#!/usr/bin/env bash
set -euo pipefail

# Produce an apply-time snapshot. Missing or malformed upstream values are
# intentionally represented as 1.0 so theme generation remains available.

kitty_opacity=1
hyprland_opacity=1
kitty_config=${KITTY_CONFIG_FILE:-${HOME}/.config/kitty/kitty.conf}
declare -A visited=()

valid_opacity() {
    [[ $1 =~ ^(0(\.[0-9]+)?|1(\.0+)?)$ ]] && awk -v value="$1" 'BEGIN { exit !(value >= 0 && value <= 1) }'
}

# shellcheck disable=SC2094
read_kitty_config() {
    local file=$1 line include candidate value
    [[ -f $file && -r $file ]] || return 0
    [[ ${visited[$file]+yes} ]] && return 0
    visited[$file]=1

    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%%#*}
        if [[ $line =~ ^[[:space:]]*background_opacity[[:space:]]+([^[:space:]]+) ]]; then
            value=${BASH_REMATCH[1]}
            valid_opacity "$value" && kitty_opacity=$value
        elif [[ $line =~ ^[[:space:]]*include[[:space:]]+(.+)[[:space:]]*$ ]]; then
            include=${BASH_REMATCH[1]}
            if [[ $include != /* ]]; then
                include=$(dirname -- "$file")/$include
            fi
            if [[ $include == *'*'* || $include == *'?'* || $include == *'['* ]]; then
                while IFS= read -r candidate; do
                    read_kitty_config "$candidate"
                done < <(compgen -G "$include" || true)
            else
                read_kitty_config "$include"
            fi
        fi
    done < "$file"
}

read_kitty_config "$kitty_config"

if command -v hyprctl >/dev/null 2>&1; then
    hyprland_value=$(hyprctl getoption decoration:active_opacity -j 2>/dev/null || true)
    if [[ $hyprland_value =~ \"float\"[[:space:]]*:[[:space:]]*([0-9]+(\.[0-9]+)?) ]]; then
        value=${BASH_REMATCH[1]}
        valid_opacity "$value" && hyprland_opacity=$value
    fi
fi

printf '{"kittyOpacity":%s,"hyprlandActiveOpacity":%s}\n' \
    "$kitty_opacity" "$hyprland_opacity"
