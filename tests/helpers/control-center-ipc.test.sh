#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
log_file="$(mktemp)"
shell_pid=""

cleanup() {
  if [[ -n "$shell_pid" ]]; then
    kill "$shell_pid" 2>/dev/null || true
    wait "$shell_pid" 2>/dev/null || true
  fi
  rm -f -- "$log_file"
}
trap cleanup EXIT

quickshell -p "$project_root/shell.qml" >"$log_file" 2>&1 &
shell_pid="$!"

for _ in {1..50}; do
  if qs ipc --pid "$shell_pid" show >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

targets="$(qs ipc --pid "$shell_pid" show)"
[[ "$targets" == *"target qe-control-center"* ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-control-center isOpen)" == "false" ]]

qs ipc --pid "$shell_pid" call qe-dashboard open audio
qs ipc --pid "$shell_pid" call qe-control-center open
[[ "$(qs ipc --pid "$shell_pid" call qe-control-center isOpen)" == "true" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-dashboard isOpen audio)" == "false" ]]

qs ipc --pid "$shell_pid" call qe-control-center toggle
[[ "$(qs ipc --pid "$shell_pid" call qe-control-center isOpen)" == "false" ]]
qs ipc --pid "$shell_pid" call qe-control-center toggle
[[ "$(qs ipc --pid "$shell_pid" call qe-control-center isOpen)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-notifications open
[[ "$(qs ipc --pid "$shell_pid" call qe-control-center isOpen)" == "false" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-notifications isOpen)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-notifications close
qs ipc --pid "$shell_pid" call qe-control-center open
qs ipc --pid "$shell_pid" call qe-theme open
[[ "$(qs ipc --pid "$shell_pid" call qe-control-center isOpen)" == "false" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-theme isOpen)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-theme close
qs ipc --pid "$shell_pid" call qe-control-center open
qs ipc --pid "$shell_pid" call qe-dashboard open audio
[[ "$(qs ipc --pid "$shell_pid" call qe-control-center isOpen)" == "false" ]]
qs ipc --pid "$shell_pid" call qe-dashboard close
qs ipc --pid "$shell_pid" call qe-control-center open
qs ipc --pid "$shell_pid" call qe-wallpaper open
[[ "$(qs ipc --pid "$shell_pid" call qe-control-center isOpen)" == "false" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-wallpaper isOpen)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-wallpaper close
qs ipc --pid "$shell_pid" call qe-control-center open
qs ipc --pid "$shell_pid" call qe-palette open
[[ "$(qs ipc --pid "$shell_pid" call qe-control-center isOpen)" == "false" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-palette isOpen)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-palette close
qs ipc --pid "$shell_pid" call qe-control-center open
qs ipc --pid "$shell_pid" call qe-launcher open
[[ "$(qs ipc --pid "$shell_pid" call qe-control-center isOpen)" == "false" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-launcher isOpen)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-launcher close
qs ipc --pid "$shell_pid" call qe-control-center open
qs ipc --pid "$shell_pid" call qe-help open
[[ "$(qs ipc --pid "$shell_pid" call qe-control-center isOpen)" == "false" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-help isOpen)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-help close
qs ipc --pid "$shell_pid" call qe-control-center open
qs ipc --pid "$shell_pid" call qe-control-center close
[[ "$(qs ipc --pid "$shell_pid" call qe-control-center isOpen)" == "false" ]]

kill -0 "$shell_pid"
printf '%s\n' "CONTROL_CENTER_IPC_TEST_PASSED"
