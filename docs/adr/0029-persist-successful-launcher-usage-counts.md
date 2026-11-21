# ADR-029: Persist successful launcher usage counts

Status: Accepted by user on 2026-08-31

Decision: the Phase 7 launcher records successful main-command launches as
QE-owned usage records, keyed by stable desktop-entry ID and persisted in
versioned `launcher-usage.json` state separate from authored configuration. The
document has an `entries` object mapping IDs to `launchCount`. It retains at
most 512 records, prunes IDs no longer present, and ranks empty-query results
by launch count before normalized name and stable ID. For non-empty queries,
search relevance precedes usage count. Terminal entries are excluded from v1.

Context: Quickshell provides the desktop-entry model and structured commands but
does not provide usage-based sorting. A session-only count would not satisfy
the meaning of frequently used, while adding usage tracking to user config would
mix generated behavior with authored settings.

Consequences: LauncherService owns loading, validation, in-memory updates, and
atomic persistence of usage state. A persistence failure does not fail a
successful launch; it leaves the current-process count updated and reports a
bounded diagnostic. Malformed or incompatible state starts empty without
blocking the launcher.

Affected areas: LauncherService, launcher ranking utilities, XDG state schema,
launcher tests, and the Phase 7 acceptance/rollback validation.

Related decision: ADR-030 later includes eligible `Terminal=true` desktop entries
and applies the same successful-launch usage-count policy to them.
