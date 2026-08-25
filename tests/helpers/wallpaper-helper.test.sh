#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

bin_dir="$test_root/bin"
data_dir="$test_root/data"
mkdir -p -- "$bin_dir" "$data_dir"

cat >"$bin_dir/hyprctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_HYPRCTL_LOG:?}"
if [[ "${1-}" == "-q" ]]; then
    shift
fi
if [[ "${1-}" == "hyprpaper" ]]; then
    exit "${FAKE_HYPRPAPER_EXIT:-0}"
fi
printf '%s\n' '[{"focused":true,"width":1920,"height":1080}]'
EOF
cat >"$bin_dir/magick" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${*: -1}" == "info:" ]]; then
    printf '%s\n' '1920x1080'
else
    output=${!#}
    printf '%s\n' 'generated image' >"$output"
fi
EOF
cat >"$bin_dir/pkill" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
cat >"$bin_dir/hyprpaper" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$bin_dir"/*

printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' \
    | base64 --decode >"$test_root/source.png"
FAKE_HYPRCTL_LOG="$test_root/hyprctl.log" PATH="$bin_dir:$PATH" XDG_DATA_HOME="$data_dir" \
    "$project_root/scripts/apply-wallpaper.sh" "$test_root/source.png"

[[ -s "$data_dir/current_wallpaper.png" ]]
[[ -s "$data_dir/current_lockscreen.png" ]]
grep -q 'hyprpaper wallpaper' "$test_root/hyprctl.log"
if compgen -G "$data_dir/.qe-wallpaper.*" >/dev/null; then
    printf '%s\n' 'temporary wallpaper directory remains' >&2
    exit 1
fi

printf '%s\n' prior >"$data_dir/current_wallpaper.png"
printf '%s\n' prior >"$data_dir/current_lockscreen.png"
if FAKE_HYPRPAPER_EXIT=1 FAKE_HYPRCTL_LOG="$test_root/hyprctl-failure.log" \
    PATH="$bin_dir:$PATH" XDG_DATA_HOME="$data_dir" \
    "$project_root/scripts/apply-wallpaper.sh" "$test_root/source.png"; then
    printf '%s\n' 'failed Hyprpaper IPC was accepted' >&2
    exit 1
fi
[[ "$(<"$data_dir/current_wallpaper.png")" == prior ]]
[[ "$(<"$data_dir/current_lockscreen.png")" == prior ]]

printf '%s\n' 'WALLPAPER_HELPER_TEST_PASSED'
