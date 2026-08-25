#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAKE_SWITCHER="$PROJECT_DIR/tests/fixtures/external-theme/fake-switcher.sh"
TEST_QML="$PROJECT_DIR/external-theme-adapter-test.qml"

run_case() {
  local mode="$1"
  QE_THEME_SWITCHER="$FAKE_SWITCHER" FAKE_EXTERNAL_MODE="$mode" EXPECT_EXTERNAL="$mode" \
    timeout 5 quickshell -p "$TEST_QML"
}

run_case success
run_case partial
run_case malformed
run_case timeout
QE_THEME_SWITCHER="$FAKE_SWITCHER" EXPECT_EXTERNAL=invalid-id \
  timeout 5 quickshell -p "$TEST_QML"

QE_THEME_SWITCHER="/missing/qe-theme-switcher" EXPECT_EXTERNAL=unavailable \
  timeout 5 quickshell -p "$TEST_QML"

state_root="$(mktemp -d)"
log_file="$state_root/state-watch.log"
mkdir -p "$state_root/state/theme-switcher"
printf '%s\n' '{"schema":"theme-switcher","version":1,"mode":"machine","requestedTheme":"gruvbox","skipGtk":false,"status":"success","timestamp":"2026-08-25T12:00:00Z","persisted":true,"error":null,"results":[]}' \
  >"$state_root/state/theme-switcher/active-theme.json"
cleanup() {
  if [[ -n "${state_pid:-}" ]]; then
    kill "$state_pid" 2>/dev/null || true
    wait "$state_pid" 2>/dev/null || true
  fi
  rm -rf "$state_root"
}
trap cleanup EXIT

XDG_STATE_HOME="$state_root/state" QE_THEME_SWITCHER="$FAKE_SWITCHER" \
  EXPECT_EXTERNAL=state timeout 5 quickshell -p "$TEST_QML" >"$log_file" 2>&1 &
state_pid=$!

for _ in $(seq 1 50); do
  if grep -q "EXTERNAL_THEME_ADAPTER_READY" "$log_file"; then break; fi
  sleep 0.05
done
grep -q "EXTERNAL_THEME_ADAPTER_READY" "$log_file"

state_tmp="$state_root/state/theme-switcher/.active-theme.test"
printf '%s\n' '{"schema":"theme-switcher","version":1,"mode":"machine","requestedTheme":"poimandres","skipGtk":false,"status":"success","timestamp":"2026-08-25T12:00:00Z","persisted":true,"error":null,"results":[]}' >"$state_tmp"
mv "$state_tmp" "$state_root/state/theme-switcher/active-theme.json"

for _ in $(seq 1 50); do
  if grep -q "EXTERNAL_THEME_ADAPTER_STATE_READY" "$log_file"; then break; fi
  sleep 0.05
done
grep -q "EXTERNAL_THEME_ADAPTER_STATE_READY" "$log_file"
state_tmp="$state_root/state/theme-switcher/.active-theme.malformed"
printf '%s\n' '{not-json}' >"$state_tmp"
mv "$state_tmp" "$state_root/state/theme-switcher/active-theme.json"

wait "$state_pid"
state_pid=""
grep -q "EXTERNAL_THEME_ADAPTER_STATE_PASSED" "$log_file"

daemon_switcher="$state_root/fake-switcher.sh"
cp "$FAKE_SWITCHER" "$daemon_switcher"
daemon_log="$state_root/daemon-loss.log"
QE_THEME_SWITCHER="$daemon_switcher" EXPECT_EXTERNAL=daemon-loss \
  timeout 5 quickshell -p "$TEST_QML" >"$daemon_log" 2>&1 &
state_pid=$!
for _ in $(seq 1 50); do
  if grep -q "EXTERNAL_THEME_ADAPTER_READY" "$daemon_log"; then break; fi
  sleep 0.05
done
grep -q "EXTERNAL_THEME_ADAPTER_READY" "$daemon_log"
rm "$daemon_switcher"
wait "$state_pid"
state_pid=""
grep -q "EXTERNAL_THEME_ADAPTER_DAEMON-LOSS_PASSED" "$daemon_log"
printf '%s\n' "EXTERNAL_THEME_ADAPTER_TEST_PASSED"
