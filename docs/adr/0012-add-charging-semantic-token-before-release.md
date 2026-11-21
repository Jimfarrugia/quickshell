# ADR-012: Add charging semantic token before release

Status: Accepted by user

Decision: revise the pre-release theme-v1 contract to require a `charging`
semantic color token.

Context: charging is a distinct visible power state and should not implicitly
reuse warning or accent semantics. QE has no shipped external theme consumers,
so a coordinated v1 revision is smaller and safer than adding schema migration
code now.

Rationale: every authored theme can choose an intentional charging color while
bar presentation remains palette-independent.

Alternatives considered: reuse `warning`; reuse `accentSecondary`; introduce
theme schema v2 immediately.

Consequences: all authored themes, fixtures, emergency fallback data, runtime
validation, JSON Schema, and token documentation require `charging`. Poimandres
maps it to `palette.yellow`; Gruvbox maps it to `palette.yellowLight`.

Affected areas: theme-v1 contract, Phase 2 power presentation, future generated
themes.

Revisit if: external theme consumers ship before another token change; further
contract changes then require a versioned migration.
