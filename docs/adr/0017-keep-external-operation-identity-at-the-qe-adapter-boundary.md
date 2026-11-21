# ADR-017: Keep external operation identity at the QE adapter boundary

Status: Accepted as part of the approved Phase 4 machine contract on 2026-08-25

Decision: use the switcher's schema-v1 document as durable external desktop
state without a QE operation ID. `ThemeService` assigns a local operation ID
before invoking machine mode, `CommandRunner` carries it through the bounded
process lifecycle, and stale process results are rejected by that local ID.

Context: the switcher remains independently usable, and its persisted document
describes external state that may be produced by QE, its human CLI, or another
machine caller. Persisting a QE-generated ID would imply QE ownership and would
not identify independent invocations meaningfully. QE still needs operation
identity to prevent stale process completion from overwriting current UI state.

Alternatives considered: require every switcher caller to provide and persist an
operation ID; let QE infer result identity only from requested theme; omit
operation association in QE.

Consequences: the machine syntax remains
`run.sh --machine --theme <id> [--skip-gtk]`; its state/result schema contains
theme, status, timestamp, persistence, error, and per-target outcomes but no
caller identity. QE serializes theme requests through an active external phase
and associates only direct process results with its local operation ID. File
watch updates are external state observations and never complete a QE operation
or mutate the active QE theme.

Affected areas: external switcher schema v1, `ExternalThemeAdapter`,
`ThemeService`, selector status, command fixtures, and external state watching.

Revisit if: the switcher adds concurrent remote callers that require shared
cross-process request correlation rather than independent durable state.
