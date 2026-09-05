#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
fixture_bin="$project_root/tests/fixtures/monitor-layout"
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

export XDG_STATE_HOME="$test_root/state"
export PATH="$fixture_bin:$PATH"

query_result=$(FAKE_MONITOR_MODE=mirror FAKE_PRIMARY_SCALE=1.25 FAKE_SECONDARY_SCALE=1.5 \
    "$project_root/scripts/qe-monitor-layout" query)
jq -e '.available and .mode == "mirror" and .selectedMode == "extended"
    and .primaryScale == 1.25 and .secondaryScale == 1.5
    and (.stateMatchesLive | not)' <<<"$query_result" >/dev/null

query_result=$(FAKE_HOSTNAME=other-host "$project_root/scripts/qe-monitor-layout" query)
jq -e '(.available | not) and (.message | contains("not configured"))' <<<"$query_result" >/dev/null

mkdir -p "$XDG_STATE_HOME/qe"
printf '%s\n' '{"version":1,"mode":"extended","direction":"up"}' >"$XDG_STATE_HOME/qe/monitor-layout.json"
query_result=$("$project_root/scripts/qe-monitor-layout" query)
jq -e '.stateValid and .migrationNeeded and .selectedPrimaryScale == 1
    and .selectedSecondaryScale == 1' <<<"$query_result" >/dev/null

printf '%s\n' '{"version":1,"mode":"sideways"}' >"$XDG_STATE_HOME/qe/monitor-layout.json"
query_result=$(FAKE_MONITOR_MODE=mirror "$project_root/scripts/qe-monitor-layout" query)
jq -e '.available and (.stateValid | not) and (.message | contains("Invalid saved layout"))' <<<"$query_result" >/dev/null
rm -f "$XDG_STATE_HOME/qe/monitor-layout.json"

apply_result=$(FAKE_MONITOR_MODE=mirror "$project_root/scripts/qe-monitor-layout" apply extended right 1.25 1.5)
jq -e '.available and .mode == "extended" and .direction == "right"
    and .primaryScale == 1.25 and .secondaryScale == 1.5 and .restartRequired' <<<"$apply_result" >/dev/null
jq -e '.version == 2 and .mode == "extended" and .direction == "right"
    and .scales["eDP-1"] == 1.25 and .scales["HDMI-A-1"] == 1.5' \
    "$XDG_STATE_HOME/qe/monitor-layout.json" >/dev/null

apply_result=$("$project_root/scripts/qe-monitor-layout" apply extended down 1.2 1.6)
jq -e '.mode == "extended" and .direction == "down" and (.restartRequired | not)' <<<"$apply_result" >/dev/null

for direction in left up right down; do
    apply_result=$("$project_root/scripts/qe-monitor-layout" apply extended "$direction" 1.2 1.6)
    jq -e --arg direction "$direction" \
        '.mode == "extended" and .direction == $direction' <<<"$apply_result" >/dev/null
done

if FAKE_SECONDARY_CONNECTED=0 "$project_root/scripts/qe-monitor-layout" apply mirror up 1.2 1.6 >/dev/null 2>&1; then
    printf 'Disconnected secondary output unexpectedly accepted an apply request\n' >&2
    exit 1
fi
jq -e '.mode == "extended" and .direction == "down"
    and .scales["eDP-1"] == 1.2 and .scales["HDMI-A-1"] == 1.6' "$XDG_STATE_HOME/qe/monitor-layout.json" >/dev/null

query_result=$(FAKE_SECONDARY_CONNECTED=0 FAKE_PRIMARY_SCALE=1.2 \
    "$project_root/scripts/qe-monitor-layout" query)
jq -e '.available and (.secondaryConnected | not) and (.primaryScale == 1.2)' <<<"$query_result" >/dev/null

apply_result=$(FAKE_SECONDARY_CONNECTED=0 "$project_root/scripts/qe-monitor-layout" apply extended down 1.5 1.6)
jq -e '.available and .primaryScale == 1.5 and .secondaryScale == 1.6' <<<"$apply_result" >/dev/null
jq -e '.mode == "extended" and .direction == "down"
    and .scales["eDP-1"] == 1.5 and .scales["HDMI-A-1"] == 1.6' "$XDG_STATE_HOME/qe/monitor-layout.json" >/dev/null

if FAKE_SECONDARY_CONNECTED=0 "$project_root/scripts/qe-monitor-layout" apply mirror up 1.5 1.6 >/dev/null 2>&1; then
    printf 'Disconnected secondary output unexpectedly accepted a layout-mode change\n' >&2
    exit 1
fi

if FAKE_IGNORE_STATE=1 FAKE_MONITOR_MODE=extended FAKE_MONITOR_DIRECTION=down \
        FAKE_PRIMARY_SCALE=1.25 FAKE_SECONDARY_SCALE=1.5 \
        "$project_root/scripts/qe-monitor-layout" apply mirror up 1.6 2 >/dev/null 2>&1; then
    printf 'Unconfirmed topology unexpectedly reported success\n' >&2
    exit 1
fi
jq -e '.mode == "extended" and .direction == "down"
    and .scales["eDP-1"] == 1.25 and .scales["HDMI-A-1"] == 1.5' "$XDG_STATE_HOME/qe/monitor-layout.json" >/dev/null

if FAKE_RELOAD_FAILURE=1 "$project_root/scripts/qe-monitor-layout" apply mirror up 1.6 2 >/dev/null 2>&1; then
    printf 'Failed Hyprland reload unexpectedly reported success\n' >&2
    exit 1
fi
jq -e '.mode == "extended" and .direction == "down"
    and .scales["eDP-1"] == 1.25 and .scales["HDMI-A-1"] == 1.5' "$XDG_STATE_HOME/qe/monitor-layout.json" >/dev/null

if "$project_root/scripts/qe-monitor-layout" apply extended down 1.4 1.6 >/dev/null 2>&1; then
    printf 'Invalid scale unexpectedly accepted\n' >&2
    exit 1
fi

printf 'MONITOR_LAYOUT_HELPER_TEST_PASSED\n'
