# 03: Add Searchable Launcher Access to Dashboards

**What to build:** A built-in curated QE launcher action that lets users search for and toggle the audio dashboard alongside applications, using the same public dashboard routing contract.

**Blocked by:** 01: Build the Shared Dashboard Shell and Routing Foundation; 02: Deliver the Audio Dashboard from the Bar.

**Status:** completed

- [x] The launcher exposes a stable, built-in audio dashboard toggle action alongside eligible applications.
- [x] The action has predictable curated metadata and is clearly identifiable as a QE dashboard action.
- [x] Selecting the action toggles the audio dashboard on the active monitor.
- [x] The action routes through the dashboard surface contract rather than constructing or executing arbitrary shell commands.
- [x] Launcher search and selection tests cover discovery, activation, and dashboard visibility behavior.
- [x] The existing display-only help catalog remains unchanged.
