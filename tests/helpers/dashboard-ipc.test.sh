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
[[ "$targets" == *"target qe-dashboard"* ]]
[[ "$targets" == *"target qe-audio"* ]]
[[ "$targets" == *"target qe-ai-quota"* ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-dashboard isOpen audio)" == "false" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-audio isOpen)" == "false" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-ai-quota isOpen)" == "false" ]]

qs ipc --pid "$shell_pid" call qe-dashboard open audio
[[ "$(qs ipc --pid "$shell_pid" call qe-dashboard isOpen audio)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-audio close
[[ "$(qs ipc --pid "$shell_pid" call qe-audio isOpen)" == "false" ]]
qs ipc --pid "$shell_pid" call qe-audio toggle
[[ "$(qs ipc --pid "$shell_pid" call qe-audio isOpen)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-audio toggle
[[ "$(qs ipc --pid "$shell_pid" call qe-audio isOpen)" == "false" ]]

qs ipc --pid "$shell_pid" call qe-ai-quota open
[[ "$(qs ipc --pid "$shell_pid" call qe-ai-quota isOpen)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-ai-quota toggle
[[ "$(qs ipc --pid "$shell_pid" call qe-ai-quota isOpen)" == "false" ]]

qs ipc --pid "$shell_pid" call qe-dashboard open network
[[ "$(qs ipc --pid "$shell_pid" call qe-dashboard isOpen audio)" == "false" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-dashboard isOpen network)" == "true" ]]

qs ipc --pid "$shell_pid" call qe-dashboard toggle network
[[ "$(qs ipc --pid "$shell_pid" call qe-dashboard isOpen network)" == "false" ]]

qs ipc --pid "$shell_pid" call qe-dashboard open audio
qs ipc --pid "$shell_pid" call qe-dashboard close
[[ "$(qs ipc --pid "$shell_pid" call qe-dashboard isOpen audio)" == "false" ]]

kill -0 "$shell_pid"
printf '%s\n' "DASHBOARD_IPC_TEST_PASSED"
