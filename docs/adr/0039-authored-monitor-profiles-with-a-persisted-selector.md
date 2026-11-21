# ADR-039: Authored monitor profiles with a persisted selector

Status: Accepted by user on 2026-09-05; per-monitor scale extension accepted on
2026-09-05

Decision: keep the X1 Carbon's mirrored and four directional extended profiles
authored in Hyprland's `monitors.lua`. QE owns only a versioned selector at
`${XDG_STATE_HOME:-$HOME/.local/state}/qe/monitor-layout.json`. The selector also
stores independent built-in and HDMI scales from the closed set `1.00`, `1.20`,
`1.25`, `1.50`, `1.60`, and `2.00`, derived by filtering a `1.00-2.00` range at
`0.05` precision for values that divide 1920x1080 into whole logical pixels. A
narrow helper validates the closed mode/direction/scale vocabulary, atomically
updates that selector, reloads Hyprland, and verifies the live topology before
reporting success. It rejects unsupported hosts and disconnected configured
outputs. Confirmed
mirror-to-extended transitions restart QE so Qt discovers the newly independent
screen.

Context: an environment variable cannot be reliably changed in Hyprland's parent
process at runtime, so it is not a dependable config-reload selector. Direct
runtime monitor commands would apply immediately but would duplicate the authored
startup profiles and make persistence ambiguous. The requested scope is one
specific built-in output and one secondary output on `jim-x1c`.

Consequences: monitor geometry remains reviewable in the Hyprland configuration;
QE state contains only selection, never monitor commands. The built-in monitor
rule and every non-X1 Carbon host branch remain unchanged unless the user
explicitly selects a new built-in scale. Both scales remain persisted in mirrored
mode, but only the source `eDP-1` scale visibly controls mirrored content, so the
HDMI slider is hidden until Extended is selected. Extended positions use logical
scaled dimensions and remain top-aligned. Version-1 state loads with `1.00` scales
and upgrades on the next accepted write. A failed reload or unconfirmed topology
restores the confirmed pre-operation topology and reconciles the selector rather
than claiming the request as confirmed.
