# ADR-027: Dedicated sidebar surface token

Status: Accepted by user on 2026-08-30

Decision: add `surface_sidebar` as a required semantic theme token and make the
reusable `components/Sidebar.qml` consume it by default. Poimandres uses its
`palette.black` color with alpha `f5` (`#f5171922`). Gruvbox adds
`palette.sidebar` as `#1d2021` and uses the corresponding alpha color
`#f51d2021`. The generated wallpaper theme derives its sidebar source color by
reducing the Matugen background's HSL lightness by 9/255 while preserving hue
and saturation, then applies the existing captured opacity.

Context: `surface_panel` is shared by bars, selectors, and panels, while the
sidebar needs a distinct darker surface. Matugen's optional `surface_container*`
colors do not guarantee the required relationship across variants.

Rationale: a schema-wide semantic role keeps normal components independent of
raw palette names. The measured HSL delta matches the requested Gruvbox
separation without imposing Gruvbox's cool tint on generated wallpaper themes.

Consequences: the theme-v1 contract expands from 32 to 33 roles. Runtime
validation, JSON Schema, emergency fallback, authored themes, fixtures, the
generated wallpaper artifact, and theme tests must be updated together.

Affected areas: `components/Sidebar.qml`, `utils/Matugen.mjs`, theme schema and
validation, authored and generated themes, and theme/QML validation.

Revisit if: generated wallpaper palettes need a user-configurable sidebar
darkening amount or a distinct sidebar foreground role.
