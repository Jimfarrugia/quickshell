#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 0 ]]; then
  printf 'Usage: %s\n' "$0" >&2
  exit 2
fi

hyprshot_bin=$(command -v hyprshot || true)
if [[ -z "$hyprshot_bin" ]]; then
  printf 'hyprshot is not available\n' >&2
  exit 127
fi

script_dir=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
notification_helper="$script_dir/qe-hyprshot-notification.py"
if [[ ! -x "$notification_helper" ]]; then
  printf 'Hyprshot notification helper is not executable\n' >&2
  exit 1
fi

if [[ -n "${XDG_RUNTIME_DIR:-}" && -S "$XDG_RUNTIME_DIR/bus" ]]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
fi

pictures_dir=$(xdg-user-dir PICTURES 2>/dev/null || true)
pictures_dir=${pictures_dir:-"$HOME/Pictures"}
screenshot_dir="$pictures_dir/Screenshots"
filename="Screenshot-$(date +%Y%m%d-%H%M%S)-$BASHPID.png"
screenshot_path="$screenshot_dir/$filename"

mkdir -p -- "$screenshot_dir"
capture_status=0
"$hyprshot_bin" -s -m region -o "$screenshot_dir" -f "$filename" || capture_status=$?

if [[ ! -f "$screenshot_path" ]]; then
  printf 'hyprshot did not create %s\n' "$screenshot_path" >&2
  [[ "$capture_status" -ne 0 ]] || capture_status=1
  exit "$capture_status"
fi

"$notification_helper" "$screenshot_path" "$screenshot_dir" >/dev/null 2>&1 &
