#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
project_root=$(cd "$script_dir/../.." && pwd)
log_file=$(mktemp)
shell_pid=""
dunst_was_active=false

cleanup() {
  set +e
  if [[ -n "$shell_pid" ]] && kill -0 "$shell_pid" 2>/dev/null; then
    qs kill --pid "$shell_pid" >/dev/null 2>&1 || kill "$shell_pid" 2>/dev/null || true
    wait "$shell_pid" 2>/dev/null || true
  fi
  if [[ "$dunst_was_active" == true ]]; then
    systemctl --user start dunst.service >/dev/null 2>&1 || true
    for _ in {1..50}; do
      if busctl --user status org.freedesktop.Notifications >/dev/null 2>&1; then break; fi
      sleep 0.1
    done
  else
    systemctl --user stop dunst.service >/dev/null 2>&1 || true
  fi
  rm -f "$log_file"
}
trap cleanup EXIT INT TERM

if systemctl --user is-active --quiet dunst.service; then
  dunst_was_active=true
fi
if [[ "$dunst_was_active" == true ]]; then
  systemctl --user stop dunst.service
fi

for _ in {1..50}; do
  if ! busctl --user status org.freedesktop.Notifications >/dev/null 2>&1; then break; fi
  sleep 0.1
done
if busctl --user status org.freedesktop.Notifications >/dev/null 2>&1; then
  printf 'notification DBus name remained occupied before reload test\n' >&2
  exit 1
fi

quickshell -p "$project_root/tests/qml/notification-integration-test.qml" >"$log_file" 2>&1 &
shell_pid=$!
for _ in {1..100}; do
  if grep -Fq 'NOTIFICATION_OWNER_QE' "$log_file"; then break; fi
  if ! kill -0 "$shell_pid" 2>/dev/null; then
    printf 'notification reload test exited early\n' >&2
    exit 1
  fi
  sleep 0.1
done
if ! grep -Fq 'NOTIFICATION_OWNER_QE' "$log_file"; then
  printf 'QE did not acquire the notification DBus name for reload test\n' >&2
  exit 1
fi

notify-send -a "QE Reload" -t 5000 "Reload one" "first body"
notify-send -a "QE Reload" -t 5000 "Reload two" "second body"
read_history_count() {
  local value
  value=$(qs ipc --pid "$shell_pid" call qe-notification-test historyCount 2>/dev/null || true)
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    printf '%s' "$value"
  else
    printf '%s' '-1'
  fi
}
for _ in {1..50}; do
  count=$(read_history_count)
  if [[ "$count" -eq 2 ]]; then break; fi
  sleep 0.1
done
[[ "$count" -eq 2 ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-notification-test popupCount)" -le 2 ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-notification-test popupVisible)" == "true" ]]

qs ipc --pid "$shell_pid" call qe-notification-test reload >/dev/null
for _ in {1..50}; do
  count=$(read_history_count)
  if [[ "$count" -eq 2 ]]; then break; fi
  sleep 0.1
done
[[ "$count" -eq 2 ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-notification-test popupCount)" -le 2 ]]

echo "NOTIFICATION_RELOAD_TEST_PASSED"
