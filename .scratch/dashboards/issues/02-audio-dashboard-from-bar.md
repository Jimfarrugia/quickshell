# 02: Deliver the Audio Dashboard from the Bar

**What to build:** A complete audio dashboard path from the audio source module to native interactive controls, including current service state, pending operations, degraded states, and the fallback application action.

**Blocked by:** 01: Build the Shared Dashboard Shell and Routing Foundation.

**Status:** completed

Implemented in `modules/audio/AudioDashboard.qml`, `services/AudioService.qml`,
and `integrations/PipewireIntegration.qml`. Fixture coverage is in
`tests/qml/audio-dashboard-test.qml`.

- [x] Clicking the audio source module opens and toggles the audio dashboard on the module's monitor and right-side anchor.
- [x] The header shows the `Audio` feature title and a clickable `settings` icon.
- [x] Hovering the settings icon shows the feature-specific tooltip `Open pavucontrol`.
- [x] The settings icon launches `pavucontrol` through the reviewed external-launch boundary.
- [x] Missing or failed `pavucontrol` launches produce bounded visible errors without closing the dashboard.
- [x] The dashboard lists output and input devices and supports selecting each default device.
- [x] The dashboard supports output and input volume changes and mute toggles.
- [x] The dashboard supports volume and mute controls for common per-application playback streams.
- [x] Pending requested volume and mute state is visibly distinct from confirmed PipeWire state.
- [x] Missing devices and unavailable service state are represented locally without blocking unrelated shell surfaces.
- [x] Audio fixture tests verify node grouping, pending reconciliation, stale/service-loss handling, hot-plug updates, native controls, and fallback launch failure while the existing fallback boundary remains available.
