#!/usr/bin/env bash
set -euo pipefail

counter_file=${QE_FAKE_MATUGEN_COUNTER:?QE_FAKE_MATUGEN_COUNTER is required}
count=0
if [[ -f "$counter_file" ]]; then
    count=$(<"$counter_file")
fi
printf '%s\n' "$((count + 1))" >"$counter_file"

output=$("$(dirname -- "${BASH_SOURCE[0]}")/fake-matugen.sh")
if ((count == 0)); then
    printf '%s\n' "$output"
else
    printf '%s\n' "$output" \
        | sed -e 's/#101820/#202020/g' \
            -e 's/#f4f7fb/#eeeeee/g' \
            -e 's/#18232d/#303030/g' \
            -e 's/#9ecaff/#a0d0ff/g'
fi
