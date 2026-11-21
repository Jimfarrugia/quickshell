# ADR-018: Stage QE wallpaper themes before promotion

Status: Accepted as part of the Phase 4 wallpaper implementation on 2026-08-25

Decision: Matugen output mapped to the QE `Wallpaper` schema is written to a
per-operation staging path under the QE data directory. A dedicated promotion
adapter atomically renames the staged artifact into the catalog-visible
`Wallpaper.json` path only after the staged write succeeds.

Context: direct writes to the catalog-visible generated file made the current
foundation safe at the single-file level but did not expose a distinct
generation/promotion boundary. The Phase 4 contract requires generated output
to remain out of authored themes and to retain the complete last-known-good set
when generation or promotion fails.

Rationale: keeping staging and the target on the same filesystem gives the QE
artifact a replace operation with clear failure semantics. The adapter remains
replaceable when approved external Matugen targets add more artifacts.

Alternatives considered: write directly with `FileView.atomicWrites`; invoke
Matugen templates from the shell; implement multi-artifact promotion in QML.

Consequences: an interrupted generation can leave an unpromoted staging
directory, which is harmless derived data and can be cleaned in a later startup
maintenance step. External artifact promotion and compositor application remain
separate contracts; this ADR does not authorize edits to the legacy picker.

Affected areas: `WallpaperService`, `MatugenAdapter`,
`WallpaperPromotionAdapter`, generated QE theme state, and Phase 4 fixtures.

Revisit if: external generated artifacts require cross-filesystem promotion or
an atomic directory-set replacement rather than per-artifact replacement.
