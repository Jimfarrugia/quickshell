#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

wallpaper_root="$test_root/wallpaper"
mkdir -p -- "$wallpaper_root/themes/poimandres"
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' \
    | base64 --decode >"$wallpaper_root/themes/poimandres/sample.png"

XDG_STATE_HOME="$test_root/state" \
XDG_DATA_HOME="$test_root/data" \
XDG_CACHE_HOME="$test_root/cache" \
QE_MATUGEN="$project_root/tests/fixtures/matugen/fake-matugen.sh" \
QE_WALLPAPER_ROOT="$wallpaper_root" \
    timeout 12 quickshell -p "$project_root/wallpaper-service-test.qml"

printf '%s\n' 'WALLPAPER_SERVICE_HELPER_TEST_PASSED'
