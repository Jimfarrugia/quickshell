#!/usr/bin/env bash
set -euo pipefail

case "${QE_FAKE_MATUGEN_MODE:-success}" in
    success)
        printf '%s\n' '{"colors":{"dark":{"background":"#101820","on_background":"#f4f7fb","surface":"#18232d","on_surface":"#f4f7fb","surface_variant":"#3f4b56","surface_container_high":"#29343e","on_surface_variant":"#d1dae4","primary":"#9ecaff","on_primary":"#003258","primary_container":"#1c4a73","on_primary_container":"#d1e5ff","secondary":"#b5c9e2","on_secondary":"#1f3348","secondary_container":"#364b62","on_secondary_container":"#d1e5ff","tertiary":"#d5bce5","on_tertiary":"#392347","tertiary_container":"#513a5e","on_tertiary_container":"#f2daff","outline":"#8b96a2","outline_variant":"#414b56","error":"#ffb4ab","shadow":"#000000","scrim":"#000000"}}}'
        ;;
    malformed)
        printf '%s\n' '{not-json}'
        ;;
    timeout)
        sleep 2
        ;;
    *)
        printf 'unsupported fake Matugen mode\n' >&2
        exit 1
        ;;
esac
