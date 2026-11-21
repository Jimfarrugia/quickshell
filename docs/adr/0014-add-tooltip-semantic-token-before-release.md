# ADR-014: Add tooltip semantic token before release

Status: Accepted by user on 2026-08-24

Decision: revise the pre-release theme-v1 contract to require a `tooltip`
semantic color token. Poimandres maps it to the new `palette.black` value
`#171922`; Gruvbox maps it to `palette.blackLight`; the emergency theme provides
an internal dark fallback.

Context: bar hover popups need a deliberate background distinct from general
raised surfaces. Reusing `surfaceRaised` coupled tooltip styling to unrelated
module-hover and elevated-surface decisions.

Rationale: one semantic token lets each authored theme choose tooltip contrast
without presentation code knowing palette names.

Alternatives considered: continue using `surfaceRaised`; hard-code popup colors;
add a bar-specific tooltip color outside the theme contract.

Consequences: runtime validation, JSON Schema, emergency fallback, authored
themes, fixtures, and token documentation require `tooltip`. This remains a
pre-release schema-v1 revision with no shipped migration obligation.

Affected areas: theme schema and validation, `ThemeService`, authored themes,
bar tooltip presentation, fixtures, and future generated-theme mappings.

Revisit if: tooltip surfaces later require separate normal, border, and rich
content tokens.
