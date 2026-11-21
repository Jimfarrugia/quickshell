# ADR-006: Matugen generates QE and external `Wallpaper` outputs

Status: Accepted by user

Decision: one wallpaper input generates a QE theme conforming to the normal
schema and supported external application artifacts.

Context: `Wallpaper` must be selectable like a manual QE theme and participate
in wider desktop theming.

Rationale: one derivation pipeline avoids manually maintaining unrelated
generated palettes.

Alternatives considered: QE-only generation; limited core-app generation.

Consequences: template validation and staged promotion become critical; target
coverage can vary but must be reported.

Affected areas: Matugen config, theme schema, external switcher, wallpaper flow.

Revisit if: maintaining broad external templates becomes disproportionate; a
documented supported-target subset may then replace universal generation.
