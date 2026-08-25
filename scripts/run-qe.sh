#!/usr/bin/env bash
set -euo pipefail

restart=0
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "--restart" ]]; then
        restart=1
    else
        printf 'Usage: %s [--restart]\n' "$0" >&2
        exit 2
    fi
fi

script_path=$(readlink -f -- "${BASH_SOURCE[0]}")
script_dir=$(cd -- "$(dirname -- "$script_path")" && pwd)
project_root=$(cd -- "$script_dir/.." && pwd)

if ! command -v quickshell >/dev/null 2>&1; then
  printf 'QE launch failed: quickshell is not installed or not in PATH.\n' >&2
  exit 127
fi

# Gracefully stop any running shell of this config so --no-duplicate can start a
# fresh instance. The pattern is scoped to this project's shell path.
restart_instance() {
    local pid pids alive
    local shell_pattern="quickshell --no-duplicate --path ${project_root}/shell.qml"
    mapfile -t pids < <(pgrep -f -- "$shell_pattern" || true)
    for pid in "${pids[@]}"; do
        kill -TERM -- "$pid" 2>/dev/null || true
    done
    if ((${#pids[@]} > 0)); then
        for _ in {1..50}; do
            alive=0
            for pid in "${pids[@]}"; do
                if kill -0 -- "$pid" 2>/dev/null; then
                    alive=1
                    break
                fi
            done
            [[ $alive -eq 0 ]] && return 0
            sleep 0.1
        done
        for pid in "${pids[@]}"; do
            kill -KILL -- "$pid" 2>/dev/null || true
        done
    fi
}

if ((restart)); then
    restart_instance
fi

if [[ -z "${QE_MATUGEN:-}" ]]; then
    QE_MATUGEN=$(command -v matugen || true)
fi
export QE_MATUGEN

if [[ -z "${QE_WALLPAPER_HELPER:-}" ]]; then
    QE_WALLPAPER_HELPER="$project_root/scripts/apply-wallpaper.sh"
fi
export QE_WALLPAPER_HELPER

# External theming stays behind the explicit QE_THEME_SWITCHER boundary.
# Prefer the installed qe-theme-switcher helper when present so a stable path
# is wired without assuming the theme-switcher repository location.
if [[ -z "${QE_THEME_SWITCHER:-}" ]]; then
    QE_THEME_SWITCHER=$(command -v qe-theme-switcher || true)
    if [[ -z "$QE_THEME_SWITCHER" && -x "$HOME/.local/bin/qe-theme-switcher" ]]; then
        QE_THEME_SWITCHER="$HOME/.local/bin/qe-theme-switcher"
    fi
fi
export QE_THEME_SWITCHER

exec quickshell --no-duplicate --path "$project_root/shell.qml"
