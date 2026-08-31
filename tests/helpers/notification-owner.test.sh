#!/usr/bin/env bash
set -euo pipefail

if [[ "${QE_NOTIFICATION_OWNER_TEST_DBUS_SESSION:-}" != "1" ]]; then
  exec dbus-run-session -- env QE_NOTIFICATION_OWNER_TEST_DBUS_SESSION=1 bash "$0"
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
project_root=$(cd "$script_dir/../.." && pwd)
helper="$project_root/scripts/qe-notification-owner.sh"
tmp_dir=$(mktemp -d)
tracked_pids=()

cleanup() {
  set +e
  local pid
  for pid in "${tracked_pids[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill -KILL "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
  rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

wait_for_exit() {
  local pid=$1
  for _ in {1..100}; do
    if [[ ! -e "/proc/$pid" ]]; then
      return 0
    fi
    sleep 0.02
  done
  printf 'process %s did not exit\n' "$pid" >&2
  return 1
}

wait_for_monitor() {
  local wrapper_pid=$1 monitor_pid=""
  for _ in {1..100}; do
    monitor_pid=$(pgrep -P "$wrapper_pid" -x gdbus 2>/dev/null || true)
    if [[ "$monitor_pid" =~ ^[0-9]+$ ]]; then
      printf '%s' "$monitor_pid"
      return 0
    fi
    sleep 0.02
  done
  printf 'notification owner wrapper %s did not start one gdbus child\n' "$wrapper_pid" >&2
  return 1
}

start_helper() {
  local output_file=$1 qe_pid=${2:-999999}
  setpriv --pdeathsig TERM "$helper" --qe-pid "$qe_pid" >"$output_file" &
  STARTED_WRAPPER_PID=$!
  tracked_pids+=("$STARTED_WRAPPER_PID")
  STARTED_MONITOR_PID=$(wait_for_monitor "$STARTED_WRAPPER_PID")
  tracked_pids+=("$STARTED_MONITOR_PID")
}

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$helper"
fi

output_file="$tmp_dir/owner.jsonl"
start_helper "$output_file"
kill -TERM "$STARTED_WRAPPER_PID"
wait "$STARTED_WRAPPER_PID"
wait_for_exit "$STARTED_MONITOR_PID"

python3 - "$output_file" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    record = json.loads(stream.readline())
assert record["schemaVersion"] == 1, record
assert record["owner"] in {"none", "dunst", "qe", "other"}, record
assert isinstance(record["uniqueName"], str), record
assert isinstance(record["pid"], int), record
PY

# Monitor exit must end the wrapper and leave no child behind.
start_helper "$tmp_dir/monitor-exit.jsonl"
kill -TERM "$STARTED_MONITOR_PID"
wait "$STARTED_WRAPPER_PID" 2>/dev/null || true
wait_for_exit "$STARTED_WRAPPER_PID"
wait_for_exit "$STARTED_MONITOR_PID"

# Quickshell 0.3.1 destroys Process children with SIGKILL on soft reload.
start_helper "$tmp_dir/wrapper-kill.jsonl"
kill -KILL "$STARTED_WRAPPER_PID"
wait "$STARTED_WRAPPER_PID" 2>/dev/null || true
wait_for_exit "$STARTED_MONITOR_PID"

# A disappearing QE parent must terminate both its wrapper and monitor.
wrapper_pid_file="$tmp_dir/parent-wrapper.pid"
parent_output="$tmp_dir/parent-death.jsonl"
bash -c '
  helper=$1
  wrapper_pid_file=$2
  output_file=$3
  setpriv --pdeathsig TERM "$helper" --qe-pid "$BASHPID" >"$output_file" &
  printf "%s\n" "$!" >"$wrapper_pid_file"
  wait
' _ "$helper" "$wrapper_pid_file" "$parent_output" &
parent_pid=$!
tracked_pids+=("$parent_pid")
for _ in {1..100}; do
  if [[ -s "$wrapper_pid_file" ]]; then break; fi
  sleep 0.02
done
parent_wrapper_pid=$(<"$wrapper_pid_file")
tracked_pids+=("$parent_wrapper_pid")
parent_monitor_pid=$(wait_for_monitor "$parent_wrapper_pid")
tracked_pids+=("$parent_monitor_pid")
kill -KILL "$parent_pid"
wait "$parent_pid" 2>/dev/null || true
wait_for_exit "$parent_wrapper_pid"
wait_for_exit "$parent_monitor_pid"

echo "NOTIFICATION_OWNER_HELPER_TEST_PASSED"
