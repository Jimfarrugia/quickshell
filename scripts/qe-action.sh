#!/usr/bin/env bash
set -euo pipefail

script_path=$(readlink -f -- "${BASH_SOURCE[0]}")
script_dir=$(cd -- "$(dirname -- "$script_path")" && pwd)

if [[ $# -ne 1 ]]; then
  printf 'Usage: %s <action>\n' "$0" >&2
  exit 2
fi

case "$1" in
  volumeUp|volumeDown|toggleVolumeMute|toggleMicrophoneMute|\
  brightnessUp|brightnessDown|keyboardBrightnessUp|keyboardBrightnessDown|\
  mediaNext|mediaPrevious|mediaToggle|notificationsToggle|notificationsDismissAll)
    exec "$script_dir/qe-launch.sh" qe-actions "$1"
    ;;
  *)
    printf 'Unknown QE action: %s\n' "$1" >&2
    exit 2
    ;;
esac
