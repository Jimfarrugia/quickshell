#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
log_file="$test_root/systemctl.log"
quickshell_log="$test_root/quickshell.log"

cleanup() {
    rm -rf -- "$test_root"
}
trap cleanup EXIT

mkdir -p -- "$test_root/bin"
cat >"$test_root/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$QE_TEST_SYSTEMCTL_LOG"
if [[ "$*" == "--user is-active --quiet qe-shell.service" ]]; then
    [[ "${QE_TEST_SYSTEMD_ACTIVE:-1}" == 1 ]]
    exit
fi
if [[ "$*" == "--user restart qe-shell.service" ]]; then
    exit 0
fi
exit 1
EOF
cat >"$test_root/bin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
cat >"$test_root/bin/quickshell" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >"$QE_TEST_QUICKSHELL_LOG"
EOF
cat >"$test_root/bin/dbus-update-activation-environment" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'dbus %s\n' "$*" >>"$QE_TEST_SYSTEMCTL_LOG"
EOF
chmod +x "$test_root/bin/systemctl"
chmod +x "$test_root/bin/pgrep"
chmod +x "$test_root/bin/quickshell"
chmod +x "$test_root/bin/dbus-update-activation-environment"

PATH="$test_root/bin:$PATH" \
QE_TEST_SYSTEMCTL_LOG="$log_file" \
    "$project_root/scripts/run-qe.sh" --restart

mapfile -t calls <"$log_file"
[[ "${calls[0]:-}" == "--user is-active --quiet qe-shell.service" ]]
[[ "${calls[1]:-}" == "--user restart qe-shell.service" ]]
[[ ${#calls[@]} -eq 2 ]]

: >"$log_file"
if PATH="$test_root/bin:$PATH" QE_TEST_SYSTEMCTL_LOG="$log_file" \
    "$project_root/scripts/run-qe.sh" --restart --detach \
    2>"$test_root/detach-error"; then
    printf '%s\n' 'active service unexpectedly accepted detached restart' >&2
    exit 1
fi
grep -Fq -- '--detach cannot replace an active supervised service' \
    "$test_root/detach-error"
[[ "$(<"$log_file")" == "--user is-active --quiet qe-shell.service" ]]

: >"$log_file"
PATH="$test_root/bin:$PATH" \
QE_TEST_SYSTEMD_ACTIVE=0 \
QE_TEST_SYSTEMCTL_LOG="$log_file" \
QE_TEST_QUICKSHELL_LOG="$quickshell_log" \
    "$project_root/scripts/run-qe.sh" --restart

[[ "$(<"$log_file")" == "--user is-active --quiet qe-shell.service" ]]
[[ "$(<"$quickshell_log")" == "--no-duplicate --path $project_root/shell.qml" ]]

if PATH="$test_root/bin:$PATH" \
    HOME="$test_root" XDG_STATE_HOME="$test_root/state" \
    WAYLAND_DISPLAY=wayland-test \
    XDG_CURRENT_DESKTOP=Hyprland \
    QE_TEST_SYSTEMCTL_LOG="$log_file" \
    env -u HYPRLAND_INSTANCE_SIGNATURE \
    "$project_root/scripts/run-qe.sh" --service-start 2>"$test_root/start-error"; then
    printf '%s\n' 'service start unexpectedly accepted a missing instance signature' >&2
    exit 1
fi
grep -Fq 'HYPRLAND_INSTANCE_SIGNATURE is unavailable' "$test_root/start-error"

printf '%s\n' 'RUN_QE_TEST_PASSED'
