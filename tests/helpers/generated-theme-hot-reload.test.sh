#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p -- "$test_root/data/qe/wallpaper"

output=$(
    XDG_STATE_HOME="$test_root/state" \
    XDG_DATA_HOME="$test_root/data" \
    XDG_CACHE_HOME="$test_root/cache" \
        timeout 15 quickshell -p "$project_root/tests/qml/generated-theme-hot-reload-test.qml" 2>&1
)
grep -q 'GENERATED_THEME_HOT_RELOAD_TEST_PASSED' <<<"$output"

printf '%s\n' 'GENERATED_THEME_HOT_RELOAD_HELPER_TEST_PASSED'
