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

# shellcheck disable=SC1091
source "$script_dir/lib/qe-installation.sh"

activation_fail() {
    local code=$1 context=$2
    qe_write_installation_receipt activation-failed "$project_root" "$code" "$context" || true
    printf 'QE service start failed: %s\n' "$context" >&2
    return 1
}

bus_owner_pid() {
    local name=$1 reply owner pid_reply pid
    reply=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus GetNameOwner s "$name" 2>/dev/null || true)
    read -r _ owner <<<"$reply"
    owner=${owner//\"/}
    [[ -n "$owner" ]] || return 1
    pid_reply=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus GetConnectionUnixProcessID s "$owner" 2>/dev/null || true)
    read -r _ pid <<<"$pid_reply"
    [[ "$pid" =~ ^[1-9][0-9]*$ ]] || return 1
    printf '%s\n' "$pid"
}

service_fact() {
    systemctl --user show qe-shell.service -p "$1" --value 2>/dev/null
}

process_matches_session() {
    local pid=$1 proc_root=${QE_ACTIVATION_PROC_ROOT:-/proc} key value found
    [[ -r "$proc_root/$pid/environ" ]] || return 1
    for key in WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP; do
        value=${!key}
        found=$(tr '\0' '\n' <"$proc_root/$pid/environ" | grep -Fx -- "$key=$value" || true)
        [[ -n "$found" ]] || return 1
    done
}

no_competing_processes() {
    local name pid
    for name in dunst waybar hyprlock; do
        while IFS= read -r pid; do
            [[ -z "$pid" ]] && continue
            if process_matches_session "$pid"; then
                return 1
            fi
        done < <(pgrep -u "$(id -u)" -x "$name" 2>/dev/null || true)
    done
}

