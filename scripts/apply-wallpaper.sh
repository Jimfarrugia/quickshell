#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || -z "${1:-}" ]]; then
    printf 'Usage: %s <wallpaper-path>\n' "$0" >&2
    exit 2
fi

wallpaper_path=$1
if [[ ! -f "$wallpaper_path" || ! -r "$wallpaper_path" ]]; then
    printf 'Wallpaper is not a readable file: %s\n' "$wallpaper_path" >&2
    exit 2
fi

if [[ "$(file --mime-type -b -- "$wallpaper_path")" != image/* ]]; then
    printf 'Wallpaper is not an image: %s\n' "$wallpaper_path" >&2
    exit 2
fi

for dependency in hyprctl jq magick pkill hyprpaper nohup; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'Required wallpaper dependency is unavailable: %s\n' "$dependency" >&2
        exit 127
    fi
done

resolution=$(hyprctl monitors -j | jq -er 'map(select(.focused == true)) | .[0] | "\(.width)x\(.height)"')
if [[ ! "$resolution" =~ ^[1-9][0-9]*x[1-9][0-9]*$ ]]; then
    printf 'Could not determine a focused monitor resolution.\n' >&2
    exit 1
fi

data_home=${XDG_DATA_HOME:-$HOME/.local/share}
mkdir -p -- "$data_home"
temporary_dir=$(mktemp -d "$data_home/.qe-wallpaper.XXXXXX")
backup_dir=$(mktemp -d "$data_home/.qe-wallpaper-backup.XXXXXX")
rollback_needed=0

rollback_outputs() {
    rm -f -- "$data_home/current_wallpaper.png" "$data_home/current_lockscreen.png"
    if [[ -e "$backup_dir/current_wallpaper.png" ]]; then
        mv -f -- "$backup_dir/current_wallpaper.png" "$data_home/current_wallpaper.png"
    fi
    if [[ -e "$backup_dir/current_lockscreen.png" ]]; then
        mv -f -- "$backup_dir/current_lockscreen.png" "$data_home/current_lockscreen.png"
    fi
}

cleanup() {
    if ((rollback_needed)); then
        rollback_outputs
    fi
    rm -rf -- "$temporary_dir" "$backup_dir"
}
trap cleanup EXIT

wallpaper_output="$temporary_dir/current_wallpaper.png"
lockscreen_output="$temporary_dir/current_lockscreen.png"

magick "$wallpaper_path" \
    -auto-orient \
    -resize "${resolution}^" \
    -gravity center \
    -extent "$resolution" \
    "$wallpaper_output"

image_size=$(magick "$wallpaper_output" -format '%wx%h' info:)
if [[ ! "$image_size" =~ ^[1-9][0-9]*x[1-9][0-9]*$ ]]; then
    printf 'Wallpaper conversion produced an invalid image size.\n' >&2
    exit 1
fi

magick "$wallpaper_output" \
    \( -size "$image_size" gradient:transparent-black -rotate 0 \) \
    -compose over \
    -composite \
    "$lockscreen_output"

for output in current_wallpaper.png current_lockscreen.png; do
    if [[ -e "$data_home/$output" ]]; then
        mv -f -- "$data_home/$output" "$backup_dir/$output"
    fi
done
rollback_needed=1
mv -f -- "$wallpaper_output" "$data_home/current_wallpaper.png"
mv -f -- "$lockscreen_output" "$data_home/current_lockscreen.png"

pkill -x hyprpaper >/dev/null 2>&1 || true
nohup hyprpaper >/dev/null 2>&1 &

wallpaper_request=",$data_home/current_wallpaper.png,cover"
confirmed=0
for _ in {1..40}; do
    if hyprctl -q hyprpaper wallpaper "$wallpaper_request" >/dev/null 2>&1; then
        confirmed=1
        break
    fi
    sleep 0.05
done

if ((confirmed == 0)); then
    printf 'Hyprpaper did not accept the wallpaper request.\n' >&2
    exit 1
fi

rollback_needed=0
printf '%s\n' 'Hyprpaper IPC confirmed'
