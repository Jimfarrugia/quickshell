# ADR-031: Launcher uses a centered overlay panel

Status: Accepted by user on 2026-09-01

Decision: the launcher uses a transparent, non-exclusive `PanelWindow` on the
overlay layer for the focused monitor. Its visible surface is centered, is 35%
of the monitor width, and sizes to one through six result rows. Empty results
use the one-row minimum. The top edge is positioned from the six-row centered
baseline, so shorter states shrink from the bottom. It does not reserve screen
space for normal windows.

Context: the launcher must consistently overlay normal windows and remain
usable across monitor sizes without depending on compositor-managed floating
window placement. Showing six rows without a fixed-height empty area keeps the
surface compact for short result sets.

Consequences: the panel host spans the selected monitor, while the styled
launcher surface remains centered within it. The panel takes exclusive keyboard
focus only while visible and uses the existing launcher lifecycle to destroy or
hide the surface.

Affected areas: launcher presentation, focused-monitor placement, and Phase 7
manual overlay validation.
