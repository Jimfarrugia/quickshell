#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
project_root=$(cd "$script_dir/../.." && pwd)
helper="$project_root/scripts/qe-system-metrics.sh"
fixtures="$project_root/tests/fixtures/system-metrics"

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$helper"
else
  echo "shellcheck not installed; skipping" >&2
fi

thermal_output=$("$helper" --mode thermal --root "$fixtures")
python3 - "$thermal_output" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["schemaVersion"] == 1, data
assert len(data["sensors"]) == 2, data
assert any(s["name"] == "k10temp" and s["label"] == "Tctl" and s["temp"] == 42850 for s in data["sensors"])
PY

selected_sensor="$fixtures/sys/class/hwmon/hwmon0/temp1_input"
selected_output=$("$helper" --mode thermal --root "$fixtures" --sensor "$selected_sensor")
python3 - "$selected_output" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert len(data["sensors"]) == 1, data
assert data["sensors"][0]["label"] == "Tctl", data
PY

if "$helper" --mode thermal --root "$fixtures" --sensor /etc/passwd >/dev/null 2>&1; then
  echo "helper accepted a sensor outside the hwmon root" >&2
  exit 1
fi

symlink_root=$(mktemp -d)
trap 'rm -rf "$symlink_root"' EXIT
mkdir -p "$symlink_root/sys/class/hwmon" "$symlink_root/sys/devices/platform/coretemp/hwmon/hwmon6"
printf 'coretemp\n' > "$symlink_root/sys/devices/platform/coretemp/hwmon/hwmon6/name"
printf 'Package id 0\n' > "$symlink_root/sys/devices/platform/coretemp/hwmon/hwmon6/temp1_label"
printf '37000\n' > "$symlink_root/sys/devices/platform/coretemp/hwmon/hwmon6/temp1_input"
ln -s ../../devices/platform/coretemp/hwmon/hwmon6 "$symlink_root/sys/class/hwmon/hwmon6"
symlink_sensor="$symlink_root/sys/class/hwmon/hwmon6/temp1_input"
symlink_output=$("$helper" --mode thermal --root "$symlink_root" --sensor "$symlink_sensor")
python3 - "$symlink_output" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert len(data["sensors"]) == 1, data
assert data["sensors"][0]["name"] == "coretemp", data
assert data["sensors"][0]["label"] == "Package id 0", data
assert data["sensors"][0]["temp"] == 37000, data
PY

disk_output=$("$helper" --mode disk --root "$fixtures")
python3 - "$disk_output" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["schemaVersion"] == 1, data
assert len(data["disks"]) == 1, data
disk = data["disks"][0]
assert disk["mount"] == "/", disk
assert disk["percent"] == 40, disk
PY

live_disk_output=$("$helper" --mode disk)
python3 - "$live_disk_output" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["schemaVersion"] == 1, data
assert len(data["disks"]) == 1, data
disk = data["disks"][0]
assert disk["mount"] == "/", data
assert disk["size"].isdigit() and disk["used"].isdigit() and disk["available"].isdigit(), data
assert 0 <= disk["percent"] <= 100, data
PY

if "$helper" --mode >/dev/null 2>&1; then
  echo "helper accepted a missing --mode value" >&2
  exit 1
fi

echo "system-metrics helper tests passed"
