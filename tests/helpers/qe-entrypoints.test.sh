#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
home="$test_root/home"
mkdir -p -- "$home/Projects"
ln -s -- "$project_root" "$home/Projects/quickshell"
: >"$test_root/packages"

env -u XDG_RUNTIME_DIR -u DBUS_SESSION_BUS_ADDRESS -u WAYLAND_DISPLAY \
    -u HYPRLAND_INSTANCE_SIGNATURE HOME="$home" USER=test LOGNAME=test \
    XDG_CONFIG_HOME="$home/.config" XDG_DATA_HOME="$home/.local/share" \
    XDG_STATE_HOME="$home/.local/state" XDG_CACHE_HOME="$home/.cache" \
    ZSH_CONFIG_HOME="$home/.config/zsh" QE_INSTALL_TEST_MODE=1 \
    QE_INSTALL_PACKAGE_DB="$test_root/packages" \
    "$project_root/install.sh" install --non-interactive --authorize-dunst-cutover \
    >/dev/null 2>&1

entry_points=(qe-action qe-defaults qe-doctor qe-hyprshot qe-launch qe-lock qe-shell qe-theme-switcher)
targets=(qe-action.sh qe-defaults qe-doctor qe-hyprshot.sh qe-launch.sh run-qe-lock.sh run-qe.sh qe-theme-switcher)
for index in "${!entry_points[@]}"; do
    destination="$home/.local/bin/${entry_points[$index]}"
    expected="$project_root/scripts/${targets[$index]}"
    [[ -L "$destination" && "$(readlink -f -- "$destination")" == "$expected" ]]
done
[[ ! -e "$home/.local/bin/qe-project" ]]

printf '%s\n' 'QE_ENTRYPOINTS_TEST_PASSED'
