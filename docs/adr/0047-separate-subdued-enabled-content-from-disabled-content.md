# ADR-047: Separate subdued enabled content from disabled content

Status: Accepted by user on 2026-09-09

Decision: add the required `on_surface_subdued` role to theme schema version 1.
It represents enabled lower-emphasis text and meaningful icons on QE's ordinary
neutral surface family. Preserve `on_surface_variant` as the foreground paired
with `surface_variant`, reserve `on_surface_disabled` for genuinely unavailable
controls, and use outline roles for boundaries. Reusable action controls own the
mapping from semantic tone, emphasis, and interaction state to theme roles;
modules do not request component-specific colors. Checked controls use
`primary_container`/`on_primary_container`, while status colors retain confirmed
success, warning, and error meanings.

Context: production QML used `on_surface_disabled` extensively for ordinary
enabled buttons, metadata, bar content, icons, and borders. That made the same
control appear disabled under Poimandres but prominent under generated Wallpaper
themes. The contract also had no unambiguous role for enabled subdued content:
QE's accepted paired-role semantics make `on_surface_variant` content for
`surface_variant`, not a generic alternate `on_surface`. The user confirmed that
there are no external QE theme-v1 documents requiring compatibility.

Rationale: component-specific roles such as `button_default` would make every
theme depend on QE's component inventory and repeat interaction policy in theme
files. One reusable semantic role plus component-owned state composition fixes
the demonstrated gap while preserving authored palette identity. Roles may
share colors where appropriate; uniqueness is not a conformance requirement.

Consequences: schema, validators, authored and generated themes, emergency
fallbacks, lock fallback, fixtures, and consumers change atomically while
remaining schema version 1. Gruvbox gains one canonical neutral needed for a
text-safe pressed surface. Matugen maps subdued, placeholder, and disabled
content separately. A general palette generator and paired filled-status roles
remain deferred until a concrete contrast requirement demonstrates their need.

Affected areas: theme-v1 contract, `ActionButton` and action-control
specializations, authored themes, Matugen mapping, generated Wallpaper theme,
presentation consumers, lock fallback, validation, and theme documentation.

Revisit if: an implemented filled status surface requires a guaranteed
foreground pair, an authored palette cannot satisfy the documented contrast
matrix without derived colors, or external QE theme documents require a
versioned migration.
