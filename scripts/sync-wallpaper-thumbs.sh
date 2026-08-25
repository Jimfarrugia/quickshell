#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR="${1:-}"
OUTPUT_DIR="${2:-}"

if [[ -z "$SOURCE_DIR" || -z "$OUTPUT_DIR" ]]; then
    printf 'Usage: %s <wallpaper-directory> <cache-directory>\n' "$0" >&2
    exit 2
fi
if [[ ! -d "$SOURCE_DIR" ]]; then
    printf 'Wallpaper directory does not exist: %s\n' "$SOURCE_DIR" >&2
    exit 2
fi

mkdir -p -- "$OUTPUT_DIR"
temporary_dir="$(mktemp -d "${OUTPUT_DIR}/.sync.XXXXXX")"
manifest="${temporary_dir}/manifest"
expected="${temporary_dir}/expected"
trap 'rm -rf -- "$temporary_dir"' EXIT

: >"$manifest"
: >"$expected"
while IFS= read -r -d '' source; do
    name="$(basename -- "$source")"
    extension="${name##*.}"
    extension="${extension,,}"
    case "$extension" in
        jpg | jpeg | png | webp | gif)
            stem="${name%.*}"
            id="$(printf '%s' "$source" | sha256sum | cut -c1-12)"
            thumbnail_name="${stem}-${id}.jpg"
            thumbnail_path="${OUTPUT_DIR}/${thumbnail_name}"
            printf '%s\n' "$thumbnail_name" >>"$expected"
            printf '%s\t%s\n' "$thumbnail_name" "$source" >>"$manifest"
            if [[ ! -f "$thumbnail_path" || "$thumbnail_path" -ot "$source" ]]; then
                temporary_thumbnail="${temporary_dir}/${thumbnail_name}"
                if ! magick "$source" -auto-orient -thumbnail '480x270>' -quality 80 "$temporary_thumbnail"; then
                    printf 'Could not generate thumbnail for: %s\n' "$source" >&2
                    exit 1
                fi
                mv -f -- "$temporary_thumbnail" "$thumbnail_path"
            fi
            ;;
    esac
done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -print0)

LC_ALL=C sort -t $'\t' -k2,2 "$manifest" -o "$manifest"
while IFS= read -r -d '' thumbnail; do
    name="$(basename -- "$thumbnail")"
    if ! grep -Fqx -- "$name" "$expected"; then
        rm -f -- "$thumbnail"
    fi
done < <(find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.jpg' -print0)

mv -f -- "$manifest" "${OUTPUT_DIR}/manifest"
