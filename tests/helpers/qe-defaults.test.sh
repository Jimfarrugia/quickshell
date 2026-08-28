#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

mkdir -p -- "$test_root/project" "$test_root/home" "$test_root/state" "$test_root/data" "$test_root/cache"
cp -a -- "$project_root/defaults" "$test_root/project/defaults"
printf '%s\n' poimandres >"$test_root/active-theme"
printf '%s\n' idle >"$test_root/operation"

cat >"$test_root/ipc" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
target=$1
function=$2
shift 2
[[ "${TEST_IPC_AVAILABLE:-1}" == 1 ]] || exit 1
case "$target:$function" in
    qe-theme:activeTheme) cat "$TEST_ROOT/active-theme" ;;
    qe-theme:operation|qe-theme:externalOperation|qe-wallpaper:operation|qe-wallpaper:generationStatus|qe-wallpaper:externalThemeStatus)
        cat "$TEST_ROOT/operation"
        ;;
    qe-theme:applyTheme)
        printf 'theme %s\n' "$1" >>"$TEST_ROOT/ipc.log"
        printf '%s\n' true
        ;;
    qe-wallpaper:applyDefault)
        printf '%s\n' wallpaper >>"$TEST_ROOT/ipc.log"
        printf '%s\n' true
        ;;
    *) exit 2 ;;
esac
EOF
chmod +x "$test_root/ipc"

cat >"$test_root/switcher" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$TEST_ROOT/switcher.log"
printf '%s\n' '{"schema":"theme-switcher","version":1,"status":"success"}'
EOF
chmod +x "$test_root/switcher"

run_defaults() {
    HOME="$test_root/home" \
    XDG_DATA_HOME="$test_root/data" \
    XDG_STATE_HOME="$test_root/state" \
    XDG_CACHE_HOME="$test_root/cache" \
    TEST_ROOT="$test_root" \
    TEST_IPC_AVAILABLE="${TEST_IPC_AVAILABLE:-1}" \
    QE_DEFAULTS_PROJECT_ROOT="$project_root" \
    QE_DEFAULTS_ROOT="$test_root/project/defaults" \
    QE_DEFAULTS_IPC="$test_root/ipc" \
    QE_THEME_SWITCHER="$test_root/switcher" \
        "$project_root/scripts/qe-defaults" "$1"
}

run_defaults restore
cmp -s -- "$test_root/project/defaults/wallpaper/generated-theme/applications/rofi-wallpaper.rasi" \
    "$test_root/state/qe/wallpaper/external/rofi-wallpaper.rasi"
cmp -s -- "$test_root/project/defaults/wallpaper/generated-theme/applications/yazi-wallpaper.sh" \
    "$test_root/state/qe/wallpaper/external/yazi-wallpaper.sh"
cmp -s -- "$test_root/project/defaults/wallpaper/generated-theme/applications/yazi-wallpaper.tmTheme" \
    "$test_root/state/qe/wallpaper/external/yazi-wallpaper.tmTheme"
[[ -L "$test_root/home/.config/rofi/themes/colorschemes/wallpaper.rasi" ]]
[[ "$(readlink -f -- "$test_root/home/.config/rofi/themes/colorschemes/wallpaper.rasi")" \
    == "$test_root/state/qe/wallpaper/external/rofi-wallpaper.rasi" ]]
[[ -L "$test_root/home/.config/yazi/flavors/wallpaper.yazi/wallpaper.sh" ]]
[[ -L "$test_root/home/.config/yazi/flavors/wallpaper.yazi/tmtheme.xml" ]]
grep -q -- '--machine --theme poimandres' "$test_root/switcher.log"

printf '%s\n' gruvbox >"$test_root/active-theme"
printf '%s\n' 'captured-rofi' >"$test_root/state/qe/wallpaper/external/rofi-wallpaper.rasi"

# A newly-added target may have been generated directly in the application
# config before qe-defaults restore created its runtime link. Capture migrates
# that live file into runtime state and repairs the link.
rm -f -- "$test_root/state/qe/wallpaper/external/yazi-wallpaper.sh" \
    "$test_root/state/qe/wallpaper/external/yazi-wallpaper.tmTheme"
rm -f -- "$test_root/home/.config/yazi/flavors/wallpaper.yazi/wallpaper.sh" \
    "$test_root/home/.config/yazi/flavors/wallpaper.yazi/tmtheme.xml"
cp -- "$test_root/project/defaults/wallpaper/generated-theme/applications/yazi-wallpaper.sh" \
    "$test_root/home/.config/yazi/flavors/wallpaper.yazi/wallpaper.sh"
cp -- "$test_root/project/defaults/wallpaper/generated-theme/applications/yazi-wallpaper.tmTheme" \
    "$test_root/home/.config/yazi/flavors/wallpaper.yazi/tmtheme.xml"
run_defaults capture
[[ "$(jq -r .defaultTheme "$test_root/project/defaults/manifest.json")" == gruvbox ]]
grep -q -- '^captured-rofi$' "$test_root/project/defaults/wallpaper/generated-theme/applications/rofi-wallpaper.rasi"
[[ -L "$test_root/home/.config/yazi/flavors/wallpaper.yazi/wallpaper.sh" ]]
[[ -L "$test_root/home/.config/yazi/flavors/wallpaper.yazi/tmtheme.xml" ]]

printf '%s\n' 'stale-rofi' >"$test_root/state/qe/wallpaper/external/rofi-wallpaper.rasi"
run_defaults restore
grep -q -- '^captured-rofi$' "$test_root/state/qe/wallpaper/external/rofi-wallpaper.rasi"

manifest_before=$(sha256sum "$test_root/project/defaults/manifest.json")
printf '%s\n' pending >"$test_root/operation"
if run_defaults capture >/dev/null 2>&1; then
    printf '%s\n' 'capture unexpectedly succeeded while an operation was pending' >&2
    exit 1
fi
[[ "$(sha256sum "$test_root/project/defaults/manifest.json")" == "$manifest_before" ]]
printf '%s\n' idle >"$test_root/operation"

jq '.defaultTheme = "wallpaper"' "$test_root/project/defaults/manifest.json" >"$test_root/manifest.tmp"
mv -- "$test_root/manifest.tmp" "$test_root/project/defaults/manifest.json"
: >"$test_root/switcher.log"
TEST_IPC_AVAILABLE=0 run_defaults restore
grep -q -- '--machine --theme wallpaper --skip-gtk' "$test_root/switcher.log"

printf '%s\n' QE_DEFAULTS_TEST_PASSED
