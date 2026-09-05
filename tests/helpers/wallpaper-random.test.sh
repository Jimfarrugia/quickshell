#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

mkdir -p -- "$test_root/wallpaper/themes/poimandres"
touch "$test_root/wallpaper/themes/poimandres/first.png"
touch "$test_root/wallpaper/themes/poimandres/second.jpg"

XDG_STATE_HOME="$test_root/state" \
XDG_DATA_HOME="$test_root/data" \
XDG_CACHE_HOME="$test_root/cache" \
QE_WALLPAPER_ROOT="$test_root/wallpaper" \
    timeout 5 quickshell -p "$project_root/tests/qml/wallpaper-random-test.qml"

printf '%s\n' 'WALLPAPER_RANDOM_HELPER_TEST_PASSED'
