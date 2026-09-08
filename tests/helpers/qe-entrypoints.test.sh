#!/usr/bin/env bash
set -euo pipefail

dotfiles_root=${QE_DOTFILES_ROOT:-$HOME/dotfiles}
entrypoint_root="$dotfiles_root/scripts/.local/bin"
test_root=$(mktemp -d)
log_file="$test_root/entrypoints.log"

cleanup() { rm -rf -- "$test_root"; }
trap cleanup EXIT

mkdir -p -- "$test_root/project/scripts" "$test_root/home/.local/bin" \
    "$test_root/home/Projects"
ln -s "$entrypoint_root/qe-project" "$test_root/home/.local/bin/qe-project"
ln -s "$test_root/project" "$test_root/home/Projects/quickshell"

entry_points=(qe-action qe-defaults qe-doctor qe-hyprshot qe-launch qe-lock qe-shell)
targets=(qe-action.sh qe-defaults qe-doctor qe-hyprshot.sh qe-launch.sh run-qe-lock.sh run-qe.sh)
for index in "${!entry_points[@]}"; do
    entry_point=${entry_points[$index]}
    target=${targets[$index]}
    cat >"$test_root/project/scripts/$target" <<EOF
#!/usr/bin/env bash
printf '%s %s\n' '$target' "\$*" >>'$log_file'
EOF
    chmod +x "$test_root/project/scripts/$target"
    HOME="$test_root/home" QE_PROJECT_ROOT="$test_root/project" \
        "$entrypoint_root/$entry_point" argument
done

HOME="$test_root/home" "$entrypoint_root/qe-shell" default
grep -Fqx 'run-qe.sh default' "$log_file"

resolved=$(HOME="$test_root/home" QE_PROJECT_ROOT="$test_root/project" \
    "$entrypoint_root/qe-project" --resolve qe-doctor)
[[ "$resolved" == "$test_root/project/scripts/qe-doctor" ]]

for index in "${!entry_points[@]}"; do
    grep -Fqx "${targets[$index]} argument" "$log_file"
done

if HOME="$test_root/home" QE_PROJECT_ROOT="$test_root/project" \
    "$entrypoint_root/qe-project" unknown >/dev/null 2>&1; then
    printf '%s\n' 'qe-project unexpectedly accepted an unknown entry point' >&2
    exit 1
fi

printf '%s\n' 'QE_ENTRYPOINTS_TEST_PASSED'
