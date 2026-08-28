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
[[ "$targets" == *"target qe-theme"* ]]
[[ "$targets" == *"target qe-wallpaper"* ]]
[[ "$targets" == *"target qe-palette"* ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-theme isOpen)" == "false" ]]
active_theme="$(qs ipc --pid "$shell_pid" call qe-theme activeTheme)"
[[ "$active_theme" =~ ^[a-z0-9]+(_[a-z0-9]+)*$ ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-theme applyTheme "$active_theme")" == "true" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-theme operation)" != "pending" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-wallpaper isOpen)" == "false" ]]
[[ "$(qs ipc --pid "$shell_pid" call qe-palette isOpen)" == "false" ]]
qs ipc --pid "$shell_pid" call qe-theme open
[[ "$(qs ipc --pid "$shell_pid" call qe-theme isOpen)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-theme toggle
[[ "$(qs ipc --pid "$shell_pid" call qe-theme isOpen)" == "false" ]]
qs ipc --pid "$shell_pid" call qe-theme open
qs ipc --pid "$shell_pid" call qe-theme close
[[ "$(qs ipc --pid "$shell_pid" call qe-theme isOpen)" == "false" ]]
qs ipc --pid "$shell_pid" call qe-wallpaper open
[[ "$(qs ipc --pid "$shell_pid" call qe-wallpaper isOpen)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-wallpaper toggle
[[ "$(qs ipc --pid "$shell_pid" call qe-wallpaper isOpen)" == "false" ]]
qs ipc --pid "$shell_pid" call qe-palette open
[[ "$(qs ipc --pid "$shell_pid" call qe-palette isOpen)" == "true" ]]
qs ipc --pid "$shell_pid" call qe-palette toggle
[[ "$(qs ipc --pid "$shell_pid" call qe-palette isOpen)" == "false" ]]

if ! kill -0 "$shell_pid" 2>/dev/null; then
  while IFS= read -r line; do
    printf '%s\n' "$line" >&2
  done <"$log_file"
  exit 1
fi

printf '%s\n' "THEME_SELECTOR_IPC_TEST_PASSED"
