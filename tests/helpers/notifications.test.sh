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
  printf 'Dunst notification owner did not release the DBus name\n' >&2
  exit 1
fi

quickshell -p "$project_root/tests/qml/notification-integration-test.qml" >"$log_file" 2>&1 &
shell_pid=$!

for _ in {1..100}; do
  if grep -Fq 'NOTIFICATION_OWNER_QE' "$log_file"; then break; fi
  if ! kill -0 "$shell_pid" 2>/dev/null; then
    printf 'notification integration test exited early\n' >&2
    exit 1
  fi
  sleep 0.1
done
if ! grep -Fq 'NOTIFICATION_OWNER_QE' "$log_file"; then
  printf 'QE did not acquire the notification DBus name\n' >&2
  exit 1
fi

[[ "$(qs ipc --pid "$shell_pid" call qe-notification-test owner)" == "qe" ]]

notify-send -a "QE Matrix" -u low -t 1000 "Low notification" "low body"
notify-send -a "QE Matrix" -u normal -t 1000 "Normal notification" "normal body"
notify-send -a "QE Matrix" -u critical "Critical notification" "critical body"
notify-send -a "QE Matrix" -h int:value:42 -t 1000 "Progress notification" "42 percent"
notify-send -a "QE Matrix" -A "open=Open" -t 1000 "Action notification" "action body"
replacement_id=$(notify-send --print-id -a "QE Replacement" -t 1000 "Before replacement")
notify-send --replace-id="$replacement_id" -a "QE Replacement" -t 1000 "After replacement"
notify-send -a "QE Matrix" -i dialog-information -t 1000 "Image notification" "image body"
notify-send -a "QE Matrix" -t 1000 "Markup <b>notification</b>" "<i>safe</i> <script>text</script>"
oversized_body=$(printf 'x%.0s' {1..70000})
notify-send -a "QE Matrix" -t 1000 "Oversized notification" "$oversized_body"

for _ in {1..50}; do
  count=$(qs ipc --pid "$shell_pid" call qe-notification-test count)
  if [[ "$count" -ge 9 ]]; then break; fi
  sleep 0.1
done
if [[ "$count" -lt 9 ]]; then
  printf 'notification matrix delivered only %s notifications\n' "$count" >&2
  exit 1
fi

qs kill --pid "$shell_pid"
wait "$shell_pid" 2>/dev/null || true
shell_pid=""
if busctl --user status org.freedesktop.Notifications >/dev/null 2>&1; then
  printf 'QE notification owner did not release the DBus name\n' >&2
  exit 1
fi

if [[ "$dunst_was_active" == true ]]; then
  systemctl --user start dunst.service
  for _ in {1..50}; do
    if busctl --user status org.freedesktop.Notifications >/dev/null 2>&1; then break; fi
    sleep 0.1
  done
  if ! busctl --user status org.freedesktop.Notifications >/dev/null 2>&1; then
    printf 'Dunst did not reclaim the notification DBus name\n' >&2
    exit 1
  fi
fi

echo "NOTIFICATIONS_TEST_PASSED"
