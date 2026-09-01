# 01: Build the Shared Dashboard Shell and Routing Foundation

**What to build:** A reusable dashboard shell and routing contract that can host fixture content and demonstrate the complete transient-surface behavior needed by audio, Bluetooth, and network dashboards.

**Blocked by:** None (can start immediately).

**Status:** completed

Implementation is present in `components/DashboardController.qml`,
`components/DashboardShell.qml`, `integrations/DashboardIpc.qml`, and the bar
module wiring. `tests/qml/dashboard-shell-test.qml` passes the instantiated
shell geometry, controller replacement/toggle, dismissal, and lazy-loading
checks. Runtime IPC and production lazy-loader verification are covered by
`tests/helpers/dashboard-ipc.test.sh` and `tests/qml/dashboard-shell-test.qml`.
Ticket 02 is now the next unblocked task.

- [x] A dashboard opens on the requested monitor and derives its horizontal corner from the source module's resolved bar side.
- [x] The shell follows the bar edge, preserving a 20px gap from the bar and the opposite screen edge, including top-bar and no-bar cases.
- [x] The shell uses the configured initial width of 1.5 times the Sidebar's total outer width, 20px content insets, and narrow-output constraints.
- [x] Content-driven height is bounded by the available screen area and oversized content scrolls inside the shell.
- [x] Only one dashboard can be active; opening another replaces the current one and source-module activation toggles the active dashboard.
- [x] The surface takes keyboard focus and closes on Escape or outside click.
- [x] The shell is created lazily, destroyed on close, and reopened from current state.
- [x] Namespaced dashboard routing exposes `open`, `close`, `toggle`, and `isOpen` without presentation-owned external commands.
- [x] Integration tests verify the externally observable shell, routing, lifecycle, geometry, focus, and dismissal behavior with fake monitor/bar geometry and fixture content.
