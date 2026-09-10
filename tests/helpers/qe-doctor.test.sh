#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
test_bin="$test_root/bin"
user_bin="$test_root/user-bin"
proc_root="$test_root/proc"

cleanup() { rm -rf -- "$test_root"; }
trap cleanup EXIT

mkdir -p -- "$test_bin" "$user_bin" "$proc_root/4242"
printf '%s\n' quickshell >"$proc_root/4242/comm"

commands=(quickshell qs systemctl dbus-update-activation-environment pgrep busctl
    python3 brightnessctl df timeout nmcli setpriv gdbus dbus-monitor matugen jq file
    magick hyprctl hyprpaper flock pavucontrol nm-connection-editor blueman-manager rofi
    hyprlock waybar dunst)
for command_name in "${commands[@]}"; do
    cat >"$test_bin/$command_name" <<'EOF'
#!/usr/bin/bash
exit 0
EOF
    chmod +x "$test_bin/$command_name"
done

cat >"$test_bin/systemctl" <<'EOF'
#!/usr/bin/bash
if [[ "$*" == '--user is-active --quiet qe-shell.service' ]]; then exit 0; fi
if [[ "$*" == '--user show -p MainPID --value qe-shell.service' ]]; then printf '%s\n' 4242; exit 0; fi
exit 1
EOF
cat >"$test_bin/qs" <<EOF
#!/usr/bin/bash
printf '%s\n' 'Instance test:' '  Config path: $project_root/shell.qml'
EOF
cat >"$test_bin/busctl" <<'EOF'
#!/usr/bin/bash
if [[ "$*" == *'GetNameOwner'* ]]; then printf '%s\n' 's ":1.42"'; exit 0; fi
if [[ "$*" == *'GetConnectionUnixProcessID'* ]]; then printf '%s\n' 'u 4242'; exit 0; fi
exit 1
EOF
cat >"$test_bin/pgrep" <<'EOF'
#!/usr/bin/bash
exit 1
EOF
chmod +x "$test_bin/systemctl" "$test_bin/qs" "$test_bin/busctl" "$test_bin/pgrep"

ln -s "$project_root/scripts/run-qe.sh" "$user_bin/qe-shell"
ln -s "$project_root/scripts/run-qe-lock.sh" "$user_bin/qe-lock"
ln -s "$project_root/scripts/qe-action.sh" "$user_bin/qe-action"
ln -s "$project_root/scripts/qe-launch.sh" "$user_bin/qe-launch"
ln -s "$project_root/scripts/qe-defaults" "$user_bin/qe-defaults"
ln -s "$project_root/scripts/qe-doctor" "$user_bin/qe-doctor"
ln -s "$project_root/scripts/qe-hyprshot.sh" "$user_bin/qe-hyprshot"

output=$(PATH="$test_bin:/usr/bin" QE_DOCTOR_USER_BIN_DIR="$user_bin" \
    QE_DOCTOR_PROC_ROOT="$proc_root" "$project_root/scripts/qe-doctor")
[[ "$output" == *'Summary: 0 failure(s), 0 warning(s)'* ]]
[[ "$output" == *'notification service owned by supervised QE (PID 4242)'* ]]

cat >"$test_bin/pgrep" <<'EOF'
#!/usr/bin/bash
[[ "$*" == '-x dunst' ]]
EOF
chmod +x "$test_bin/pgrep"
if PATH="$test_bin:/usr/bin" QE_DOCTOR_USER_BIN_DIR="$user_bin" \
    QE_DOCTOR_PROC_ROOT="$proc_root" "$project_root/scripts/qe-doctor" \
    >"$test_root/failure-output"; then
    printf '%s\n' 'qe-doctor unexpectedly accepted a conflicting retired owner' >&2
    exit 1
fi
grep -Fq '[FAIL] retired conflicting process is running: dunst' "$test_root/failure-output"

ln -s /usr/bin/bash "$test_bin/bash"
ln -s /usr/bin/dirname "$test_bin/dirname"
ln -s /usr/bin/grep "$test_bin/grep"
ln -s /usr/bin/readlink "$test_bin/readlink"
rm -f -- "$test_bin/brightnessctl"
if PATH="$test_bin" QE_DOCTOR_USER_BIN_DIR="$user_bin" \
    QE_DOCTOR_PROC_ROOT="$proc_root" "$project_root/scripts/qe-doctor" \
    >"$test_root/enabled-feature-output"; then
    printf '%s\n' 'qe-doctor unexpectedly accepted a missing enabled-feature command' >&2
    exit 1
fi
grep -Fq '[FAIL] enabled-feature command missing: brightnessctl' \
    "$test_root/enabled-feature-output"
cp -- "$test_bin/python3" "$test_bin/brightnessctl"

rm -f -- "$test_bin/quickshell"
if PATH="$test_bin" QE_DOCTOR_USER_BIN_DIR="$user_bin" \
    QE_DOCTOR_PROC_ROOT="$proc_root" /usr/bin/bash "$project_root/scripts/qe-doctor" \
    >"$test_root/missing-output"; then
    printf '%s\n' 'qe-doctor unexpectedly accepted a missing required command' >&2
    exit 1
fi
grep -Fq '[FAIL] required command missing: quickshell' "$test_root/missing-output"

printf '%s\n' 'QE_DOCTOR_TEST_PASSED'
