# ADR-049: Add the Material surface-container hierarchy

Status: Accepted by user on 2026-09-10

Decision: add `surface_container_lowest`, `surface_container_low`,
`surface_container`, `surface_container_high`, and
`surface_container_highest` as required theme schema-v1 roles. Wallpaper themes
map those roles directly from Matugen's same-named palette colors and map
`surface_hover` from `surface_bright`. Authored themes preserve the requested
HCT hue and chroma of their existing `surface`, apply Material's relative
standard-contrast tone deltas, clamp tone to `[0, 100]`, and store the resulting
sRGB colors as authored palette values. Dark deltas are `-2`, `+4`, `+6`,
`+11`, and `+16` for the ordered container roles and `+18` for hover; light
deltas are `+2`, `-2`, `-4`, `-6`, `-8`, and zero respectively.

Context: components need the complete Material neutral-surface hierarchy without
coupling presentation to raw Matugen palettes. Wallpaper generation already
retains all required source roles, while Poimandres, Gruvbox, and emergency
fallbacks need colors that preserve their existing surface identity. The prior
hover mapping used a materially stronger `surface_variant` color rather than
Matugen's intended bright surface role.

Rationale: direct mappings preserve Matugen authority for generated themes.
Relative HCT tone differences reproduce Material's perceptual elevation spacing
without forcing authored surfaces to Material's absolute T6 or T98 anchors.
Static authored values keep theme loading declarative and avoid adding a runtime
palette generator or package dependency. Material's gamut solver may reduce
realized chroma when the requested HCT color is outside sRGB.

Consequences: the coordinated schema-v1 contract expands from 36 to 41 roles.
Validators, all shipped themes, emergency and lock fallbacks, generated-theme
mapping, fixtures, and tests change together. Existing incomplete custom themes
are rejected. A previously generated runtime `Wallpaper.json` must be
regenerated or restored before deployment; failed generation continues to
preserve the prior last-known-good artifact. ADR-027's independent HSL-derived
`surface_sidebar` and `surface_low` behavior remains unchanged.

Affected areas: theme-v1 schema and validation, authored themes, Matugen mapping,
generated Wallpaper data, emergency fallbacks, lock theme loading, Palette
Viewer output, theme tests, and theme documentation.

Revisit if: independently maintained schema-v1 themes require migration, theme
authors need a maintained palette-generation tool, or a future Material version
changes the standard surface tone model.
