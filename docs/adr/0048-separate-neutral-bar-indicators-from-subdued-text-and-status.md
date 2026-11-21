# ADR-048: Separate neutral bar indicators from subdued text and status

Status: Accepted by user on 2026-09-09

Decision: add the required `on_surface_indicator` role to theme schema version
1. It represents enabled neutral compact indicators and iconographic content on
QE's ordinary neutral surfaces. Bar text uses `on_surface_subdued`, while normal
bar icons and tray tint use `on_surface_indicator`. The SSID and clock time keep
their deliberate `primary` styling. Domain state overrides use stable meanings:
Bluetooth connected uses `success`; mute, DND, and stale data use `warning`;
idle inhibition and pending intent use `primary`; confirmed failures and
critical conditions use `error`; and non-critical charging uses `charging`.
Network connectivity and workspace focus remain neutral, while urgent
workspaces use `warning`.

Context: ADR-047 correctly removed `secondary` and status colors from generic
action selection, but the first consumer migration also erased useful domain
state distinctions and made ordinary bar icons inconsistent with tray tint.
`secondary` happened to provide the desired optical hierarchy in Poimandres but
does not guarantee greater prominence than subdued content across themes. The
user requires ordinary icons to remain slightly more prominent than bar text
without changing the intentional primary SSID and clock aesthetic.

Rationale: `on_surface_indicator` describes a reusable content role rather than
a component-specific `bar_icon` skin. It lets each authored or generated theme
control neutral icon prominence without misrepresenting an accent family as a
luminance tier. Status colors remain valid for confirmed domain meaning; they
are prohibited only as arbitrary styling or aliases for generic checked state.

Consequences: all themes, Matugen mapping, fixtures, emergency fallbacks, lock
fallback, bar modules, tray tint, validation, and tests change atomically while
remaining schema version 1. Matugen maps indicator content from `on_surface` and
subdued content from `on_surface_variant`. Critical/error state takes precedence
over stale, pending, charging, success, active, and neutral presentation. The
blanket source prohibition on module-level disabled roles is removed; genuine
unavailability remains allowed and behavior-tested.

Affected areas: theme-v1 contract, bar and tray presentation, authored themes,
Matugen mapping, generated Wallpaper theme, lock fallback, validation, and
theme documentation.

Revisit if: a non-bar compact indicator demonstrates different semantics, a
light theme cannot provide both roles with required contrast, or repeated state
precedence logic warrants a shared bar-state resolver.
