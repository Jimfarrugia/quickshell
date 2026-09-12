#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

home="$test_root/home"
bin="$test_root/bin"
mkdir -p -- "$home/Projects" "$bin"
ln -s -- "$project_root" "$home/Projects/quickshell"

run_install() {
    env -u XDG_RUNTIME_DIR -u DBUS_SESSION_BUS_ADDRESS -u WAYLAND_DISPLAY \
    -u HYPRLAND_INSTANCE_SIGNATURE HOME="$home" USER=test LOGNAME=test \
    XDG_CONFIG_HOME="$home/.config" XDG_DATA_HOME="$home/.local/share" \
    XDG_STATE_HOME="$home/.local/state" XDG_CACHE_HOME="$home/.cache" \
    ZSH_CONFIG_HOME="$home/.config/zsh" \
    QE_INSTALL_TEST_MODE=1 QE_INSTALL_PACKAGE_DB="${QE_INSTALL_PACKAGE_DB:-$test_root/packages}" \
    PATH="$bin:/usr/bin" "$project_root/install.sh" "$@"
}

stdout="$test_root/stdout"
stderr="$test_root/stderr"
run_install protocol-version >"$stdout" 2>"$stderr"
[[ "$(<"$stdout")" == 1 ]]
[[ $(wc -c <"$stdout") -eq 2 ]]
[[ ! -e "$home/.local/state/qe" ]]

printf '%s\n' quickshell bash >"$test_root/packages"
run_install package-query >"$stdout" 2>"$stderr"
grep -Fxq hyprland "$stdout"
if grep -Ev '^[a-z0-9][a-z0-9@._+-]*$' "$stdout"; then
    printf '%s\n' 'package-query emitted malformed output' >&2
    exit 1
fi

if QE_INSTALL_PACKAGE_DB="$test_root/missing-db" run_install package-query \
        >"$stdout" 2>"$stderr"; then
    printf '%s\n' 'package-query accepted an unreadable package database' >&2
    exit 1
fi
[[ ! -s "$stdout" ]]

# Compatibility is checked through the public check seam with isolated command
# and Hyprland-policy fixtures.
cap_home="$test_root/cap-home"
cap_bin="$test_root/cap-bin"
cap_units="$test_root/cap-units"
mkdir -p -- "$cap_home/.config/hypr" "$cap_bin" "$cap_units"
touch "$cap_units/pipewire.socket" "$cap_units/pipewire-pulse.socket" \
    "$cap_units/wireplumber.service"
