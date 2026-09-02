#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
temporary_root="$(mktemp -d)"

cleanup() {
  rm -rf -- "$temporary_root"
}
trap cleanup EXIT

cp -aL -- "$project_root/." "$temporary_root/project"
cp -- "$temporary_root/project/themes/poimandres.json" \
  "$temporary_root/project/tests/qml/.poimandres-backup.json"
mkdir -p -- "$temporary_root/state" "$temporary_root/cache" "$temporary_root/data"

env \
  XDG_STATE_HOME="$temporary_root/state" \
  XDG_CACHE_HOME="$temporary_root/cache" \
  XDG_DATA_HOME="$temporary_root/data" \
  QE_TEST_ISOLATED=1 \
  timeout 20 quickshell -p "$temporary_root/project/tests/qml/theme-hot-reload-test.qml"
