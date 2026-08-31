#!/usr/bin/env bash
set -euo pipefail

if [[ "${QE_NOTIFICATION_RELOAD_DBUS_SESSION:-}" != "1" ]]; then
  exec dbus-run-session -- env QE_NOTIFICATION_RELOAD_DBUS_SESSION=1 bash "$0"
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
project_root=$(cd "$script_dir/../.." && pwd)
log_file=$(mktemp)
shell_pid=""
tracked_watcher_pids=()

cleanup() {
  set +e
  if [[ -n "$shell_pid" ]] && kill -0 "$shell_pid" 2>/dev/null; then
    qs kill --pid "$shell_pid" >/dev/null 2>&1 || kill "$shell_pid" 2>/dev/null || true
    wait "$shell_pid" 2>/dev/null || true
  fi
  rm -f "$log_file"
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
  printf 'stale notification owner process %s survived\n' "$pid" >&2
  return 1
}

wait_for_single_watcher_tree() {
  local previous_wrapper=${1:-} wrapper_pid="" monitor_pid=""
  local -a wrapper_pids=() monitor_pids=()

  for _ in {1..100}; do
    mapfile -t wrapper_pids < <(
      pgrep -P "$shell_pid" -f \
        "qe-notification-owner.sh --qe-pid $shell_pid" 2>/dev/null || true
    )
    if [[ "${#wrapper_pids[@]}" -eq 1 && "${wrapper_pids[0]}" != "$previous_wrapper" ]]; then
      wrapper_pid=${wrapper_pids[0]}
      mapfile -t monitor_pids < <(pgrep -P "$wrapper_pid" -x gdbus 2>/dev/null || true)
      if [[ "${#monitor_pids[@]}" -eq 1 ]]; then
        monitor_pid=${monitor_pids[0]}
        CURRENT_WRAPPER_PID=$wrapper_pid
        CURRENT_MONITOR_PID=$monitor_pid
        tracked_watcher_pids+=("$wrapper_pid" "$monitor_pid")
        return 0
      fi
    fi
    sleep 0.05
  done

  printf 'QE %s did not settle on exactly one notification owner wrapper and monitor\n' \
    "$shell_pid" >&2
  ps -o pid=,ppid=,stat=,args= --ppid "$shell_pid" >&2 || true
  pgrep -af "qe-notification-owner.sh --qe-pid $shell_pid" >&2 || true
  return 1
}

start_shell() {
  : >"$log_file"
  quickshell -p "$project_root/tests/qml/notification-integration-test.qml" >"$log_file" 2>&1 &
  shell_pid=$!
  for _ in {1..100}; do
    if grep -Fq 'NOTIFICATION_OWNER_QE' "$log_file"; then break; fi
    if ! kill -0 "$shell_pid" 2>/dev/null; then
      printf 'notification reload test exited early\n' >&2
      return 1
    fi
    sleep 0.1
  done
  if ! grep -Fq 'NOTIFICATION_OWNER_QE' "$log_file"; then
    printf 'QE did not acquire the notification DBus name for reload test\n' >&2
    return 1
  fi
  wait_for_single_watcher_tree
}

stop_shell() {
  qs kill --pid "$shell_pid" >/dev/null 2>&1 || kill "$shell_pid" 2>/dev/null || true
  wait "$shell_pid" 2>/dev/null || true
  shell_pid=""
}

assert_tracked_watchers_gone() {
  local pid
  for pid in "${tracked_watcher_pids[@]}"; do
    wait_for_exit "$pid"
  done
}

if busctl --user status org.freedesktop.Notifications >/dev/null 2>&1; then
  printf 'isolated notification DBus name was occupied before reload test\n' >&2
  exit 1
fi

start_shell

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

for _ in {1..3}; do
  previous_wrapper_pid=$CURRENT_WRAPPER_PID
  previous_monitor_pid=$CURRENT_MONITOR_PID
  qs ipc --pid "$shell_pid" call qe-notification-test reload >/dev/null
  wait_for_single_watcher_tree "$previous_wrapper_pid"
  wait_for_exit "$previous_wrapper_pid"
  wait_for_exit "$previous_monitor_pid"
  for _ in {1..50}; do
    count=$(read_history_count)
    if [[ "$count" -eq 2 ]]; then break; fi
    sleep 0.1
  done
  [[ "$count" -eq 2 ]]
  [[ "$(qs ipc --pid "$shell_pid" call qe-notification-test popupCount)" -le 2 ]]
done

stop_shell
assert_tracked_watchers_gone

# A full restart must create one fresh tree and clean it up on shell exit.
tracked_watcher_pids=()
start_shell
stop_shell
assert_tracked_watchers_gone

echo "NOTIFICATION_RELOAD_TEST_PASSED"
