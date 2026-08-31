#!/usr/bin/env bash
# Emit one bounded JSON owner record, then structured records for notification
# DBus NameOwnerChanged events. This is a diagnostic boundary only; the native
# Quickshell NotificationServer remains the notification owner.

set -euo pipefail

qe_pid=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --qe-pid)
      [[ $# -ge 2 && "$2" =~ ^[0-9]+$ ]] || { printf 'Invalid --qe-pid\n' >&2; exit 2; }
      qe_pid="$2"
      shift 2
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

[[ -n "$qe_pid" ]] || { printf 'Missing --qe-pid\n' >&2; exit 2; }
export LC_ALL=C

emit_owner() {
  local unique_name="${1:-}" pid=0 owner="none"
  if [[ -n "$unique_name" ]]; then
    local pid_reply
    pid_reply=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
      org.freedesktop.DBus GetConnectionUnixProcessID s "$unique_name" 2>/dev/null || true)
    read -r _ pid <<< "$pid_reply"
    [[ "$pid" =~ ^[0-9]+$ ]] || pid=0
    if [[ "$pid" == "$qe_pid" ]]; then
      owner="qe"
    elif [[ "$pid" -gt 0 && -r "/proc/$pid/comm" ]] && [[ "$(<"/proc/$pid/comm")" == "dunst" ]]; then
      owner="dunst"
    else
      owner="other"
    fi
  else
    unique_name=""
  fi
  printf '{"schemaVersion":1,"owner":"%s","uniqueName":"%s","pid":%s}\n' \
    "$owner" "$unique_name" "$pid"
}

current_owner() {
  local reply unique_name=""
  reply=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
    org.freedesktop.DBus GetNameOwner s org.freedesktop.Notifications 2>/dev/null || true)
  read -r _ unique_name <<< "$reply"
  unique_name=${unique_name//\"/}
  emit_owner "$unique_name"
}

monitor_pid=""
monitor_fd=""

# shellcheck disable=SC2329 # invoked by the EXIT trap
cleanup() {
  trap - EXIT HUP INT TERM

  if [[ -n "$monitor_pid" ]]; then
    kill -TERM "$monitor_pid" 2>/dev/null || true
    for _ in {1..50}; do
      if ! kill -0 "$monitor_pid" 2>/dev/null; then
        break
      fi
      sleep 0.02
    done
    kill -KILL "$monitor_pid" 2>/dev/null || true
    wait "$monitor_pid" 2>/dev/null || true
  fi

  if [[ -n "$monitor_fd" ]]; then
    exec {monitor_fd}<&-
  fi
}
trap cleanup EXIT
trap 'exit 0' HUP INT TERM

# The child also dies if this wrapper is SIGKILLed before its EXIT trap can run.
coproc OWNER_MONITOR {
  exec setpriv --pdeathsig KILL gdbus monitor --session \
    --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus 2>/dev/null
}
monitor_pid=$OWNER_MONITOR_PID
monitor_fd=${OWNER_MONITOR[0]}

# Subscribe before querying so an owner transition cannot be missed between the
# initial record and monitor startup.
current_owner

while IFS= read -r -u "$monitor_fd" line; do
  name_owner_pattern="NameOwnerChanged[[:space:]]+\\('org\\.freedesktop\\.Notifications',[[:space:]]+'([^']*)',[[:space:]]+'([^']*)'\\)"
  if [[ "$line" =~ $name_owner_pattern ]]; then
    emit_owner "${BASH_REMATCH[2]}"
  fi
done

monitor_status=0
wait "$monitor_pid" || monitor_status=$?
monitor_pid=""
exit "$monitor_status"
