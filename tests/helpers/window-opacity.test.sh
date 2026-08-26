#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

fake_bin="$test_root/bin"
mkdir -p -- "$fake_bin" "$test_root/kitty"
cat >"$fake_bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
if [[ ${QE_FAKE_HYPR_INVALID:-0} == 1 ]]; then
    printf '%s\n' '{"option":"decoration:active_opacity","float":"bad","set":true}'
    exit 0
fi
printf '%s\n' '{"option":"decoration:active_opacity","float":0.8,"set":true}'
EOF
chmod +x "$fake_bin/hyprctl"
printf '%s\n' 'background_opacity 0.75' >"$test_root/kitty/extra.conf"
printf '%s\n' 'include extra.conf' 'background_opacity 0.9' >"$test_root/kitty/kitty.conf"

result=$(PATH="$fake_bin:$PATH" KITTY_CONFIG_FILE="$test_root/kitty/kitty.conf" \
    "$project_root/scripts/qe-window-opacity.sh")
[[ "$result" == '{"kittyOpacity":0.9,"hyprlandActiveOpacity":0.8}' ]]

empty_config="$test_root/empty.conf"
: >"$empty_config"
fallback=$(PATH="$fake_bin:$PATH" QE_FAKE_HYPR_INVALID=1 KITTY_CONFIG_FILE="$empty_config" \
    "$project_root/scripts/qe-window-opacity.sh")
[[ "$fallback" == '{"kittyOpacity":1,"hyprlandActiveOpacity":1}' ]]

printf '%s\n' 'WINDOW_OPACITY_HELPER_TEST_PASSED'
