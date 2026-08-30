#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
project_root=$(cd "$script_dir/../.." && pwd)
log_file=$(mktemp)
stub_dir=$(mktemp -d)
thunar_args_file=$(mktemp)
test_window_addresses=$(mktemp)
shell_pid=""
client_pid=""
dunst_was_active=false

capture_existing_test_windows() {
  hyprctl clients -j | jq -r '
    .[]
    | select(
        ((.class // "") | ascii_downcase) == "imv"
        or ((.class // "") | ascii_downcase) == "thunar"
      )
    | .address
  ' >"$test_window_addresses" 2>/dev/null || true
}

close_test_windows() {
  local address
  while IFS= read -r address; do
    [[ -z "$address" ]] && continue
    if ! rg -Fxq "$address" "$test_window_addresses"; then
      hyprctl dispatch "hl.dsp.window.close({ window = \"address:$address\" })" \
        >/dev/null 2>&1 || true
    fi
  done < <(
    hyprctl clients -j | jq -r '
      .[]
      | select(
          ((.class // "") | ascii_downcase) == "imv"
          or ((.class // "") | ascii_downcase) == "thunar"
        )
      | .address
    ' 2>/dev/null || true
  )
}

cleanup() {
  set +e
  if [[ -n "$shell_pid" ]] && kill -0 "$shell_pid" 2>/dev/null; then
    qs kill --pid "$shell_pid" >/dev/null 2>&1 || kill "$shell_pid" 2>/dev/null || true
    wait "$shell_pid" 2>/dev/null || true
  fi
  if [[ -n "$client_pid" ]] && kill -0 "$client_pid" 2>/dev/null; then
    kill "$client_pid" 2>/dev/null || true
    wait "$client_pid" 2>/dev/null || true
  fi
  for _ in {1..10}; do
    close_test_windows
    sleep 0.1
  done
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
  rm -f "$thunar_args_file"
  rm -f "$test_window_addresses"
  rm -rf "$stub_dir"
}
trap cleanup EXIT INT TERM

capture_existing_test_windows

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
ln -s "$(command -v true)" "$stub_dir/xdg-open"
ln -s "$project_root/tests/fixtures/bin/record-args" "$stub_dir/thunar"
export QE_TEST_THUNAR_ARGS="$thunar_args_file"
PATH="$stub_dir:$PATH" "$project_root/scripts/qe-hyprshot-notification.py" \
  "$project_root/shell.qml" "$project_root" >/dev/null 2>&1 &
client_pid=$!
for _ in {1..50}; do
  if [[ "$(qs ipc --pid "$shell_pid" call qe-notification-test actionReady)" == true ]]; then break; fi
  sleep 0.1
done
if [[ "$(qs ipc --pid "$shell_pid" call qe-notification-test actionReady)" != true ]]; then
  printf 'notification action payload was not ready for invocation\n' >&2
  exit 1
fi
[[ "$(qs ipc --pid "$shell_pid" call qe-notification-test invokeLastAction)" == true ]]
sleep 0.2
if ! kill -0 "$client_pid" 2>/dev/null; then
  printf 'notification action sender exited after the first action\n' >&2
  exit 1
fi
[[ "$(qs ipc --pid "$shell_pid" call qe-notification-test invokeAction folder)" == true ]]
sleep 0.2
if ! kill -0 "$client_pid" 2>/dev/null; then
  printf 'notification action sender exited after repeated actions\n' >&2
  exit 1
fi
if [[ "$(<"$thunar_args_file")" != "$project_root/shell.qml" ]]; then
  printf 'folder action did not pass the screenshot file to Thunar\n' >&2
  exit 1
fi
if [[ "$(qs ipc --pid "$shell_pid" call qe-notification-test imagePath)" != "file://$project_root/shell.qml" ]]; then
  printf 'screenshot notification did not publish its image path\n' >&2
  exit 1
fi
if [[ "$(qs ipc --pid "$shell_pid" call qe-notification-test body)" != "shell.qml" ]]; then
  printf 'screenshot notification body did not use the image filename\n' >&2
  exit 1
fi
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
if [[ "$(qs ipc --pid "$shell_pid" call qe-notification-test actionCount)" -lt 1 ]]; then
  printf 'notification action payload was not exposed by Quickshell\n' >&2
  exit 1
fi

sleep 5.5
popup_count=$(qs ipc --pid "$shell_pid" call qe-notification-test popupCount)
history_count=$(qs ipc --pid "$shell_pid" call qe-notification-test historyCount)
if [[ "$popup_count" -ne 1 || "$history_count" -lt 9 ]]; then
  printf 'non-critical popups did not expire independently of history (popups=%s history=%s)\n' "$popup_count" "$history_count" >&2
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
