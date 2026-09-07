#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

bin_dir="$test_root/bin"
data_dir="$test_root/data"
runtime_dir="$test_root/runtime"
mkdir -p -- "$bin_dir" "$data_dir" "$runtime_dir"

cat >"$bin_dir/file" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' image/png
EOF
cat >"$bin_dir/hyprctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'hyprctl %s\n' "$*" >>"${TEST_LOG:?}"
if [[ "${FAKE_HYPRCTL_TIMEOUT:-0}" == 1 ]]; then sleep 1; fi
if [[ "${FAKE_REJECT:-0}" == 1 ]]; then exit 1; fi
exit 0
EOF
cat >"$bin_dir/magick" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'magick %s\n' "$*" >>"${TEST_LOG:?}"
if [[ "${FAKE_MAGICK_FAIL:-0}" == 1 ]]; then exit 1; fi
if [[ "${1:-}" == identify ]]; then exit 0; fi
output=${!#}
output=${output#PNG32:}
printf '%s\n' generated >"$output"
EOF
cat >"$bin_dir/pgrep" <<'EOF'
#!/usr/bin/env bash
exit "${FAKE_HYPRPAPER_RUNNING:-1}"
EOF
cat >"$bin_dir/nohup" <<'EOF'
#!/usr/bin/env bash
printf 'nohup %s\n' "$*" >>"${TEST_LOG:?}"
exit 0
EOF
cat >"$bin_dir/hyprpaper" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$bin_dir"/*

printf '%s' 'source' >"$test_root/source.png"
printf '%s' 'prior' >"$data_dir/current_wallpaper.png"

TEST_LOG="$test_root/log" PATH="$bin_dir:$PATH" XDG_DATA_HOME="$data_dir" XDG_RUNTIME_DIR="$runtime_dir" \
    "$project_root/scripts/qe-wallpaper" "$test_root/source.png" >"$test_root/result"
grep -q '"status":"success"' "$test_root/result"
grep -q '"live":"requested"' "$test_root/result"
[[ "$(<"$data_dir/current_wallpaper.png")" == generated ]]
if [[ "$(<"$test_root/log")" != *$'hyprctl '*$'\nmagick '* ]]; then
    printf '%s\n' 'IPC was not attempted before generation' >&2
    exit 1
fi

printf '%s' 'prior' >"$data_dir/current_wallpaper.png"
if TEST_LOG="$test_root/failure-log" FAKE_MAGICK_FAIL=1 PATH="$bin_dir:$PATH" XDG_DATA_HOME="$data_dir" XDG_RUNTIME_DIR="$runtime_dir" \
    "$project_root/scripts/qe-wallpaper" "$test_root/source.png" >"$test_root/failure-result"; then
    printf '%s\n' 'generation failure was accepted' >&2
    exit 1
fi
[[ "$(<"$data_dir/current_wallpaper.png")" == prior ]]
grep -q '"errorCode":"post-apply-generation-failed"' "$test_root/failure-result"

if TEST_LOG="$test_root/reject-log" FAKE_REJECT=1 FAKE_HYPRPAPER_RUNNING=0 PATH="$bin_dir:$PATH" XDG_DATA_HOME="$data_dir" XDG_RUNTIME_DIR="$runtime_dir" \
    "$project_root/scripts/qe-wallpaper" "$test_root/source.png" >/dev/null; then
    exit 1
fi
if grep -q 'nohup' "$test_root/reject-log"; then
    printf '%s\n' 'healthy Hyprpaper was restarted' >&2
    exit 1
fi

if TEST_LOG="$test_root/unavailable-log" FAKE_REJECT=1 PATH="$bin_dir:$PATH" XDG_DATA_HOME="$data_dir" XDG_RUNTIME_DIR="$runtime_dir" \
    "$project_root/scripts/qe-wallpaper" "$test_root/source.png" >/dev/null; then
    printf '%s\n' 'unavailable Hyprpaper was accepted' >&2
    exit 1
fi

if "$project_root/scripts/qe-wallpaper" >/dev/null 2>&1; then
    printf '%s\n' 'invalid invocation was accepted' >&2
    exit 1
fi

if timeout 3 env TEST_LOG="$test_root/timeout-log" FAKE_HYPRCTL_TIMEOUT=1 FAKE_HYPRPAPER_RUNNING=0 \
    PATH="$bin_dir:$PATH" XDG_DATA_HOME="$data_dir" XDG_RUNTIME_DIR="$runtime_dir" \
    "$project_root/scripts/qe-wallpaper" "$test_root/source.png" >"$test_root/timeout-result"; then
    printf '%s\n' 'Hyprpaper timeout was accepted' >&2
    exit 1
fi
grep -q '"errorCode":"wallpaper-ipc-rejected"' "$test_root/timeout-result"

if "$project_root/scripts/qe-wallpaper" "$test_root/missing.png" >"$test_root/missing-result"; then
    printf '%s\n' 'missing source was accepted' >&2
    exit 1
fi
grep -q '"status":"invalid"' "$test_root/missing-result"

printf '%s\n' QE_WALLPAPER_HELPER_TEST_PASSED
