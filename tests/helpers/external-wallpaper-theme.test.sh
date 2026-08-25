#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

helper="$project_root/scripts/promote-external-theme.sh"
config_root="$test_root/home/.config"

run_helper() {
    local spec_path=$1 status
    if output=$("$helper" "$spec_path" 2>&1); then
        status=0
    else
        status=$?
    fi
    printf 'STATUS=%s\n%s\n' "$status" "$output"
}

spec="$test_root/spec.json"
cat >"$spec" <<'EOF'
{
  "schemaVersion": 1,
  "variant": "dark",
  "targets": [
    {"id": "alpha", "executable": "bash", "path": "/TMP/config_root/alpha/themes/wallpaper.conf", "content": "background #101820\nforeground #f4f7fb\n"},
    {"id": "beta", "executable": "bash", "path": "/TMP/config_root/beta/themes/wallpaper.conf", "content": "set -g @default_fg \"#f4f7fb\"\n"},
    {"id": "ghost", "executable": "no-such-qe-test-binary", "path": "/TMP/config_root/ghost/themes/wallpaper.conf", "content": "unused"}
  ]
}
EOF
sed -i "s#/TMP/config_root#$config_root#g" "$spec"

result=$(run_helper "$spec")
grep -q '^STATUS=0$' <<<"$result"
printf '%s\n' "$result" | sed -n '2,$p' | jq -e '.results | length == 3' >/dev/null
printf '%s\n' "$result" | sed -n '2,$p' | jq -e '.results[] | select(.id == "ghost" and .status == "skipped")' >/dev/null
printf '%s\n' "$result" | sed -n '2,$p' | jq -e '[.results[] | select(.status == "applied")] | length == 2' >/dev/null
grep -qx 'background #101820' "$config_root/alpha/themes/wallpaper.conf"
grep -qx 'foreground #f4f7fb' "$config_root/alpha/themes/wallpaper.conf"
grep -qx 'set -g @default_fg "#f4f7fb"' "$config_root/beta/themes/wallpaper.conf"
[[ ! -e "$config_root/ghost/themes/wallpaper.conf" ]]
[[ -z "$(find "$config_root" -name '.qe-wallpaper.*' 2>/dev/null)" ]]

result=$(run_helper "$test_root/does-not-exist.json")
grep -q '^STATUS=2$' <<<"$result"

printf '%s\n' '{"schemaVersion":2,"targets":[]}' >"$test_root/badspec.json"
result=$(run_helper "$test_root/badspec.json")
grep -q '^STATUS=2$' <<<"$result"

cat >"$test_root/lt.json" <<EOF
{
  "schemaVersion": 1,
  "variant": "dark",
  "targets": [
    {"id": "alpha", "executable": "bash", "path": "..",
     "content": "background #000000\n"}
  ]
}
EOF
result=$(run_helper "$test_root/lt.json")
grep -q '^STATUS=4$' <<<"$result"
grep -qx 'set -g @default_fg "#f4f7fb"' "$config_root/beta/themes/wallpaper.conf"

cat >"$test_root/part.json" <<EOF
{
  "schemaVersion": 1,
  "variant": "dark",
  "targets": [
    {"id": "alpha", "executable": "bash", "path": "$config_root/alpha/themes/wallpaper.conf",
     "content": "background #222222\n"},
    {"id": "blocked", "executable": "bash", "path": "$test_root/part.json/blocked/themes/wallpaper.conf",
     "content": "never"}
  ]
}
EOF
result=$(run_helper "$test_root/part.json")
grep -q '^STATUS=3$' <<<"$result"
grep -qx 'background #222222' "$config_root/alpha/themes/wallpaper.conf"

printf '%s\n' 'EXTERNAL_WALLPAPER_THEME_HELPER_TEST_PASSED'