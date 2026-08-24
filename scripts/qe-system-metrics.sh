#!/usr/bin/env bash
# Bounded structured helper for thermal discovery and disk capacity.
# Contract: --mode thermal | disk [--root <fake proc/sys root>] [--sensor <path>]
# Emits one JSON object on stdout; diagnostics on stderr.

set -euo pipefail

mode=""
root=""
sensor=""
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
    --sensor)
      [[ $# -ge 2 ]] || { printf 'Missing value for --sensor\n' >&2; exit 2; }
      sensor="$2"
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

if [[ "$mode" == "disk" && -z "$root" ]]; then
  if ! disk_output=$(timeout 5 df -P -B1 -- /); then
    printf 'Failed to read root disk capacity\n' >&2
    exit 1
  fi
  mapfile -t disk_lines <<< "$disk_output"
  if [[ ${#disk_lines[@]} -lt 2 ]]; then
    printf 'Root disk capacity output is incomplete\n' >&2
    exit 1
  fi
  read -r filesystem size used available capacity mount extra <<< "${disk_lines[1]}"
  percent=${capacity%\%}
  if [[ -n "${extra:-}" || "$mount" != "/"
      || ! "$filesystem" =~ ^[A-Za-z0-9_./:+-]+$
      || ! "$size" =~ ^[0-9]+$ || ! "$used" =~ ^[0-9]+$
      || ! "$available" =~ ^[0-9]+$ || ! "$percent" =~ ^[0-9]+$
      || "$percent" -gt 100 ]]; then
    printf 'Root disk capacity output is malformed\n' >&2
    exit 1
  fi
  printf '{"schemaVersion":1,"disks":[{"filesystem":"%s","size":"%s","used":"%s","available":"%s","percent":%s,"mount":"/"}]}\n' \
    "$filesystem" "$size" "$used" "$available" "$percent"
  exit 0
fi

python3 - "$mode" "$root" "$sensor" <<'PY'
import glob
import json
import os
import subprocess
import sys
import re

mode = sys.argv[1]
root = sys.argv[2]
sensor_path = sys.argv[3]


def thermal():
    sysroot = os.path.join(root, "sys") if root else "/sys"
    sensors = []
    hwmon_dir = os.path.join(sysroot, "class", "hwmon")

    if sensor_path:
        base = os.path.abspath(hwmon_dir)
        selected = os.path.abspath(sensor_path)
        try:
            contained = os.path.commonpath([base, selected]) == base
        except ValueError:
            contained = False
        if not contained or not re.fullmatch(r"temp\d+_input", os.path.basename(selected)):
            print("Invalid thermal sensor path", file=sys.stderr)
            sys.exit(2)
        paths = [os.path.dirname(selected)]
        selected_inputs = {os.path.realpath(selected)}
    else:
        paths = sorted(glob.glob(os.path.join(hwmon_dir, "hwmon*")))
        selected_inputs = None

    for path in paths:
        name_path = os.path.join(path, "name")
        try:
            with open(name_path, "r", encoding="utf-8") as handle:
                name = handle.read().strip()
        except OSError:
            continue

        inputs = sorted(glob.glob(os.path.join(path, "temp*_input")))
        if selected_inputs is not None:
            inputs = [item for item in inputs if os.path.realpath(item) in selected_inputs]
        for temp_input in inputs:
            try:
                with open(temp_input, "r", encoding="utf-8") as handle:
                    temp = int(handle.read().strip())
            except (OSError, ValueError):
                continue

            label = ""
            label_path = temp_input.replace("_input", "_label")
            try:
                with open(label_path, "r", encoding="utf-8") as handle:
                    label = handle.read().strip()
            except OSError:
                pass

            sensors.append({
                "name": name,
                "label": label,
                "path": temp_input,
                "temp": temp
            })

    print(json.dumps({"schemaVersion": 1, "sensors": sensors}, separators=(",", ":")))


def disk():
    mount = "/"
    fixture = os.path.join(root, "disk") if root else ""

    if fixture and os.path.isfile(fixture):
        with open(fixture, "r", encoding="utf-8") as handle:
            lines = handle.read().strip().splitlines()
    else:
        result = subprocess.run(
            ["df", "-P", "-B1", "--", mount],
            capture_output=True,
            text=True,
            check=True,
            timeout=5
        )
        lines = result.stdout.strip().splitlines()

    entries = []
    for line in lines[1:]:
        parts = line.split()
        if len(parts) < 6:
            continue
        try:
            percent = int(parts[4].rstrip("%"))
        except ValueError:
            percent = 0
        entries.append({
            "filesystem": parts[0],
            "size": parts[1],
            "used": parts[2],
            "available": parts[3],
            "percent": percent,
            "mount": parts[5]
        })

    print(json.dumps({"schemaVersion": 1, "disks": entries}, separators=(",", ":")))


if mode == "thermal":
    thermal()
elif mode == "disk":
    disk()
else:
    print(f"Unknown mode: {mode}", file=sys.stderr)
    sys.exit(2)
PY
