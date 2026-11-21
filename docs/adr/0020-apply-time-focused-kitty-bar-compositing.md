# ADR-020: Apply-time focused Kitty bar compositing

Status: Not explicitly stated in source record

Context: generated wallpaper themes used a fixed QE panel alpha and Matugen's
surface color, while Kitty separately applied its background opacity and
Hyprland applied window opacity. This made the generated bar visibly differ
from a focused Kitty window, especially for automatically generated palettes.

Decision: when generating the wallpaper theme, QE captures Kitty's effective
`background_opacity` and queries Hyprland's live
`decoration:active_opacity`. The generated `surface_panel` uses the Matugen
wallpaper background with the product of those values as its alpha. Kitty and
Hyprland remain the owners of their settings; QE does not introduce a shared
opacity setting or runtime watchers. Missing configuration files, missing
settings, unavailable IPC, malformed values, and out-of-range values use full
opacity (`1.0`). A later upstream change is reflected when the wallpaper theme
is next generated or applied.

Rationale: this matches the requested focused-window appearance without
polling or duplicating Kitty configuration. Applying the alpha to the bar is
necessary because Hyprland window opacity does not automatically apply to the
QE layer surface.

Alternatives considered: watching both configuration sources (unnecessary
runtime work and more lifecycle complexity); adding a QE-owned Kitty opacity
setting (creates competing ownership); using the Matugen surface token (does
not match Kitty's terminal background).

Consequences: an already-generated theme can remain stale after an upstream
opacity edit until the next wallpaper-theme application. Kitty include files
are resolved by the bounded helper, while Hyprland is queried from the live
compositor rather than assuming a config filename or syntax.

Affected areas: `MatugenAdapter`, `Matugen.mjs`, `Opacity.mjs`,
`qe-window-opacity.sh`, generated wallpaper themes, and validation fixtures.

Revisit if: Kitty or Hyprland expose a stable native event/API that makes
live synchronization valuable, or if the bar must match inactive windows too.
