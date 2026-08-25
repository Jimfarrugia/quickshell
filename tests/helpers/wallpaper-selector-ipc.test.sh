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
    quickshell -p "$project_root/shell.qml" >"$log_file" 2>&1 &
shell_pid="$!"

for _ in {1..50}; do
  if qs ipc --pid "$shell_pid" show >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

qs ipc --pid "$shell_pid" call qe-wallpaper open
[[ "$(qs ipc --pid "$shell_pid" call qe-wallpaper isOpen)" == "true" ]]

if ! kill -0 "$shell_pid" 2>/dev/null; then
  while IFS= read -r line; do
    printf '%s\n' "$line" >&2
  done <"$log_file"
  exit 1
fi

printf '%s\n' 'WALLPAPER_SELECTOR_IPC_TEST_PASSED'
