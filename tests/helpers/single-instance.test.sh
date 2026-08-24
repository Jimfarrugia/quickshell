#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
fixture="$project_root/tests/fixtures/single-instance/shell.qml"
log_file=$(mktemp)
first_pid=""

cleanup() {
  if [[ -n "$first_pid" ]] && kill -0 "$first_pid" 2>/dev/null; then
    kill "$first_pid" 2>/dev/null || true
    wait "$first_pid" 2>/dev/null || true
  fi
  rm -f "$log_file"
}
trap cleanup EXIT

quickshell --no-duplicate --path "$fixture" >"$log_file" 2>&1 &
first_pid=$!

for _ in {1..50}; do
  if qs list --all 2>/dev/null | grep -Fq "Config path: $fixture"; then
    break
  fi
  sleep 0.05
done

if ! kill -0 "$first_pid" 2>/dev/null; then
  printf 'first guarded fixture instance exited before the duplicate test\n' >&2
  exit 1
fi

duplicate_output=$(quickshell --no-duplicate --path "$fixture" 2>&1)
if [[ "$duplicate_output" != *"already running"* ]]; then
  printf 'duplicate launch did not report the existing instance: %s\n' "$duplicate_output" >&2
  exit 1
fi
if ! kill -0 "$first_pid" 2>/dev/null; then
  printf 'duplicate launch disturbed the original instance\n' >&2
  exit 1
fi

instance_count=$(qs list --all 2>/dev/null | grep -Fc "Config path: $fixture")
if [[ "$instance_count" -ne 1 ]]; then
  printf 'expected one guarded fixture instance, found %s\n' "$instance_count" >&2
  exit 1
fi

printf 'single-instance launch guard tests passed\n'
