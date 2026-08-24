#!/usr/bin/env bash
set -euo pipefail

script_path=$(readlink -f -- "${BASH_SOURCE[0]}")
script_dir=$(cd -- "$(dirname -- "$script_path")" && pwd)
project_root=$(cd -- "$script_dir/.." && pwd)

if ! command -v quickshell >/dev/null 2>&1; then
  printf 'QE launch failed: quickshell is not installed or not in PATH.\n' >&2
  exit 127
fi

exec quickshell --no-duplicate --path "$project_root/shell.qml"
