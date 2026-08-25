#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

mkdir -p -- "$test_root/stage/one" "$test_root/target"
printf '%s\n' old >"$test_root/target/Wallpaper.json"
printf '%s\n' new >"$test_root/stage/one/Wallpaper.json"
"$project_root/scripts/promote-wallpaper-theme.sh" \
    "$test_root/stage/one/Wallpaper.json" "$test_root/target/Wallpaper.json"
[[ "$(<"$test_root/target/Wallpaper.json")" == new ]]
[[ ! -e "$test_root/stage/one/Wallpaper.json" ]]

if "$project_root/scripts/promote-wallpaper-theme.sh" \
    "$test_root/stage/missing/Wallpaper.json" "$test_root/target/Wallpaper.json"; then
    exit 1
fi
[[ "$(<"$test_root/target/Wallpaper.json")" == new ]]

printf '%s\n' 'WALLPAPER_PROMOTION_TEST_PASSED'
