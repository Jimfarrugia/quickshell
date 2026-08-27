#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
log_file="$(mktemp)"
shell_pid=""

cleanup() {
  if [[ -n "$shell_pid" ]]; then
    kill "$shell_pid" 2>/dev/null || true
    wait "$shell_pid" 2>/dev/null || true
  fi
  rm -rf -- "$test_root" "$log_file"
}
trap cleanup EXIT

wallpaper_root="$test_root/wallpaper"
mkdir -p -- "$wallpaper_root/themes/poimandres"
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' \
    | base64 --decode >"$wallpaper_root/themes/poimandres/sample.png"

XDG_STATE_HOME="$test_root/state" \
XDG_DATA_HOME="$test_root/data" \
XDG_CACHE_HOME="$test_root/cache" \
QE_WALLPAPER_ROOT="$wallpaper_root" \
QE_WALLPAPER_HELPER="$project_root/scripts/apply-wallpaper.sh" \
    quickshell --path "$project_root/shell.qml" >"$log_file" 2>&1 &
shell_pid="$!"

for _ in {1..50}; do
  if qs ipc --pid "$shell_pid" show >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

QE_SHELL_PID="$shell_pid" "$project_root/scripts/qe-launch.sh" qe-theme open
[[ "$(qs ipc --pid "$shell_pid" call qe-theme isOpen)" == "true" ]]
QE_SHELL_PID="$shell_pid" "$project_root/scripts/qe-launch.sh" qe-theme close
[[ "$(qs ipc --pid "$shell_pid" call qe-theme isOpen)" == "false" ]]
active_theme="$(QE_SHELL_PID="$shell_pid" "$project_root/scripts/qe-launch.sh" qe-theme activeTheme)"
[[ "$active_theme" == "poimandres" ]]
[[ "$(QE_SHELL_PID="$shell_pid" "$project_root/scripts/qe-launch.sh" qe-theme applyTheme "$active_theme")" == "true" ]]
QE_SHELL_PID="$shell_pid" "$project_root/scripts/qe-launch.sh" qe-wallpaper open
[[ "$(qs ipc --pid "$shell_pid" call qe-wallpaper isOpen)" == "true" ]]
QE_SHELL_PID="$shell_pid" "$project_root/scripts/qe-launch.sh" qe-wallpaper close
[[ "$(qs ipc --pid "$shell_pid" call qe-wallpaper isOpen)" == "false" ]]

if ! kill -0 "$shell_pid" 2>/dev/null; then
  while IFS= read -r line; do
    printf '%s\n' "$line" >&2
  done <"$log_file"
  exit 1
fi

printf '%s\n' 'QE_LAUNCH_TEST_PASSED'
