# 04: Complete Dashboard Resilience and Phase 8 Acceptance

**What to build:** Validate the shared shell and audio dashboard as a reliable Phase 8 vertical slice, including environmental failures, alternate bar placement, multi-monitor behavior, and rollback availability.

**Blocked by:** 02: Deliver the Audio Dashboard from the Bar; 03: Add Searchable Launcher Access to Dashboards.

**Status:** ready-for-agent

- [ ] PipeWire event reconciliation keeps confirmed and pending audio state truthful.
- [ ] Device hot-plug and WirePlumber restart behavior completes without stale or misleading controls.
- [ ] Missing integration dependencies, absent devices, stale state, service loss, and fallback launch failure remain local and visible.
- [ ] Bottom-bar, top-bar, no-bar, narrow-output, and 20px margin behavior passes acceptance checks.
- [ ] Source-module monitor placement and active-monitor launcher placement pass multi-monitor checks.
- [ ] Single-dashboard replacement, source-module toggling, Escape dismissal, outside-click dismissal, and lazy recreation pass acceptance checks.
- [ ] `pavucontrol` remains installed and launchable as the unsupported-routing rollback path.
- [ ] The persistent-shell smoke test and documented Phase 8 validation commands pass.
