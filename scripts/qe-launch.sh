#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  printf 'Usage: %s <ipc-target> <function> [arguments...]\n' "$0" >&2
  exit 2
fi

command -v qs >/dev/null 2>&1 || {
  printf '%s\n' 'QE launcher failed: qs is unavailable.' >&2
  exit 127
}

script_path=$(readlink -f -- "${BASH_SOURCE[0]}")
script_dir=$(cd -- "$(dirname -- "$script_path")" && pwd)
project_root=$(cd -- "$script_dir/.." && pwd)

pid=${QE_SHELL_PID:-}

target=$1
function=$2
shift 2
if [[ -n "$pid" ]]; then
  exec qs ipc --pid "$pid" call "$target" "$function" "$@"
fi
exec qs ipc --path "$project_root/shell.qml" call "$target" "$function" "$@"
