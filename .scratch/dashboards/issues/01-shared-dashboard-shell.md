# 01: Build the Shared Dashboard Shell and Routing Foundation

**What to build:** A reusable dashboard shell and routing contract that can host fixture content and demonstrate the complete transient-surface behavior needed by audio, Bluetooth, and network dashboards.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] A dashboard opens on the requested monitor and derives its horizontal corner from the source module's resolved bar side.
- [ ] The shell follows the bar edge, preserving a 20px gap from the bar and the opposite screen edge, including top-bar and no-bar cases.
- [ ] The shell uses the configured initial width of 1.5 times the Sidebar's total outer width, 20px content insets, and narrow-output constraints.
- [ ] Content-driven height is bounded by the available screen area and oversized content scrolls inside the shell.
- [ ] Only one dashboard can be active; opening another replaces the current one and source-module activation toggles the active dashboard.
- [ ] The surface takes keyboard focus and closes on Escape or outside click.
- [ ] The shell is created lazily, destroyed on close, and reopened from current state.
- [ ] Namespaced dashboard routing exposes `open`, `close`, `toggle`, and `isOpen` without presentation-owned external commands.
- [ ] Integration tests verify the externally observable shell, routing, lifecycle, geometry, focus, and dismissal behavior with fake monitor/bar geometry and fixture content.
