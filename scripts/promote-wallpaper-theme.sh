#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 || -z "${1:-}" || -z "${2:-}" ]]; then
    printf 'Usage: %s <staged-theme-path> <target-theme-path>\n' "$0" >&2
    exit 2
fi

staged_path=$1
target_path=$2
if [[ ! -f "$staged_path" || ! -r "$staged_path" ]]; then
    printf 'Staged wallpaper theme is not readable: %s\n' "$staged_path" >&2
    exit 2
fi
if [[ "$staged_path" != /* || "$target_path" != /* ]]; then
    printf 'Wallpaper theme paths must be absolute.\n' >&2
    exit 2
fi

target_directory=$(dirname -- "$target_path")
mkdir -p -- "$target_directory"

# Staging and target paths are kept below the same QE data directory so this is
# a same-filesystem rename. A failed rename leaves the last-known-good target.
mv -f -- "$staged_path" "$target_path"
rmdir -- "$(dirname -- "$staged_path")" 2>/dev/null || true
