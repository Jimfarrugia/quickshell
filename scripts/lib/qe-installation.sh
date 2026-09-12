#!/usr/bin/env bash

qe_state_home() {
    printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
}

qe_installation_receipt_path() {
    printf '%s/qe/installation.json\n' "$(qe_state_home)"
}

qe_install_lock_path() {
    printf '%s/qe/install.lock\n' "$(qe_state_home)"
}

qe_acquire_install_lock() {
    local lock_path inherited_target
    lock_path=$(qe_install_lock_path)
    mkdir -p -- "$(dirname -- "$lock_path")"

    if [[ -n "${QE_INSTALL_LOCK_FD:-}" ]]; then
        [[ "$QE_INSTALL_LOCK_FD" =~ ^[0-9]+$ && -e "/proc/$$/fd/$QE_INSTALL_LOCK_FD" ]] || {
            printf '%s\n' 'QE installation lock inheritance is invalid.' >&2
            return 1
        }
        inherited_target=$(readlink -f -- "/proc/$$/fd/$QE_INSTALL_LOCK_FD")
        [[ "$inherited_target" == "$lock_path" && "${QE_INSTALL_LOCK_PATH:-}" == "$lock_path" ]] || {
            printf '%s\n' 'QE installation lock inheritance does not match the shared lock.' >&2
            return 1
        }
        flock -n "$QE_INSTALL_LOCK_FD" || {
            printf '%s\n' 'QE installation lock descriptor is not the inherited lock owner.' >&2
            return 1
        }
        return 0
    fi

    exec {QE_INSTALL_LOCK_FD}>"$lock_path"
    flock -x "$QE_INSTALL_LOCK_FD"
    QE_INSTALL_LOCK_PATH=$lock_path
    export QE_INSTALL_LOCK_FD QE_INSTALL_LOCK_PATH
}

qe_attempt_id() {
    if [[ -r /proc/sys/kernel/random/uuid ]]; then
        tr -d '\n' </proc/sys/kernel/random/uuid
    else
        printf '%s-%s-%s' "$(date +%s)" "$$" "$RANDOM"
    fi
}

qe_write_installation_receipt() {
    local outcome=$1 checkout=$2 error_code=${3:-} error_context=${4:-}
    local receipt directory temporary attempt timestamp
    receipt=$(qe_installation_receipt_path)
    directory=$(dirname -- "$receipt")
    mkdir -p -- "$directory"
    temporary="$directory/.installation.json.$$.$RANDOM"
    attempt=$(qe_attempt_id)
    timestamp=$(date --utc +%Y-%m-%dT%H:%M:%SZ)

    jq -n \
        --arg outcome "$outcome" \
        --arg attempt "$attempt" \
        --arg timestamp "$timestamp" \
        --arg checkout "$checkout" \
        --arg errorCode "$error_code" \
        --arg errorContext "$error_context" \
        '{schemaVersion: 1, outcome: $outcome, attemptId: $attempt,
          attemptedAt: $timestamp, checkoutPath: $checkout,
          errorCode: (if $errorCode == "" then null else $errorCode end),
          errorContext: (if $errorContext == "" then null else $errorContext end)}' \
        >"$temporary"
    chmod 0600 -- "$temporary"
    mv -fT -- "$temporary" "$receipt"
}
