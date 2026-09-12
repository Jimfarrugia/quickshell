#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
bin="$test_root/bin"
runtime="$test_root/runtime"
state="$test_root/state"
proc="$test_root/proc"
signature=fixture-signature
mkdir -p -- "$bin" "$runtime/hypr/$signature" "$proc/4242"
: >"$runtime/hypr/$signature/.socket.sock"
printf 'WAYLAND_DISPLAY=wayland-fixture\0HYPRLAND_INSTANCE_SIGNATURE=%s\0XDG_CURRENT_DESKTOP=Hyprland\0' \
    "$signature" >"$proc/4242/environ"

cat >"$bin/systemctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$TEST_ROOT/systemctl.log"
case "$*" in
    '--user show-environment') ;;
    '--user daemon-reload'|'--user restart qe-shell.service') ;;
    '--user is-enabled --quiet pipewire.socket'|'--user is-enabled --quiet pipewire-pulse.socket'|'--user is-enabled --quiet wireplumber.service') ;;
    '--user is-active --quiet dunst.service') exit 3 ;;
    '--user show qe-shell.service -p InvocationID --value') printf '%s\n' invocation-1 ;;
    '--user show qe-shell.service -p MainPID --value') printf '%s\n' 4242 ;;
    *) exit 1 ;;
esac
EOF
cat >"$bin/dbus-update-activation-environment" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'dbus %s\n' "$*" >>"$TEST_ROOT/systemctl.log"
EOF
cat >"$bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '[{"name":"fixture"}]'
EOF
cat >"$bin/qs" <<EOF
#!/usr/bin/env bash
if [[ "\${QE_TEST_GUARD_FAIL:-0}" == 1 ]]; then
    count=0
    [[ -r "\$TEST_ROOT/qs-count" ]] && count=\$(<"\$TEST_ROOT/qs-count")
    count=\$((count + 1))
    printf '%s\n' "\$count" >"\$TEST_ROOT/qs-count"
    if ((count > 1)); then printf '%s\n' '[]'; exit 0; fi
fi
printf '%s\n' '[{"pid":4242,"config_path":"$project_root/shell.qml"}]'
EOF
cat >"$bin/busctl" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == ' --user list --no-pager' || "$*" == '--user list --no-pager' ]]; then exit 0; fi
if [[ "$*" == *GetNameOwner* ]]; then printf '%s\n' 's ":1.42"'; exit 0; fi
if [[ "$*" == *GetConnectionUnixProcessID* ]]; then printf 'u %s\n' "${QE_TEST_OWNER_PID:-4242}"; exit 0; fi
exit 1
EOF
cat >"$bin/journalctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'Configuration Loaded'
EOF
cat >"$bin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
cat >"$bin/sleep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$bin"/*

run_activation() {
    PATH="$bin:/usr/bin" HOME="$test_root/home" XDG_STATE_HOME="$state" \
    XDG_RUNTIME_DIR="$runtime" DBUS_SESSION_BUS_ADDRESS=fixture-bus \
    WAYLAND_DISPLAY=wayland-fixture HYPRLAND_INSTANCE_SIGNATURE="$signature" \
    XDG_CURRENT_DESKTOP=Hyprland TEST_ROOT="$test_root" \
    QE_ACTIVATION_PROC_ROOT="$proc" QE_ACTIVATION_POLL_ATTEMPTS=2 \
    QE_ACTIVATION_ALLOW_REGULAR_SOCKET_FIXTURE=1 \
    QE_ACTIVATION_POLL_SECONDS=0 QE_ACTIVATION_GUARD_SECONDS=0 \
        "$project_root/scripts/run-qe.sh" --service-start
}

run_activation
jq -e '.schemaVersion == 1 and .outcome == "ready" and .errorCode == null' \
    "$state/qe/installation.json" >/dev/null
grep -Fxq -- '--user daemon-reload' "$test_root/systemctl.log"
grep -Fxq -- '--user restart qe-shell.service' "$test_root/systemctl.log"

rm -f -- "$test_root/qs-count"
if QE_TEST_GUARD_FAIL=1 run_activation >"$test_root/guard.stdout" 2>"$test_root/guard.stderr"; then
    printf '%s\n' 'activation accepted readiness loss during the crash guard' >&2
    exit 1
fi
jq -e '.outcome == "activation-failed" and .errorCode == "readiness-lost"' \
    "$state/qe/installation.json" >/dev/null

if QE_TEST_OWNER_PID=9999 run_activation >"$test_root/owner.stdout" 2>"$test_root/owner.stderr"; then
    printf '%s\n' 'activation accepted an unmanaged notification owner' >&2
    exit 1
fi
jq -e '.outcome == "activation-failed" and .errorCode == "unknown-notification-owner"' \
    "$state/qe/installation.json" >/dev/null

if env -u WAYLAND_DISPLAY PATH="$bin:/usr/bin" HOME="$test_root/home" \
    XDG_STATE_HOME="$state" XDG_RUNTIME_DIR="$runtime" DBUS_SESSION_BUS_ADDRESS=fixture \
    HYPRLAND_INSTANCE_SIGNATURE="$signature" XDG_CURRENT_DESKTOP=Hyprland \
    QE_ACTIVATION_PROC_ROOT="$proc" "$project_root/scripts/run-qe.sh" --service-start \
    >"$test_root/failure.stdout" 2>"$test_root/failure.stderr"; then
    printf '%s\n' 'activation accepted a missing Wayland display' >&2
    exit 1
fi
jq -e '.outcome == "activation-failed" and .errorCode == "missing-environment"' \
    "$state/qe/installation.json" >/dev/null

printf '%s\n' ACTIVATION_TEST_PASSED
