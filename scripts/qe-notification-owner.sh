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

current_owner

cleanup() {
  if [[ -n "${monitor_pid:-}" ]]; then
    kill "$monitor_pid" 2>/dev/null || true
    wait "$monitor_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT TERM INT

gdbus monitor --session --dest org.freedesktop.DBus \
  --object-path /org/freedesktop/DBus 2>/dev/null |
while IFS= read -r line; do
  name_owner_pattern="NameOwnerChanged[[:space:]]+\\('org\\.freedesktop\\.Notifications',[[:space:]]+'([^']*)',[[:space:]]+'([^']*)'\\)"
  if [[ "$line" =~ $name_owner_pattern ]]; then
    emit_owner "${BASH_REMATCH[2]}"
  fi
done &
monitor_pid=$!
wait "$monitor_pid"
