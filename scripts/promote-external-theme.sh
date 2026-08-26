#!/usr/bin/env bash
set -euo pipefail

# Promotes QE-generated external "wallpaper" theme files into each app's
# theme slot. The spec JSON is produced by QE from the wallpaper palette; this
# script only materializes and atomically replaces files. Result document on
# stdout and exit semantics mirror the external theme-switcher machine mode:
# 0 = success, 3 = partial, 4 = failed, 2 = usage/contract error.

if [[ $# -ne 1 || -z "${1:-}" ]]; then
    printf 'Usage: %s <spec-file>\n' "$0" >&2
    exit 2
fi

spec_file=$1
if [[ "$spec_file" != /* || ! -f "$spec_file" || ! -r "$spec_file" ]]; then
    printf 'External wallpaper theme spec must be an absolute readable file.\n' >&2
    exit 2
fi

for dependency in jq mktemp realpath; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'Required external theme dependency is unavailable: %s\n' "$dependency" >&2
        exit 127
    fi
done

if ! jq -e '.schemaVersion == 1 and (.targets | type == "array")' "$spec_file" >/dev/null 2>&1; then
    printf 'External wallpaper theme spec is not a valid schema-v1 target list.\n' >&2
    exit 2
fi

target_count=$(jq '.targets | length' "$spec_file")
if [[ ! "$target_count" =~ ^[0-9]+$ ]] || ((target_count == 0)); then
    printf 'External wallpaper theme spec contains no targets.\n' >&2
    exit 2
fi

path_has_parent_segment() {
    local path=$1
    local segment
    IFS='/' read -r -a segments <<<"$path"
    for segment in "${segments[@]}"; do
        if [[ "$segment" == ".." ]]; then
            return 0
        fi
    done
    return 1
}

resolve_target_path() {
    local path=$1
    # Stow-managed slots can be restore-managed links to mutable XDG state. Never
    # replace the link itself; promote the generated file at its destination.
    if [[ -L "$path" ]]; then
        realpath -m -- "$path"
    else
        printf '%s\n' "$path"
    fi
}

results=()
exit_code=0
temporary_dirs=()

# shellcheck disable=SC2329
cleanup() {
    rm -rf -- "${temporary_dirs[@]}"
}
trap cleanup EXIT

for ((i = 0; i < target_count; i++)); do
    id=$(jq -r --argjson i "$i" '.targets[$i].id' "$spec_file")
    path=$(jq -r --argjson i "$i" '.targets[$i].path' "$spec_file")
    executable=$(jq -r --argjson i "$i" '.targets[$i].executable // ""' "$spec_file")

    if [[ ! "$id" =~ ^[a-z0-9_]+$ ]]; then
        results+=("{\"id\":\"$id\",\"status\":\"failed\",\"error\":\"invalid target id\"}")
        exit_code=4
        continue
    fi
    if [[ "$path" != /* || $(path_has_parent_segment "$path"; echo $?) -eq 0 ]]; then
        results+=("{\"id\":\"$id\",\"status\":\"failed\",\"error\":\"invalid target path\"}")
        exit_code=4
        continue
    fi
    if ! path=$(resolve_target_path "$path"); then
        results+=("{\"id\":\"$id\",\"status\":\"failed\",\"error\":\"target path could not be resolved\"}")
        exit_code=4
        continue
    fi
    if [[ "$path" != /* || $(path_has_parent_segment "$path"; echo $?) -eq 0 ]]; then
        results+=("{\"id\":\"$id\",\"status\":\"failed\",\"error\":\"resolved target path is invalid\"}")
        exit_code=4
        continue
    fi
    if [[ -n "$executable" ]] && ! command -v "$executable" >/dev/null 2>&1; then
        results+=("{\"id\":\"$id\",\"status\":\"skipped\",\"error\":\"executable is unavailable\"}")
        continue
    fi

    target_dir=$(dirname -- "$path")
    if ! mkdir -p -- "$target_dir" 2>/dev/null; then
        results+=("{\"id\":\"$id\",\"status\":\"failed\",\"error\":\"target directory could not be created\"}")
        exit_code=4
        continue
    fi
    temporary_dir=$(mktemp -d "$target_dir/.qe-wallpaper.XXXXXX")
    temporary_dirs+=("$temporary_dir")
    staged_path="$temporary_dir/wallpaper"
    if ! jq -r --argjson i "$i" '.targets[$i].content' "$spec_file" >"$staged_path" 2>/dev/null; then
        results+=("{\"id\":\"$id\",\"status\":\"failed\",\"error\":\"content extraction failed\"}")
        exit_code=4
        continue
    fi
    if [[ ! -s "$staged_path" ]]; then
        results+=("{\"id\":\"$id\",\"status\":\"failed\",\"error\":\"empty generated content\"}")
        exit_code=4
        continue
    fi

    if [[ -f "$path" ]] && cmp -s "$staged_path" "$path"; then
        results+=("{\"id\":\"$id\",\"status\":\"unchanged\"}")
        continue
    fi

    if mv -f -- "$staged_path" "$path" 2>/dev/null; then
        results+=("{\"id\":\"$id\",\"status\":\"applied\"}")
    else
        results+=("{\"id\":\"$id\",\"status\":\"failed\",\"error\":\"atomic promotion failed\"}")
        exit_code=4
    fi
done

promoted_count=0
failed_count=0
for result in "${results[@]}"; do
    case "$result" in
        *'"status":"applied"'*) ((promoted_count += 1)) ;;
        *'"status":"failed"'*) ((failed_count += 1)) ;;
    esac
done
if ((failed_count > 0 && promoted_count > 0)); then
    exit_code=3
elif ((failed_count > 0)); then
    exit_code=4
else
    exit_code=0
fi

printf '{"schema":"qe-external-theme","version":1,"results":[%s]}\n' "$(IFS=,; printf '%s' "${results[*]}")"
exit "$exit_code"
