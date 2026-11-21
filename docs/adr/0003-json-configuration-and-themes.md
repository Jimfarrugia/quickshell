# ADR-003: JSON configuration and themes

Status: Accepted by user

Decision: use strict, versioned JSON for user configuration and themes.

Context: QE and external generators need a portable, schema-validatable format.

Rationale: Quickshell supports JSON adapters and external tools can reliably
produce/validate JSON.

Alternatives considered: executable QML config, JSONC, TOML.

Consequences: comments are unavailable; schemas and diagnostics must make files
understandable. Generated and authored JSON remain in separate roots.

Affected areas: config, themes, Matugen, persistent state.

Revisit if: native tooling cannot provide safe transactional JSON reload or user
maintenance proves materially worse than alternatives.
