#!/usr/bin/env bash
set -euo pipefail

script_path=$(readlink -f -- "${BASH_SOURCE[0]}")
script_dir=$(cd -- "$(dirname -- "$script_path")" && pwd -P)
project_root=${QE_INSTALL_PROJECT_ROOT:-$(cd -- "$script_dir/../.." && pwd -P)}
# shellcheck disable=SC1090,SC1091 # project_root is resolved before sourcing.
source "$project_root/scripts/lib/qe-installation.sh"

usage() {
    printf 'Usage: %s <check|protocol-version|package-query|install|activate> [options]\n' "$project_root/install.sh" >&2
    exit 2
}

[[ $# -ge 1 ]] || usage
command_name=$1
shift
case "$command_name" in
    check|protocol-version|package-query|install|activate) ;;
    *) usage ;;
esac

if [[ $EUID -eq 0 && "${QE_INSTALL_TEST_MODE:-}" != 1 ]]; then
    printf '%s\n' 'QE installation must run as the target user, not root.' >&2
    exit 1
fi

if [[ "$command_name" == protocol-version ]]; then
    [[ $# -eq 0 ]] || usage
    printf '1\n'
    exit 0
fi

package_file="$project_root/scripts/install/packages.txt"
read_packages() {
    [[ -r "$package_file" ]] || {
        printf 'QE package inventory is unreadable: %s\n' "$package_file" >&2
        return 1
    }
    while IFS= read -r package; do
        [[ -z "$package" || "$package" == \#* ]] && continue
        [[ "$package" =~ ^[a-z0-9][a-z0-9@._+-]*$ ]] || {
            printf 'QE package inventory contains an invalid name: %s\n' "$package" >&2
            return 1
        }
        printf '%s\n' "$package"
    done <"$package_file"
}

package_query() {
    local package inventory installed
    if [[ -n "${QE_INSTALL_PACKAGE_DB:-}" ]]; then
        [[ -r "$QE_INSTALL_PACKAGE_DB" ]] || {
            printf '%s\n' 'QE package query could not read the package database.' >&2
            return 1
        }
        installed=$(<"$QE_INSTALL_PACKAGE_DB")
    else
        installed=$(pacman -Qq 2>/dev/null) || {
            printf '%s\n' 'QE package query could not read the complete Pacman database.' >&2
            return 1
        }
    fi
    inventory=$(read_packages) || return
    while IFS= read -r package; do
        grep -Fxq -- "$package" <<<"$installed" || printf '%s\n' "$package"
    done <<<"$inventory"
}

if [[ "$command_name" == package-query ]]; then
    [[ $# -eq 0 ]] || usage
    package_query
    exit
fi

expected_home=$(getent passwd "$(id -u)" | cut -d: -f6)
validate_paths() {
    [[ -n "$HOME" && "$HOME" == /* && ( "${QE_INSTALL_TEST_MODE:-}" == 1 || "$HOME" == "$expected_home" ) ]] || {
        printf 'QE installation rejected HOME=%s for the effective user.\n' "${HOME:-}" >&2
        return 1
    }
    local expected_checkout="$HOME/Projects/quickshell"
    [[ "${QE_INSTALL_TEST_MODE:-}" == 1 || "$project_root" == "$expected_checkout" ]] || {
        printf 'QE production checkout must be %s (found %s).\n' "$expected_checkout" "$project_root" >&2
        return 1
    }
    if [[ "${QE_INSTALL_TEST_MODE:-}" != 1 ]]; then
        [[ "${XDG_CONFIG_HOME:-$HOME/.config}" == "$HOME/.config" \
            && "${XDG_DATA_HOME:-$HOME/.local/share}" == "$HOME/.local/share" \
            && "${XDG_STATE_HOME:-$HOME/.local/state}" == "$HOME/.local/state" \
            && "${XDG_CACHE_HOME:-$HOME/.cache}" == "$HOME/.cache" ]] || {
            printf '%s\n' 'QE production installation requires conventional XDG roots.' >&2
            return 1
        }
    fi
}

config_home=${XDG_CONFIG_HOME:-$HOME/.config}
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
user_bin="$HOME/.local/bin"
unit_dir="$config_home/systemd/user"
desktop_dir="$data_home/applications"

validate_parents() {
    local parent
    for parent in "$HOME/.local" "$user_bin" "$config_home/systemd" "$unit_dir" "$desktop_dir"; do
        if [[ -L "$parent" ]]; then
            printf 'QE managed parent is a symlink: %s. Complete the coordinated Stow --no-folding migration first.\n' "$parent" >&2
            return 1
        fi
    done
}

validate_sources() {
    local relative
    for relative in scripts/run-qe.sh scripts/run-qe-lock.sh scripts/qe-action.sh \
        scripts/qe-launch.sh scripts/qe-defaults scripts/qe-doctor \
        scripts/qe-hyprshot.sh scripts/qe-theme-switcher; do
        [[ -x "$project_root/$relative" ]] || {
            printf 'QE command source is missing or not executable: %s\n' "$project_root/$relative" >&2
            return 1
        }
    done
}

validate_artifacts() {
    local image theme
    jq -e . "$project_root/defaults/manifest.json" >/dev/null
    for theme in "$project_root"/themes/*.json "$project_root/defaults/wallpaper/generated-theme/qe/Wallpaper.json"; do
        jq -e . "$theme" >/dev/null || {
            printf 'QE authored/default JSON is invalid: %s\n' "$theme" >&2
            return 1
        }
    done
    for image in "$project_root"/defaults/wallpaper/images/*; do
        file --brief --mime-type "$image" | grep -q '^image/' || {
            printf 'QE default image is invalid: %s\n' "$image" >&2
            return 1
        }
    done
}

validate_old_owner_relinquished() {
    local path name
    for name in qe-shell qe-lock qe-action qe-launch qe-defaults qe-doctor qe-hyprshot qe-theme-switcher qe-project; do
        path="$HOME/dotfiles/scripts/.local/bin/$name"
        [[ ! -e "$path" && ! -L "$path" ]] || {
            printf 'QE deployment is still declared by the dotfiles checkout: %s. Update dotfiles and complete the coordinated restow first.\n' "$path" >&2
            return 1
        }
    done
    for path in \
        "$HOME/dotfiles/_hyprland/systemd/.config/systemd/user/qe-shell.service" \
        "$HOME/dotfiles/_hyprland/applications/.local/share/applications/qe-theme-selector.desktop" \
        "$HOME/dotfiles/_hyprland/applications/.local/share/applications/qe-wallpaper-selector.desktop" \
        "$HOME/dotfiles/_hyprland/applications/.local/share/applications/qe-palette-viewer.desktop"; do
        [[ ! -e "$path" && ! -L "$path" ]] || {
            printf 'QE deployment is still declared by the dotfiles checkout: %s. Update dotfiles and complete the coordinated restow first.\n' "$path" >&2
            return 1
        }
    done
    for path in \
        "$HOME/dotfiles/bat/.config/bat/themes/wallpaper.tmTheme" \
        "$HOME/dotfiles/btop/.config/btop/themes/wallpaper.theme" \
        "$HOME/dotfiles/eza/.config/eza/themes/wallpaper.yml" \
        "$HOME/dotfiles/zsh/.config/zsh/fzf_themes/wallpaper.zsh" \
        "$HOME/dotfiles/_hyprland/hypr/.config/hypr/themes/hyprland/wallpaper.lua" \
        "$HOME/dotfiles/_hyprland/imv/.config/imv/themes/wallpaper.conf" \
        "$HOME/dotfiles/kitty/.config/kitty/themes/wallpaper.conf" \
        "$HOME/dotfiles/mpv/.config/mpv/themes/wallpaper.conf" \
        "$HOME/dotfiles/opencode/.config/opencode/themes/wallpaper.json" \
        "$HOME/dotfiles/_hyprland/rofi/.config/rofi/themes/colorschemes/wallpaper.rasi" \
        "$HOME/dotfiles/starship/.config/starship/themes/wallpaper.sh" \
        "$HOME/dotfiles/tmux/.config/tmux/themes/wallpaper.conf" \
        "$HOME/dotfiles/yazi/.config/yazi/flavors/wallpaper.yazi/wallpaper.sh" \
        "$HOME/dotfiles/yazi/.config/yazi/flavors/wallpaper.yazi/tmtheme.xml"; do
        [[ ! -e "$path" && ! -L "$path" ]] || {
            printf 'QE generated asset is still declared inside dotfiles: %s. Complete the coordinated cutover first.\n' "$path" >&2
            return 1
        }
    done
}

is_legacy_wrapper() {
    local name=$1 destination=$2 expected status=1
    expected=$(mktemp)
    # shellcheck disable=SC2016 # These variables belong to the frozen wrapper.
    printf '#!/usr/bin/env bash\nset -euo pipefail\n\nexec "$HOME/.local/bin/qe-project" %s "$@"\n' "$name" >"$expected"
    cmp -s -- "$expected" "$destination" && status=0
    rm -f -- "$expected"
    return "$status"
}

is_legacy_desktop() {
    local name=$1 destination=$2 label comment target icon expected status=1
    case "$name" in
        qe-theme-selector.desktop)
            label='QE Theme Selector'; comment='Open the QE theme selector.'; target='qe-theme open'; icon='/usr/share/icons/breeze-dark/preferences/32/preferences-desktop-theme-global.svg' ;;
        qe-wallpaper-selector.desktop)
            label='QE Wallpaper Selector'; comment='Open the QE wallpaper selector.'; target='qe-wallpaper open'; icon='/usr/share/icons/breeze-dark/preferences/32/preferences-desktop-wallpaper.svg' ;;
        qe-palette-viewer.desktop)
            label='QE Palette Viewer'; comment='View the current QE color palette.'; target='qe-palette open'; icon='/usr/share/icons/breeze-dark/preferences/32/preferences-desktop-color.svg' ;;
        *) return 1 ;;
    esac
    expected=$(mktemp)
    printf '[Desktop Entry]\nName=%s\nComment=%s\nExec=%s/scripts/qe-launch.sh %s\nTerminal=false\nType=Application\nIcon=%s\nCategories=Settings;\nNoDisplay=false\n' \
        "$label" "$comment" "$project_root" "$target" "$icon" >"$expected"
    cmp -s -- "$expected" "$destination" && status=0
    rm -f -- "$expected"
    return "$status"
}

validate_destinations() {
    local name relative destination source asset
    local names=(qe-shell qe-lock qe-action qe-launch qe-defaults qe-doctor qe-hyprshot qe-theme-switcher)
    local relatives=(scripts/run-qe.sh scripts/run-qe-lock.sh scripts/qe-action.sh scripts/qe-launch.sh scripts/qe-defaults scripts/qe-doctor scripts/qe-hyprshot.sh scripts/qe-theme-switcher)
    for index in "${!names[@]}"; do
        name=${names[$index]}
        relative=${relatives[$index]}
        destination="$user_bin/$name"
        source="$project_root/$relative"
        [[ ! -e "$destination" && ! -L "$destination" ]] && continue
        [[ -L "$destination" && "$(readlink -f -- "$destination")" == "$source" ]] && continue
        is_legacy_wrapper "$name" "$destination" && continue
        printf 'QE refuses unknown or user-owned command destination: %s\n' "$destination" >&2
        return 1
    done
    for asset in qe-shell.service qe-theme-selector.desktop qe-wallpaper-selector.desktop qe-palette-viewer.desktop; do
        if [[ "$asset" == qe-shell.service ]]; then destination="$unit_dir/$asset"; else destination="$desktop_dir/$asset"; fi
        [[ ! -e "$destination" && ! -L "$destination" ]] && continue
        [[ -f "$destination" && ! -L "$destination" ]] \
            && cmp -s -- "$project_root/install/assets/$asset" "$destination" && continue
        [[ "$asset" != qe-shell.service ]] && is_legacy_desktop "$asset" "$destination" && continue
        printf 'QE refuses unknown or user-owned asset destination: %s\n' "$destination" >&2
        return 1
    done
    destination="$unit_dir/dunst.service"
    if [[ -e "$destination" || -L "$destination" ]]; then
        [[ -L "$destination" && "$(readlink -f -- "$destination")" == /dev/null ]] || {
            printf 'QE refuses unknown Dunst unit destination: %s\n' "$destination" >&2
            return 1
        }
    fi
    destination="$user_bin/qe-project"
    if [[ -e "$destination" || -L "$destination" ]]; then
        cmp -s -- "$project_root/install/legacy/qe-project" "$destination" || {
            printf 'QE refuses unknown legacy dispatcher destination: %s\n' "$destination" >&2
            return 1
        }
    fi
}

check_host_hooks() {
    local hypr_root="$config_home/hypr" entry autostart idle paper current module candidate
    local -a queue
    local -A visited
    entry="$hypr_root/hyprland.lua"
    [[ -r "$entry" ]] || {
        printf 'QE requires an active Hyprland Lua entry at %s loading autostart.lua.\n' "$entry" >&2
        return 1
    }
    grep -Eq "require\\([\"']autostart[\"']\\)" "$entry" || {
        printf 'QE could not verify that %s loads autostart.lua.\n' "$entry" >&2
        return 1
    }
    autostart="$hypr_root/autostart.lua"
    idle="$hypr_root/hypridle.conf"
    paper="$hypr_root/hyprpaper.conf"
    queue=("$entry")
    while ((${#queue[@]})); do
        current=${queue[0]}
        queue=("${queue[@]:1}")
        [[ -n "${visited[$current]+present}" ]] && continue
        visited[$current]=1
        luac -p "$current" >/dev/null 2>&1 || {
            printf 'QE rejected loaded Hyprland Lua syntax: %s\n' "$current" >&2
            return 1
        }
        if grep -Eiq 'exec_cmd\([^)]*(dunst|waybar|hyprlock)' "$current"; then
            printf 'QE rejects a loaded Dunst, Waybar, or Hyprlock startup hook: %s\n' "$current" >&2
            return 1
        fi
        while IFS= read -r module; do
            module=${module#*\(}
            module=${module//[\"\047\)]/}
            candidate="$hypr_root/${module//./\/}.lua"
            [[ -r "$candidate" ]] && queue+=("$candidate")
        done < <(grep -Eo "require\\([\"'][A-Za-z0-9_.-]+[\"']\\)" "$current" || true)
    done
    if ! grep -Fq 'hyprpaper' "$autostart" || ! grep -Fq 'hypridle' "$autostart" \
        || ! grep -Fq 'qe-shell --service-start' "$autostart"; then
        printf '%s\n' 'QE requires active Hyprpaper, Hypridle, and qe-shell --service-start autostart hooks.' >&2
        return 1
    fi
    if [[ ! -r "$idle" ]] || ! grep -Eq 'lock_cmd[[:space:]]*=[[:space:]]*([^#[:space:]]*/)?qe-lock([[:space:]#]|$)' "$idle"; then
        printf 'QE requires Hypridle lock routing through qe-lock in %s.\n' "$idle" >&2
        return 1
    fi
    if [[ ! -r "$paper" ]] || ! grep -Fq 'current_wallpaper.png' "$paper"; then
        printf 'QE requires Hyprpaper to consume the managed current_wallpaper.png in %s.\n' "$paper" >&2
        return 1
    fi
}

check_packages_complete() {
    local missing
    missing=$(package_query) || return
    [[ -z "$missing" ]] || {
        printf 'QE required packages are missing:\n%s\nRun %s install --packages.\n' "$missing" "$project_root/install.sh" >&2
        return 1
    }
}

version_ge() {
    [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | sed -n '1p')" == "$2" ]]
}

check_capabilities() {
    local executable version hyprland_version family unit
    local required_commands=(bash busctl cmp dbus-update-activation-environment file flock hyprctl hyprpaper hypridle hyprshot jq magick pgrep python3 qs quickshell systemctl timeout xdg-open)
    for executable in "${required_commands[@]}"; do
        command -v "$executable" >/dev/null 2>&1 || {
            printf 'QE required capability is unavailable: command %s\n' "$executable" >&2
            return 1
        }
    done
    python3 -c 'import dbus; from gi.repository import GLib' >/dev/null 2>&1 || {
        printf '%s\n' 'QE Python DBus/GObject imports are unavailable.' >&2
        return 1
    }
    [[ -r /etc/pam.d/login ]] || { printf '%s\n' 'QE requires readable /etc/pam.d/login.' >&2; return 1; }
    [[ -r /usr/share/dbus-1/system-services/org.freedesktop.UPower.service ]] || {
        printf '%s\n' 'QE requires UPower system-bus activation metadata.' >&2
        return 1
    }
    for family in Inter Roboto 'JetBrainsMono Nerd Font' 'Material Symbols Rounded'; do
        fc-match -f '%{family}\n' "$family" | grep -Fqi -- "$family" || {
            printf 'QE configured font family is unavailable: %s\n' "$family" >&2
            return 1
        }
    done
    version=$(quickshell --version 2>&1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | sed -n '1p')
    [[ -n "$version" ]] || { printf '%s\n' 'QE could not determine the Quickshell version.' >&2; return 1; }
    version_ge "$version" 0.3.1 || { printf 'QE requires Quickshell 0.3.1 or newer (found %s).\n' "$version" >&2; return 1; }
    if [[ "$version" != 0.3.1 ]]; then
        printf 'Warning: Quickshell %s is newer than the validated 0.3.1 baseline; capability probes passed.\n' "$version" >&2
    fi
    hyprland_version=$(hyprctl version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | sed -n '1p' || true)
    if [[ -n "$hyprland_version" && "$hyprland_version" != 0.56.2 ]]; then
        printf 'Warning: Hyprland %s differs from the validated 0.56.2 baseline; no unsupported minimum is enforced.\n' "$hyprland_version" >&2
    fi
    local probe_root probe_status=0
    probe_root=$(mktemp -d)
    mkdir -m 0700 -- "$probe_root/runtime"
    XDG_CONFIG_HOME="$probe_root/config" XDG_DATA_HOME="$probe_root/data" \
        XDG_STATE_HOME="$probe_root/state" XDG_CACHE_HOME="$probe_root/cache" \
        XDG_RUNTIME_DIR="$probe_root/runtime" \
        timeout 5 quickshell -p "$project_root/install/qml/capability-probe.qml" \
        >/dev/null 2>"$probe_root/probe.log" || probe_status=$?
    if [[ $probe_status -ne 0 && $probe_status -ne 124 ]]; then
        printf 'QE required QML/API probe failed: ' >&2
        dd if="$probe_root/probe.log" bs=1 count=2048 status=none >&2 || true
        printf '\n' >&2
        rm -rf -- "$probe_root"
        return 1
    fi
    if ! grep -Fq QE_INSTALL_CAPABILITY_PROBE_PASSED "$probe_root/probe.log"; then
        printf '%s\n' 'QE required QML/API probe did not complete.' >&2
        rm -rf -- "$probe_root"
        return 1
    fi
    rm -rf -- "$probe_root"
    for unit in NetworkManager.service bluetooth.service; do
        systemctl is-enabled --quiet "$unit" || {
            printf 'QE requires enabled %s. Run: sudo systemctl enable --now %s\n' "$unit" "$unit" >&2
            return 1
        }
    done
    for unit in pipewire.socket pipewire-pulse.socket wireplumber.service; do
        systemctl --user cat "$unit" >/dev/null 2>&1 || {
            printf 'QE required user unit is unavailable: %s\n' "$unit" >&2
            return 1
        }
    done
    for executable in qe-theme-switcher rofi rofi_power_menu blueman-manager nm-connection-editor pavucontrol thunar powerprofilesctl; do
        command -v "$executable" >/dev/null 2>&1 \
            || printf 'Warning: optional QE integration is unavailable: %s\n' "$executable" >&2
    done
}

preflight_static() {
    validate_paths
    validate_parents
    validate_sources
    validate_old_owner_relinquished
    validate_destinations
}

preflight() {
    preflight_static
    if [[ "${QE_INSTALL_TEST_MODE:-}" != 1 ]]; then
        check_packages_complete
        check_capabilities
        validate_artifacts
        check_host_hooks
    elif [[ "${QE_INSTALL_TEST_CAPABILITIES:-}" == 1 ]]; then
        check_capabilities
        validate_artifacts
        check_host_hooks
    else
        validate_artifacts
    fi
}

if [[ "$command_name" == check ]]; then
    [[ $# -eq 0 ]] || usage
    preflight
    printf '%s\n' 'QE installation check passed.' >&2
    exit 0
fi

if [[ "$command_name" == activate ]]; then
    [[ $# -eq 0 ]] || usage
    exec "$project_root/scripts/run-qe.sh" --service-start
fi

install_packages=0
non_interactive=0
authorized=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --packages) install_packages=1 ;;
        --non-interactive) non_interactive=1 ;;
        --authorize-dunst-cutover) authorized=1 ;;
        *) usage ;;
    esac
    shift
done

if ((install_packages)); then
    preflight_static
    missing_output=$(package_query) || exit 1
    mapfile -t missing_packages <<<"$missing_output"
    [[ -n "$missing_output" ]] || missing_packages=()
    if ((${#missing_packages[@]})); then
        sudo_args=()
        ((non_interactive)) && sudo_args+=(-n)
        sudo "${sudo_args[@]}" pacman -S --needed --noconfirm -- "${missing_packages[@]}" || {
            printf '%s\n' 'QE package installation failed.' >&2
            exit 1
        }
    fi
fi

preflight
if ((!authorized)); then
    if ((non_interactive)) || [[ ! -t 0 ]]; then
        printf '%s\n' 'QE installation requires --authorize-dunst-cutover to persistently mask Dunst.' >&2
        exit 1
    fi
    read -r -p 'QE will persistently mask Dunst. Continue? [y/N] ' answer
    [[ "$answer" == y || "$answer" == Y || "$answer" == yes || "$answer" == YES ]] || exit 1
fi

qe_acquire_install_lock
mkdir -p -- "$user_bin" "$unit_dir" "$desktop_dir"

install_link() {
    local name=$1 relative=$2 destination source temporary
    destination="$user_bin/$name"
    source="$project_root/$relative"
    if [[ -L "$destination" && "$(readlink -f -- "$destination")" == "$source" ]]; then
        return
    fi
    if [[ -e "$destination" || -L "$destination" ]]; then
        if is_legacy_wrapper "$name" "$destination"; then
            rm -f -- "$destination"
        else
            printf 'QE refuses unknown or user-owned command destination: %s\n' "$destination" >&2
            return 1
        fi
    fi
    temporary="$user_bin/.${name}.qe-install.$$"
    ln -s -- "$source" "$temporary"
    mv -Tf -- "$temporary" "$destination"
}

install_asset() {
    local name=$1 destination=$2 source temporary
    source="$project_root/install/assets/$name"
    if [[ -f "$destination" && ! -L "$destination" ]] && cmp -s -- "$source" "$destination"; then
        return
    fi
    if [[ -e "$destination" || -L "$destination" ]]; then
        printf 'QE refuses unknown or user-owned asset destination: %s\n' "$destination" >&2
        return 1
    fi
    temporary="$(dirname -- "$destination")/.${name}.qe-install.$$"
    install -m 0644 -- "$source" "$temporary"
    mv -Tf -- "$temporary" "$destination"
}

adopt_legacy_desktop() {
    local name=$1 destination="$desktop_dir/$1"
    [[ -e "$destination" || -L "$destination" ]] || return 0
    if is_legacy_desktop "$name" "$destination"; then
        rm -f -- "$destination"
    fi
}

install_link qe-shell scripts/run-qe.sh
install_link qe-lock scripts/run-qe-lock.sh
install_link qe-action scripts/qe-action.sh
install_link qe-launch scripts/qe-launch.sh
install_link qe-defaults scripts/qe-defaults
install_link qe-doctor scripts/qe-doctor
install_link qe-hyprshot scripts/qe-hyprshot.sh
install_link qe-theme-switcher scripts/qe-theme-switcher
install_asset qe-shell.service "$unit_dir/qe-shell.service"
adopt_legacy_desktop qe-theme-selector.desktop
adopt_legacy_desktop qe-wallpaper-selector.desktop
adopt_legacy_desktop qe-palette-viewer.desktop
install_asset qe-theme-selector.desktop "$desktop_dir/qe-theme-selector.desktop"
install_asset qe-wallpaper-selector.desktop "$desktop_dir/qe-wallpaper-selector.desktop"
install_asset qe-palette-viewer.desktop "$desktop_dir/qe-palette-viewer.desktop"

legacy_dispatcher="$user_bin/qe-project"
if [[ -e "$legacy_dispatcher" || -L "$legacy_dispatcher" ]]; then
    if cmp -s -- "$project_root/install/legacy/qe-project" "$legacy_dispatcher"; then
        rm -f -- "$legacy_dispatcher"
    else
        printf 'QE refuses unknown legacy dispatcher destination: %s\n' "$legacy_dispatcher" >&2
        exit 1
    fi
fi

"$project_root/scripts/qe-defaults" seed

mask="$unit_dir/dunst.service"
[[ "$(<"$project_root/install/assets/dunst.service.mask")" == /dev/null ]] || {
    printf '%s\n' 'QE Dunst mask asset is invalid.' >&2
    exit 1
}
if [[ -L "$mask" && "$(readlink -f -- "$mask")" == /dev/null ]]; then
    :
elif [[ -e "$mask" || -L "$mask" ]]; then
    printf 'QE refuses unknown Dunst unit destination: %s\n' "$mask" >&2
    exit 1
else
    temporary="$unit_dir/.dunst.service.qe-install.$$"
    ln -s -- /dev/null "$temporary"
    mv -Tf -- "$temporary" "$mask"
fi

if [[ -z "${XDG_RUNTIME_DIR:-}" || -z "${DBUS_SESSION_BUS_ADDRESS:-}" \
    || -z "${WAYLAND_DISPLAY:-}" || -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    qe_write_installation_receipt activation-deferred "$project_root"
    printf '%s\n' 'QE static deployment complete; activation deferred.' >&2
    printf '%s\n' 'From the current Hyprland session run: qe-shell --service-start' >&2
    exit 0
fi

exec "$project_root/scripts/run-qe.sh" --service-start
