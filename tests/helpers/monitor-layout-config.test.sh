#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
monitors_config=${QE_MONITORS_CONFIG:-${HOME}/.config/hypr/monitors.lua}
harness="$project_root/tests/fixtures/monitor-layout/assert-config.lua"
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/qe"

assert_secondary() {
    local state=$1 position=$2 scale=$3 mirror=$4
    printf '%s\n' "$state" >"$test_root/qe/monitor-layout.json"
    XDG_STATE_HOME="$test_root" MONITORS_CONFIG="$monitors_config" \
        EXPECTED_COUNT=2 EXPECTED_INDEX=2 EXPECTED_OUTPUT=HDMI-A-1 \
        EXPECTED_POSITION="$position" EXPECTED_SCALE="$scale" \
        EXPECTED_MIRROR="$mirror" lua "$harness"
}

[[ -f "$monitors_config" ]] || {
    printf 'Monitor config not found: %s\n' "$monitors_config" >&2
    exit 1
}
command -v lua >/dev/null 2>&1 || {
    printf 'Missing dependency: lua\n' >&2
    exit 127
}

assert_secondary '{"version":1,"mode":"extended","direction":"down"}' "0x1080" 1 ""
assert_secondary '{"version":2,"mode":"extended","direction":"right","scales":{"eDP-1":1.25,"HDMI-A-1":1.5}}' "1536x0" 1.5 ""
assert_secondary '{"version":2,"mode":"extended","direction":"down","scales":{"eDP-1":1.5,"HDMI-A-1":1.25}}' "0x720" 1.25 ""
assert_secondary '{"version":2,"mode":"extended","direction":"left","scales":{"eDP-1":1.2,"HDMI-A-1":1.6}}' "-1200x0" 1.6 ""
assert_secondary '{"version":2,"mode":"extended","direction":"up","scales":{"eDP-1":1.6,"HDMI-A-1":2}}' "0x-540" 2 ""
assert_secondary '{"version":2,"mode":"mirror","direction":"up","scales":{"eDP-1":1.2,"HDMI-A-1":1.5}}' "0x0" 1.5 "eDP-1"
assert_secondary '{"version":2,"mode":"mirror","direction":"up","scales":{"eDP-1":1.4,"HDMI-A-1":1.5}}' "0x-1080" 1 ""
assert_secondary '{"version":20,"mode":"mirror","direction":"up","scales":{"eDP-1":1.2,"HDMI-A-1":1.5}}' "0x-1080" 1 ""

printf '%s\n' '{"version":2,"mode":"extended","direction":"up","scales":{"eDP-1":1.6,"HDMI-A-1":2}}' >"$test_root/qe/monitor-layout.json"
XDG_STATE_HOME="$test_root" MONITORS_CONFIG="$monitors_config" \
    EXPECTED_COUNT=2 EXPECTED_INDEX=1 EXPECTED_OUTPUT=eDP-1 \
    EXPECTED_POSITION="0x0" EXPECTED_SCALE=1.6 EXPECTED_MIRROR="" \
    lua "$harness"

printf 'MONITOR_LAYOUT_CONFIG_TEST_PASSED\n'