readiness_observation() {
    local invocation=$1 pid=$2 current_invocation current_pid instances instance_match notification_pid watcher_pid
    current_invocation=$(service_fact InvocationID)
    current_pid=$(service_fact MainPID)
    [[ "$current_invocation" == "$invocation" && "$current_pid" == "$pid" ]] || return 1
    [[ "$pid" =~ ^[1-9][0-9]*$ ]] || return 1
    process_matches_session "$pid" || return 1
    instances=$(qs list --all --json 2>/dev/null) || return 1
    instance_match=$(jq -r --arg path "$project_root/shell.qml" --argjson pid "$pid" \
        '([.[] | select(.config_path == $path)] | length) == 1
         and ([.[] | select(.config_path == $path and .pid == $pid)] | length) == 1' \
        <<<"$instances" 2>/dev/null) || return 1
    [[ "$instance_match" == true ]] || return 1
    notification_pid=$(bus_owner_pid org.freedesktop.Notifications || true)
    watcher_pid=$(bus_owner_pid org.kde.StatusNotifierWatcher || true)
    [[ "$notification_pid" == "$pid" && "$watcher_pid" == "$pid" ]] || return 1
    no_competing_processes || return 1
    journalctl --user -u qe-shell.service "_SYSTEMD_INVOCATION_ID=$invocation" \
        --grep 'Configuration Loaded' -n 1 --no-pager 2>/dev/null | grep -Fq 'Configuration Loaded' || return 1
    current_invocation=$(service_fact InvocationID)
    current_pid=$(service_fact MainPID)
    [[ "$current_invocation" == "$invocation" && "$current_pid" == "$pid" ]]
}

service_start_activation() {
    local variable runtime_uid socket dunst_pid owner_pid invocation pid
    local attempts=${QE_ACTIVATION_POLL_ATTEMPTS:-60}
    local poll_seconds=${QE_ACTIVATION_POLL_SECONDS:-0.5}
    local guard_seconds=${QE_ACTIVATION_GUARD_SECONDS:-10}
    for variable in XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP; do
        [[ -n "${!variable:-}" ]] || { activation_fail missing-environment "$variable is unavailable."; return 1; }
    done
    [[ -d "$XDG_RUNTIME_DIR" ]] || { activation_fail invalid-runtime 'XDG_RUNTIME_DIR is not a directory.'; return 1; }
    runtime_uid=$(stat -c %u -- "$XDG_RUNTIME_DIR" 2>/dev/null || true)
    [[ "$runtime_uid" == "$(id -u)" ]] || { activation_fail invalid-runtime 'XDG_RUNTIME_DIR is not owned by the effective user.'; return 1; }
    busctl --user list --no-pager >/dev/null 2>&1 || { activation_fail user-bus-unavailable 'the session DBus is unreachable.'; return 1; }
    systemctl --user show-environment >/dev/null 2>&1 || { activation_fail user-manager-unavailable 'the systemd user manager is unreachable.'; return 1; }
    socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock"
    [[ -S "$socket" || ( "${QE_ACTIVATION_ALLOW_REGULAR_SOCKET_FIXTURE:-0}" == 1 && -e "$socket" && "${QE_ACTIVATION_PROC_ROOT:-}" != "" ) ]] \
        || { activation_fail invalid-hyprland-session 'the current-user Hyprland socket is unavailable.'; return 1; }
    timeout 3 hyprctl -j monitors >/dev/null 2>&1 || { activation_fail hyprland-ipc-failed 'the Hyprland IPC probe failed.'; return 1; }
    command -v jq >/dev/null 2>&1 || { activation_fail missing-capability 'jq is unavailable.'; return 1; }

    dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP \
        || { activation_fail environment-import-failed 'the session environment import failed.'; return 1; }
    systemctl --user daemon-reload || { activation_fail daemon-reload-failed 'the systemd user daemon reload failed.'; return 1; }
    for unit in pipewire.socket pipewire-pulse.socket wireplumber.service; do
        systemctl --user is-enabled --quiet "$unit" || {
            activation_fail user-unit-disabled "$unit is disabled. Run: systemctl --user enable --now $unit"
            return 1
        }
    done

    owner_pid=$(bus_owner_pid org.freedesktop.Notifications || true)
    if systemctl --user is-active --quiet dunst.service; then
        dunst_pid=$(systemctl --user show dunst.service -p MainPID --value 2>/dev/null || true)
        [[ "$dunst_pid" =~ ^[1-9][0-9]*$ && "$owner_pid" == "$dunst_pid" ]] \
            || { activation_fail unknown-notification-owner 'Dunst is active but does not own notifications through its supervised PID.'; return 1; }
        systemctl --user stop dunst.service || { activation_fail dunst-stop-failed 'systemd could not stop dunst.service.'; return 1; }
        for ((i = 0; i < attempts; i++)); do
            owner_pid=$(bus_owner_pid org.freedesktop.Notifications || true)
            [[ -z "$owner_pid" ]] && break
            sleep "$poll_seconds"
        done
        [[ -z "$owner_pid" ]] || { activation_fail dunst-owner-timeout 'Dunst did not release notification ownership.'; return 1; }
    elif [[ -n "$owner_pid" ]]; then
        pid=$(service_fact MainPID)
        if [[ "$owner_pid" != "$pid" || ! "$pid" =~ ^[1-9][0-9]*$ ]]; then
            activation_fail unknown-notification-owner "notifications are owned by unmanaged PID $owner_pid."
            return 1
        fi
    fi

    systemctl --user restart qe-shell.service || { activation_fail service-restart-failed 'qe-shell.service did not restart.'; return 1; }
    for ((i = 0; i < attempts; i++)); do
        invocation=$(service_fact InvocationID)
        pid=$(service_fact MainPID)
        if [[ -n "$invocation" ]] && readiness_observation "$invocation" "$pid"; then
            sleep "$guard_seconds"
            if readiness_observation "$invocation" "$pid"; then
                qe_write_installation_receipt ready "$project_root"
                printf '%s\n' 'QE activation ready.' >&2
                return 0
            fi
            activation_fail readiness-lost 'QE changed or lost readiness during the immediate-crash guard.'
            return 1
        fi
        sleep "$poll_seconds"
    done
    activation_fail readiness-timeout 'QE did not reach correlated service, singleton, DBus, journal, and session readiness.'
}

if ((service_start)); then
    if ((restart || detach)); then
        printf '%s\n' 'QE service start failed: --service-start cannot be combined with other options.' >&2
        exit 2
    fi
    service_start_activation
    exit
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
