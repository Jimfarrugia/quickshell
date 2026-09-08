#!/usr/bin/env bash
set -euo pipefail

restart=0
detach=0
service_start=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --restart) restart=1 ;;
        --detach) detach=1 ;;
        --service-start) service_start=1 ;;
        *)
            printf 'Usage: %s [--restart] [--detach] [--service-start]\n' "$0" >&2
            exit 2
            ;;
    esac
    shift
done

script_path=$(readlink -f -- "${BASH_SOURCE[0]}")
script_dir=$(cd -- "$(dirname -- "$script_path")" && pwd)
project_root=$(cd -- "$script_dir/.." && pwd)

if ((service_start)); then
    if ((restart || detach)); then
        printf '%s\n' 'QE service start failed: --service-start cannot be combined with other options.' >&2
        exit 2
    fi
    for variable in WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP; do
        if [[ -z "${!variable:-}" ]]; then
            printf 'QE service start failed: %s is unavailable.\n' "$variable" >&2
            exit 1
        fi
    done
    if ! command -v dbus-update-activation-environment >/dev/null 2>&1; then
        printf '%s\n' 'QE service start failed: dbus-update-activation-environment is unavailable.' >&2
        exit 127
    fi
    if ! command -v systemctl >/dev/null 2>&1; then
        printf '%s\n' 'QE service start failed: systemctl is unavailable.' >&2
        exit 127
    fi
    dbus-update-activation-environment --systemd \
        WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP
    exec systemctl --user restart qe-shell.service
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
        printf '%s\n' 'QE restart failed: the previous shell did not exit.' >&2
        return 1
    fi
}

if ((restart)); then
    if command -v systemctl >/dev/null 2>&1 \
        && systemctl --user is-active --quiet qe-shell.service; then
        if ((detach)); then
            printf '%s\n' 'QE restart failed: --detach cannot replace an active supervised service.' >&2
            exit 2
        fi
        exec systemctl --user restart qe-shell.service
    fi
    restart_instance
fi

if ! command -v quickshell >/dev/null 2>&1; then
  printf 'QE launch failed: quickshell is not installed or not in PATH.\n' >&2
  exit 127
fi

if [[ -z "${QE_MATUGEN:-}" ]]; then
    QE_MATUGEN=$(command -v matugen || true)
fi
export QE_MATUGEN

if [[ -z "${QE_WALLPAPER_HELPER:-}" ]]; then
    QE_WALLPAPER_HELPER="$project_root/scripts/qe-wallpaper"
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

if ((detach)); then
    nohup setsid quickshell --no-duplicate --path "$project_root/shell.qml" \
        </dev/null >/dev/null 2>&1 &
    printf 'QE started in detached mode (PID %s).\n' "$!"
    exit 0
fi

exec quickshell --no-duplicate --path "$project_root/shell.qml"
