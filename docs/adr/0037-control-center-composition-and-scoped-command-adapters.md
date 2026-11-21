# ADR-037: Control-center composition and scoped command adapters

Status: Accepted by user on 2026-09-04

Decision: the control center is a separate centered overlay surface owned by
`SurfaceService`, rather than a dashboard slot or a floating application window.
It is placed on the focused output, takes exclusive keyboard focus while open,
and replaces other major interactive transient surfaces when navigating. Its
quick-setting tiles compose existing domain services and open existing dashboards
for detailed operations.

Clarification: replacement applies to competing QE layer-shell surfaces with
exclusive keyboard-focus behavior. Hyprland-managed normal application windows
remain open behind the control-center overlay. Explicit destination navigation
remains replacement-based and closes the control center before opening the
destination.

Phase 11 also approves two narrow external boundaries needed by the requested
controls: launching the existing `rofi_power_menu` program and launching the
project-owned `scripts/qe-defaults capture|restore` helper. These are typed
adapters with bounded state and errors; QML does not construct commands or parse
their output. The power adapter exposes only the existing interactive menu, not
direct logout, lock, reboot, suspend, or shutdown operations. Defaults capture
and restore require explicit in-panel confirmation, serialize operations, and
report timeout outcomes as potentially partial.

Context: the control center must compose established capabilities while retaining
the existing fallback tools and avoiding a broad command-execution service. The
two command helpers already exist as user-facing project contracts, but neither
previously had a presentation-facing typed API.

Consequences: the control center has independent lifecycle and failure handling;
one unavailable service does not block unrelated tiles. The microphone receives a
dedicated volume projection in `AudioService`, and `TimeService` exposes a long
localized date while retaining compact bar text. `Super+Tab` opens the new surface;
the existing `Super+Escape` Rofi binding is unchanged.
