# ADR-009: Bar as first vertical slice

Status: Accepted by user

Decision: validate foundations through a safely coexisting bar.

Context: the bar exercises multiple native event-driven integrations and daily
presentation without exclusive protocol ownership.

Rationale: high architectural coverage with lower migration risk than lock or
notifications.

Alternatives considered: theme selector, launcher, lock.

Consequences: first slice intentionally omits feature breadth and cutover.

Affected areas: Phases 1-3.

Revisit if: Waybar coexistence proves technically unsafe; use a test floating
surface with the same service contracts.
