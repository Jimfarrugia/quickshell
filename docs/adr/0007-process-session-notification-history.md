# ADR-007: Process-session notification history

Status: Accepted by user

Decision: do not persist notification history to disk initially.

Context: disk persistence adds privacy, retention, serialization, and migration
requirements.

Rationale: current-process history meets the initial notification-center goal
with lower risk.

Alternatives considered: persistence from first release; popups without history.

Consequences: history is lost on QE restart and diagnostics must not imply
otherwise.

Affected areas: NotificationService and center.

Revisit if: daily use demonstrates restart-persistent history is valuable enough
to justify a privacy and migration design.
