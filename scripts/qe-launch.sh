#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  printf 'Usage: %s <ipc-target> <function>\n' "$0" >&2
  exit 2
fi

command -v qs >/dev/null 2>&1 || {
  printf '%s\n' 'QE launcher failed: qs is unavailable.' >&2
  exit 127
}

pid=${QE_SHELL_PID:-}
if [[ -z "$pid" ]]; then
  pid=$(pgrep -f 'quickshell --no-duplicate --path .*/shell.qml' | head -1)
fi
if [[ -z "$pid" ]]; then
  printf '%s\n' 'QE launcher failed: no running QE shell to control.' >&2
  exit 1
fi

exec qs ipc --pid "$pid" call "$1" "$2"
