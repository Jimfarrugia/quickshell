#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

wallpaper_root="$test_root/wallpaper"
mkdir -p -- "$wallpaper_root/themes/poimandres"
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' \
    | base64 --decode >"$wallpaper_root/themes/poimandres/a.png"
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' \
    | base64 --decode >"$wallpaper_root/themes/poimandres/b.png"

for return_to_a in 0 1; do
    mkdir -p -- "$test_root/$return_to_a"
    output=$(
        XDG_STATE_HOME="$test_root/$return_to_a/state" \
        XDG_DATA_HOME="$test_root/$return_to_a/data" \
        XDG_CACHE_HOME="$test_root/$return_to_a/cache" \
        QE_MATUGEN="$project_root/tests/fixtures/matugen/repeated-matugen.sh" \
        QE_FAKE_MATUGEN_COUNTER="$test_root/$return_to_a/matugen-counter" \
        QE_TEST_RETURN_TO_A="$return_to_a" \
        QE_WALLPAPER_ROOT="$wallpaper_root" \
        QE_TEST_WALLPAPER_A="$wallpaper_root/themes/poimandres/a.png" \
        QE_TEST_WALLPAPER_B="$wallpaper_root/themes/poimandres/b.png" \
            timeout 15 quickshell -p "$project_root/tests/qml/queued-wallpaper-generation-test.qml" 2>&1
    )
    grep -q 'QUEUED_WALLPAPER_GENERATION_TEST_PASSED' <<<"$output"
done

printf '%s\n' 'QUEUED_WALLPAPER_GENERATION_HELPER_TEST_PASSED'