cat >"$cap_home/.config/hypr/hyprland.lua" <<'EOF'
require("autostart")
EOF
cat >"$cap_home/.config/hypr/autostart.lua" <<'EOF'
hl.exec_cmd("hyprpaper")
hl.exec_cmd("hypridle")
hl.exec_cmd("qe-shell --service-start")
EOF
printf '%s\n' 'general { lock_cmd = qe-lock }' >"$cap_home/.config/hypr/hypridle.conf"
# shellcheck disable=SC2016 # Literal Hyprpaper variable for the fixture.
printf '%s\n' 'path = $HOME/.local/share/current_wallpaper.png' >"$cap_home/.config/hypr/hyprpaper.conf"
cat >"$cap_bin/systemctl" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" != --user ]] || exit 1
exit 0
EOF
cat >"$cap_bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'Hyprland 0.56.2'
EOF
cat >"$cap_bin/quickshell" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == --version ]]; then printf 'Quickshell %s\n' "${QE_TEST_QS_VERSION:-0.3.1}"; exit 0; fi
if [[ "${QE_TEST_QML_BROKEN:-0}" == 1 ]]; then exit 1; fi
[[ "${QT_QPA_PLATFORM:-}" == offscreen && -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]] || exit 1
printf '%s\n' 'QE_INSTALL_CAPABILITY_PROBE_PASSED'
exit 0
EOF
chmod +x "$cap_bin"/*
run_capability_check() {
    HOME="$cap_home" USER=test LOGNAME=test DISPLAY=:99 WAYLAND_DISPLAY=stale-wayland \
    XDG_CONFIG_HOME="$cap_home/.config" XDG_DATA_HOME="$cap_home/.local/share" \
    XDG_STATE_HOME="$cap_home/.local/state" XDG_CACHE_HOME="$cap_home/.cache" \
    QE_INSTALL_TEST_MODE=1 QE_INSTALL_TEST_CAPABILITIES=1 \
    QE_INSTALL_TEST_USER_UNIT_DIR="$cap_units" \
    PATH="$cap_bin:/usr/bin" "$project_root/install.sh" check
}
if QE_TEST_QS_VERSION=0.3.0 run_capability_check >"$stdout" 2>"$stderr"; then
    printf '%s\n' 'compatibility check accepted old Quickshell' >&2
    exit 1
fi
grep -Fq 'requires Quickshell 0.3.1 or newer' "$stderr"
QE_TEST_QS_VERSION=0.4.0 run_capability_check >"$stdout" 2>"$stderr"
[[ ! -s "$stdout" ]]
grep -Fq 'newer than the validated 0.3.1 baseline' "$stderr"
grep -Fq 'Warning: optional QE integration is unavailable: qe-theme-switcher' "$stderr"
if QE_TEST_QML_BROKEN=1 run_capability_check >"$stdout" 2>"$stderr"; then
    printf '%s\n' 'compatibility check accepted a broken QML capability' >&2
    exit 1
fi
grep -Fq 'required QML/API probe failed' "$stderr"
rm "$cap_units/wireplumber.service"
if run_capability_check >"$stdout" 2>"$stderr"; then
    printf '%s\n' 'compatibility check accepted a missing packaged user unit' >&2
    exit 1
fi
grep -Fq 'required user unit is unavailable: wireplumber.service' "$stderr"

# Fixture mode isolates filesystem ownership/activation behavior from the host;
# package and capability validation has its own query/check fixture paths.
: >"$test_root/packages"
if run_install install --non-interactive >"$stdout" 2>"$stderr"; then
    printf '%s\n' 'non-interactive install authorized Dunst cutover' >&2
    exit 1
fi
grep -Fq -- '--authorize-dunst-cutover' "$stderr"

run_install install --non-interactive --authorize-dunst-cutover
for name in qe-shell qe-lock qe-action qe-launch qe-defaults qe-doctor qe-hyprshot qe-theme-switcher; do
    [[ -L "$home/.local/bin/$name" ]]
done
[[ "$(readlink -- "$home/.config/systemd/user/dunst.service")" == /dev/null ]]
[[ -f "$home/.config/systemd/user/qe-shell.service" ]]
[[ ! -L "$home/.config/systemd" ]]
jq -e '.schemaVersion == 1 and .outcome == "activation-deferred"
    and .checkoutPath == $checkout and .errorCode == null' \
    --arg checkout "$project_root" "$home/.local/state/qe/installation.json" >/dev/null

receipt_before=$(sha256sum "$home/.local/state/qe/installation.json")
run_install install --non-interactive --authorize-dunst-cutover
[[ "$(readlink -f -- "$home/.local/bin/qe-shell")" == "$project_root/scripts/run-qe.sh" ]]
[[ -f "$home/.local/share/applications/qe-theme-selector.desktop" ]]
[[ "$receipt_before" != "$(sha256sum "$home/.local/state/qe/installation.json")" ]]

rm -f -- "$home/.config/systemd/user/qe-shell.service"
ln -s -- "$project_root/install/assets/qe-shell.service" \
    "$home/.config/systemd/user/qe-shell.service"
if run_install install --non-interactive --authorize-dunst-cutover \
        >"$stdout" 2>"$stderr"; then
    printf '%s\n' 'installer accepted a content-identical asset symlink' >&2
    exit 1
fi
[[ -L "$home/.config/systemd/user/qe-shell.service" ]]
rm -f -- "$home/.config/systemd/user/qe-shell.service"
cp -- "$project_root/install/assets/qe-shell.service" \
    "$home/.config/systemd/user/qe-shell.service"

rm -f -- "$home/.local/share/applications/qe-theme-selector.desktop"
run_install install --non-interactive --authorize-dunst-cutover
[[ -f "$home/.local/share/applications/qe-theme-selector.desktop" ]]

rm -f -- "$home/.local/bin/qe-action"
cp -- "$project_root/install/legacy/qe-project" "$home/.local/bin/qe-project"
cat >"$home/.local/bin/qe-action" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

exec "$HOME/.local/bin/qe-project" qe-action "$@"
EOF
run_install install --non-interactive --authorize-dunst-cutover
[[ "$(readlink -f -- "$home/.local/bin/qe-action")" == "$project_root/scripts/qe-action.sh" ]]
[[ ! -e "$home/.local/bin/qe-project" ]]

rm -f -- "$home/.local/bin/qe-action"
printf '%s\n' mine >"$home/.local/bin/qe-action"
if run_install install --non-interactive --authorize-dunst-cutover \
        >"$stdout" 2>"$stderr"; then
    printf '%s\n' 'installer overwrote an unknown command' >&2
    exit 1
fi
[[ "$(<"$home/.local/bin/qe-action")" == mine ]]

rm -f -- "$home/.local/bin/qe-action"
mkdir -p -- "$test_root/folded"
rm -rf -- "$home/.local/bin"
ln -s -- "$test_root/folded" "$home/.local/bin"
if run_install install --non-interactive --authorize-dunst-cutover \
        >"$stdout" 2>"$stderr"; then
    printf '%s\n' 'installer accepted a folded managed parent' >&2
    exit 1
fi
grep -Fq 'managed parent is a symlink' "$stderr"

printf '%s\n' INSTALLER_TEST_PASSED
