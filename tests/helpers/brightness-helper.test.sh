#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
project_root=$(cd "$script_dir/../.." && pwd)
helper="$project_root/scripts/qe-brightness.sh"
fixtures="$project_root/tests/fixtures/brightness"

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$helper"
else
  echo "shellcheck not installed; skipping" >&2
fi

discover_output=$("$helper" --mode discover --root "$fixtures")
python3 - "$discover_output" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["schemaVersion"] == 1, data
assert len(data["devices"]) == 1, data
dev = data["devices"][0]
assert dev["name"] == "intel_backlight", dev
assert dev["class"] == "backlight", dev
assert dev["brightness"] == 1060, dev
assert dev["maxBrightness"] == 1060, dev
assert dev["percent"] == 100, dev
PY

read_output=$("$helper" --mode read --root "$fixtures" --device intel_backlight)
python3 - "$read_output" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["name"] == "intel_backlight", data
assert data["brightness"] == 1060, data
assert data["maxBrightness"] == 1060, data
assert data["percent"] == 100, data
PY

# Use a disposable root for all set tests so committed fixtures stay immutable.
tmp_root=$(mktemp -d)
trap 'rm -rf "$tmp_root"' EXIT
mkdir -p "$tmp_root/sys/class/backlight/intel_backlight"
printf '1060\n' > "$tmp_root/sys/class/backlight/intel_backlight/max_brightness"
printf '1060\n' > "$tmp_root/sys/class/backlight/intel_backlight/brightness"

set_output=$("$helper" --mode set --root "$tmp_root" --device intel_backlight --percent 50)
python3 - "$set_output" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["name"] == "intel_backlight", data
assert data["brightness"] == 530, data
assert data["maxBrightness"] == 1060, data
assert data["percent"] == 50, data
PY

set_output=$("$helper" --mode set --root "$tmp_root" --device intel_backlight --percent 1)
python3 - "$set_output" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["brightness"] == 11, data
assert data["percent"] == 1, data
PY

set_output=$("$helper" --mode set --root "$tmp_root" --device intel_backlight --percent 100)
python3 - "$set_output" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["brightness"] == 1060, data
assert data["percent"] == 100, data
PY

if "$helper" --mode set --root "$tmp_root" --device intel_backlight --percent 0 >/dev/null 2>&1; then
  echo "helper accepted percent 0" >&2
  exit 1
fi

if "$helper" --mode set --root "$tmp_root" --device intel_backlight --percent 101 >/dev/null 2>&1; then
  echo "helper accepted percent 101" >&2
  exit 1
fi

keyboard_root=$(mktemp -d)
trap 'rm -rf "$keyboard_root" "$tmp_root"' EXIT
mkdir -p "$keyboard_root/sys/class/leds/tpacpi::power" "$keyboard_root/sys/class/leds/tpacpi::kbd_backlight"
printf '255\n' > "$keyboard_root/sys/class/leds/tpacpi::power/max_brightness"
printf '255\n' > "$keyboard_root/sys/class/leds/tpacpi::power/brightness"
printf '1\n' > "$keyboard_root/sys/class/leds/tpacpi::kbd_backlight/max_brightness"
printf '0\n' > "$keyboard_root/sys/class/leds/tpacpi::kbd_backlight/brightness"
keyboard_discover=$($helper --mode discover --root "$keyboard_root" --class leds)
python3 - "$keyboard_discover" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert len(data["devices"]) == 2, data
assert any(device["name"] == "tpacpi::kbd_backlight" for device in data["devices"]), data
PY

if "$helper" --mode read --root "$fixtures" --device '../etc/passwd' >/dev/null 2>&1; then
  echo "helper accepted a device name with path traversal" >&2
  exit 1
fi

if "$helper" --mode read --root "$fixtures" --device broken_device >/dev/null 2>&1; then
  echo "helper accepted a device with malformed brightness" >&2
  exit 1
fi

empty_root=$(mktemp -d)
trap 'rm -rf "$empty_root" "$tmp_root"' EXIT
mkdir -p "$empty_root/sys/class"
discover_empty=$("$helper" --mode discover --root "$empty_root")
python3 - "$discover_empty" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["schemaVersion"] == 1, data
assert data["devices"] == [], data
PY

missing_path=$(mktemp -d)
trap 'rm -rf "$empty_root" "$tmp_root" "$missing_path"' EXIT
ln -s /usr/bin/python3 "$missing_path/python3"
if PATH="$missing_path" /usr/bin/bash "$helper" --mode discover >/dev/null 2>&1; then
  echo "helper succeeded without brightnessctl" >&2
  exit 1
fi

echo "brightness helper tests passed"
