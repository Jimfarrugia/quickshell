#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

source_dir="$test_root/source"
cache_dir="$test_root/cache"
mkdir -p -- "$source_dir"
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' \
    | base64 --decode >"$source_dir/sample.png"

"$project_root/scripts/sync-wallpaper-thumbs.sh" "$source_dir" "$cache_dir"
manifest="$cache_dir/manifest"
thumbnail="$(cut -f1 "$manifest")"
[[ -n "$thumbnail" ]]
[[ -f "$cache_dir/$thumbnail" ]]

rm -f -- "$source_dir/sample.png"
"$project_root/scripts/sync-wallpaper-thumbs.sh" "$source_dir" "$cache_dir"
[[ ! -s "$manifest" ]]
if compgen -G "$cache_dir/*.jpg" >/dev/null; then
    printf '%s\n' "stale wallpaper thumbnail remains" >&2
    exit 1
fi

printf '%s\n' "WALLPAPER_CACHE_TEST_PASSED"
