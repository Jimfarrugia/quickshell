#!/usr/bin/env bash

set -euo pipefail

theme=""
while (($# > 0)); do
  case "$1" in
    --machine) ;;
    --theme)
      shift
      theme="${1-}"
      ;;
  esac
  shift
done

case "${FAKE_EXTERNAL_MODE:-success}" in
  success)
    printf '{"schema":"theme-switcher","version":1,"mode":"machine","requestedTheme":"%s","skipGtk":false,"status":"success","timestamp":"2026-08-25T12:00:00Z","persisted":true,"error":null,"results":[{"target":"gtk","status":"applied","exitCode":0,"reason":null,"detail":null}]}\n' "$theme"
    ;;
  partial)
    printf '{"schema":"theme-switcher","version":1,"mode":"machine","requestedTheme":"%s","skipGtk":false,"status":"partial","timestamp":"2026-08-25T12:00:00Z","persisted":true,"error":null,"results":[{"target":"gtk","status":"applied","exitCode":0,"reason":null,"detail":null},{"target":"nvim","status":"failed","exitCode":1,"reason":null,"detail":"fixture failure"}]}\n' "$theme"
    exit 3
    ;;
  malformed)
    printf '{not-json}\n'
    exit 4
    ;;
  timeout)
    sleep 2
    ;;
  *)
    printf 'unsupported fake mode\n' >&2
    exit 4
    ;;
esac
