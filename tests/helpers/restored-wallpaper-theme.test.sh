#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

mkdir -p -- "$test_root/data/qe/wallpaper"
jq '.id = "wallpaper" | .name = "Wallpaper"' \
    "$project_root/tests/fixtures/themes/valid.json" \
    >"$test_root/data/qe/wallpaper/Wallpaper.json"

output=$(
    XDG_STATE_HOME="$test_root/state" \
    XDG_DATA_HOME="$test_root/data" \
    XDG_CACHE_HOME="$test_root/cache" \
        timeout 8 quickshell -p "$project_root/tests/qml/restored-wallpaper-theme-test.qml" 2>&1
)
grep -q 'RESTORED_WALLPAPER_THEME_TEST_PASSED' <<<"$output"

printf '%s\n' 'RESTORED_WALLPAPER_THEME_HELPER_TEST_PASSED'
