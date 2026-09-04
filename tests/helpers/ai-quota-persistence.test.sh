#!/usr/bin/env bash
set -euo pipefail

state_dir="$(mktemp -d)"
trap 'rm -rf "$state_dir"' EXIT

run_case() {
  local mode="$1"
  local output
  local status=0
  output="$(XDG_STATE_HOME="$state_dir" QE_AI_QUOTA_TEST_MODE="$mode" timeout 5 quickshell -p tests/qml/ai-quota-persistence-test.qml 2>&1)" || status=$?
  [[ "$status" -eq 0 || "$status" -eq 124 ]]
  [[ "$output" == *"AI_QUOTA_PERSISTENCE_${mode^^}_PASSED"* ]]
  [[ "$output" != *"AI_QUOTA_PERSISTENCE_TEST_FAILED"* ]]
}

run_case write
run_case read
state_files=("$state_dir"/quickshell/by-shell/*/ai-quota.json)
[[ "${#state_files[@]}" -eq 1 ]]
printf '%s\n' '{"schemaVersion":1,"selectedProvider":"invalid"}' > "${state_files[0]}"
run_case invalid
printf '%s\n' "AI_QUOTA_PERSISTENCE_TEST_PASSED"
