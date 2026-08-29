#!/usr/bin/env bash
# Bounded structured helper for backlight discovery, read, and set.
# Contract: --mode discover | read | set [--root <fake proc/sys root>]
#           [--class backlight|leds] [--device <name>] [--percent <1..100>]
# Emits one JSON object on stdout; diagnostics on stderr.

set -euo pipefail

mode=""
root=""
device=""
percent=""
device_class="backlight"
export LC_ALL=C

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      [[ $# -ge 2 ]] || { printf 'Missing value for --mode\n' >&2; exit 2; }
      mode="$2"
      shift 2
      ;;
    --root)
      [[ $# -ge 2 ]] || { printf 'Missing value for --root\n' >&2; exit 2; }
      root="$2"
      shift 2
      ;;
    --device)
      [[ $# -ge 2 ]] || { printf 'Missing value for --device\n' >&2; exit 2; }
      device="$2"
      shift 2
      ;;
    --percent)
      [[ $# -ge 2 ]] || { printf 'Missing value for --percent\n' >&2; exit 2; }
      percent="$2"
      shift 2
      ;;
    --class)
      [[ $# -ge 2 ]] || { printf 'Missing value for --class\n' >&2; exit 2; }
      device_class="$2"
      shift 2
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$mode" ]]; then
  printf 'Missing required --mode\n' >&2
  exit 2
fi

if [[ "$device_class" != "backlight" && "$device_class" != "leds" ]]; then
  printf 'Unsupported brightness class: %s\n' "$device_class" >&2
  exit 2
fi

sysroot() {
  if [[ -n "$root" ]]; then
    printf '%s/sys/class/%s' "$root" "$device_class"
  else
    printf '/sys/class/%s' "$device_class"
  fi
}

validate_device_name() {
  local name="$1"
  if [[ -z "$name" ]]; then
    printf 'Device name is required\n' >&2
    return 1
  fi
  if [[ ! "$name" =~ ^[a-zA-Z0-9_:.-]+$ ]]; then
    printf 'Invalid device name: %s\n' "$name" >&2
    return 1
  fi
}

read_file() {
  local path="$1"
  if [[ ! -r "$path" ]]; then
    printf 'Cannot read %s\n' "$path" >&2
    return 1
  fi
  tr -d '[:space:]' < "$path"
}

discover_sysfs() {
  local base
  base="$(sysroot)"
  if [[ ! -d "$base" ]]; then
    printf '{"schemaVersion":1,"devices":[]}\n'
    return 0
  fi
  python3 - "$base" <<'PY'
import json
import os
import sys

base = sys.argv[1]
devices = []
for name in sorted(os.listdir(base)):
    path = os.path.join(base, name)
    if not os.path.isdir(path):
        continue
    try:
        with open(os.path.join(path, "brightness"), "r", encoding="utf-8") as b:
            brightness = int(b.read().strip())
        with open(os.path.join(path, "max_brightness"), "r", encoding="utf-8") as m:
            max_brightness = int(m.read().strip())
    except (OSError, ValueError):
        continue
    percent = round(100 * brightness / max_brightness) if max_brightness > 0 else 0
    devices.append({
        "name": name,
        "class": "backlight",
        "brightness": brightness,
        "maxBrightness": max_brightness,
        "percent": percent
    })
print(json.dumps({"schemaVersion": 1, "devices": devices}, separators=(",", ":")))
PY
}

discover_brightnessctl() {
  local output
  if ! output=$(brightnessctl -c "$device_class" -m -l 2>/dev/null); then
    printf 'brightnessctl discovery failed\n' >&2
    return 1
  fi
  if [[ -z "$output" ]]; then
    printf '{"schemaVersion":1,"devices":[]}\n'
    return 0
  fi
  python3 - "$output" <<'PY'
import json
import sys

devices = []
for line in sys.argv[1].strip().splitlines():
    parts = line.split(",")
    if len(parts) < 5:
        continue
    try:
        brightness = int(parts[2])
        percent = int(parts[3].rstrip("%"))
        max_brightness = int(parts[4])
    except ValueError:
        continue
    devices.append({
        "name": parts[0],
        "class": parts[1],
        "brightness": brightness,
        "maxBrightness": max_brightness,
        "percent": percent
    })
print(json.dumps({"schemaVersion": 1, "devices": devices}, separators=(",", ":")))
PY
}

read_device() {
  local base path
  base="$(sysroot)"
  path="$base/$device"
  if ! validate_device_name "$device"; then
    return 1
  fi
  local brightness max_brightness percent
  brightness=$(read_file "$path/brightness") || return 1
  max_brightness=$(read_file "$path/max_brightness") || return 1
  percent=$(python3 - "$brightness" "$max_brightness" <<'PY'
import sys
brightness = int(sys.argv[1])
max_brightness = int(sys.argv[2])
print(round(100 * brightness / max_brightness) if max_brightness > 0 else 0)
PY
) || return 1
  printf '{"schemaVersion":1,"name":"%s","brightness":%s,"maxBrightness":%s,"percent":%s}\n' \
    "$device" "$brightness" "$max_brightness" "$percent"
}

set_device() {
  local base path
  base="$(sysroot)"
  path="$base/$device"
  if ! validate_device_name "$device"; then
    return 1
  fi
  if [[ -z "$percent" ]]; then
    printf 'Missing --percent for set\n' >&2
    return 2
  fi
  if ! [[ "$percent" =~ ^[0-9]+$ ]] || (( percent < 1 || percent > 100 )); then
    printf 'Percent must be an integer from 1 to 100\n' >&2
    return 2
  fi

  local max_brightness
  max_brightness=$(read_file "$path/max_brightness") || return 1

  local raw
  raw=$(python3 - "$percent" "$max_brightness" <<'PY'
import sys
percent = int(sys.argv[1])
max_brightness = int(sys.argv[2])
print(max(1, round(percent * max_brightness / 100)))
PY
) || return 1

  if [[ -n "$root" ]]; then
    if [[ ! -w "$path/brightness" ]]; then
      printf 'Cannot write %s/brightness\n' "$path" >&2
      return 1
    fi
    printf '%s\n' "$raw" > "$path/brightness"
  else
    if ! brightnessctl -c "$device_class" -d "$device" -q s "${percent}%" >/dev/null 2>&1; then
      printf 'brightnessctl set failed for %s\n' "$device" >&2
      return 1
    fi
  fi

  # Authoritative post-set read.
  local brightness new_percent
  brightness=$(read_file "$path/brightness") || return 1
  new_percent=$(python3 - "$brightness" "$max_brightness" <<'PY'
import sys
brightness = int(sys.argv[1])
max_brightness = int(sys.argv[2])
print(round(100 * brightness / max_brightness) if max_brightness > 0 else 0)
PY
) || return 1
  printf '{"schemaVersion":1,"name":"%s","brightness":%s,"maxBrightness":%s,"percent":%s}\n' \
    "$device" "$brightness" "$max_brightness" "$new_percent"
}

case "$mode" in
  discover)
    if [[ -n "$root" ]]; then
      discover_sysfs
    else
      discover_brightnessctl
    fi
    ;;
  read)
    read_device
    ;;
  set)
    set_device
    ;;
  *)
    printf 'Unknown mode: %s\n' "$mode" >&2
    exit 2
    ;;
esac
