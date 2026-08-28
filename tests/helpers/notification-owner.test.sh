#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
project_root=$(cd "$script_dir/../.." && pwd)
helper="$project_root/scripts/qe-notification-owner.sh"

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$helper"
fi

output=$(timeout 2 "$helper" --qe-pid 999999 || [[ $? -eq 124 ]])
python3 - "$output" <<'PY'
import json
import sys

record = json.loads(sys.argv[1].splitlines()[0])
assert record["schemaVersion"] == 1, record
assert record["owner"] in {"none", "dunst", "qe", "other"}, record
assert isinstance(record["uniqueName"], str), record
assert isinstance(record["pid"], int), record
PY

echo "NOTIFICATION_OWNER_HELPER_TEST_PASSED"
