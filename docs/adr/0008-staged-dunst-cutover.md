# ADR-008: Staged Dunst cutover

Status: Accepted by user

Decision: keep Dunst during development; test QE ownership only in isolated
windows/sessions; disable Dunst only after notification acceptance passes.

Context: the DBus notification service has exclusive ownership.

Rationale: preserves reliable daily notifications and a simple rollback.

Alternatives considered: replace Dunst early; defer notification work entirely.

Consequences: notification development needs explicit owner transitions and
cannot be casually tested alongside Dunst.

Affected areas: Phase 5-6, Dunst user service, hardware scripts.

Revisit if: DBus activation prevents reliable isolated testing; use a separate
test user/session instead.
