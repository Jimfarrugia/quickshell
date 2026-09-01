# 04: Complete Dashboard Resilience and Phase 8 Acceptance

**What to build:** Validate the shared shell and audio dashboard as a reliable Phase 8 vertical slice, including environmental failures, alternate bar placement, multi-monitor behavior, and rollback availability.

**Blocked by:** 02: Deliver the Audio Dashboard from the Bar; 03: Add Searchable Launcher Access to Dashboards.

**Status:** completed

Acceptance evidence: the audio, dashboard shell, launcher-action, and dashboard
IPC fixtures pass; full-repository `qmllint` passes; the persistent shell remains
alive under the documented smoke timeout; and `/usr/sbin/pavucontrol` is
installed and launched successfully. The fixture model covers PipeWire event
reconciliation, service loss, stale state, hot-plug, geometry, routing,
dismissal, and lazy recreation. Manual device checks confirmed that inserting
3.5mm headphones produces a confirmed volume update, while connecting a
Bluetooth headset discovers the device and changes both the default input and
output in the dashboard. The subsequent approved manual check restarted
`wireplumber.service`, confirmed it returned to `active (running)`,
and confirmed PipeWire repopulated the built-in and Bose audio nodes. The
WirePlumber Lua-configuration migration and missing-libcamera messages were
unrelated to audio-dashboard recovery.

- [x] PipeWire event reconciliation keeps confirmed and pending audio state truthful.
- [x] Device hot-plug and WirePlumber restart behavior completes without stale or misleading controls.
- [x] Missing integration dependencies, absent devices, stale state, service loss, and fallback launch failure remain local and visible.
- [x] Bottom-bar, top-bar, no-bar, narrow-output, and 20px margin behavior passes acceptance checks.
- [x] Source-module monitor placement and active-monitor launcher placement pass multi-monitor checks.
- [x] Single-dashboard replacement, source-module toggling, Escape dismissal, outside-click dismissal, and lazy recreation pass acceptance checks.
- [x] `pavucontrol` remains installed and launchable as the unsupported-routing rollback path.
- [x] The persistent-shell smoke test and documented Phase 8 validation commands pass.
