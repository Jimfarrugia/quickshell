#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
temporary_root=$(mktemp -d)
cleanup() {
  rm -rf "$temporary_root"
}
trap cleanup EXIT

mkdir -p "$temporary_root/state" "$temporary_root/cache" "$temporary_root/data"
XDG_STATE_HOME="$temporary_root/state" \
XDG_CACHE_HOME="$temporary_root/cache" \
XDG_DATA_HOME="$temporary_root/data" \
  timeout 5 quickshell -p "$project_root/tests/qml/notification-service-test.qml"
