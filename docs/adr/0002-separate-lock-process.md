# ADR-002: Separate lock process

Status: Accepted by user

Decision: persistent shell and secure lock use separate Quickshell processes.

Context: lock security and availability should not share the persistent shell's
large failure domain.

Rationale: minimizes lock dependencies and prevents bar/dashboard failures from
affecting the lock UI.

Alternatives considered: one process; additional process isolation for all
transient tools.

Consequences: theme/config sharing occurs through validated disk state; a crash
after secure lock remains fail-closed and requires session recovery.

Affected areas: entry points, theme/config readers, lock lifecycle, Hypridle.

Revisit if: the compositor/session-lock protocol gains a verified secure
handover/recovery mechanism or process separation causes a security regression.
