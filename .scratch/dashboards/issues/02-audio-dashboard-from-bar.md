# 02: Deliver the Audio Dashboard from the Bar

**What to build:** A complete audio dashboard path from the audio source module to native interactive controls, including current service state, pending operations, degraded states, and the fallback application action.

**Blocked by:** 01: Build the Shared Dashboard Shell and Routing Foundation.

**Status:** ready-for-agent

- [ ] Clicking the audio source module opens and toggles the audio dashboard on the module's monitor and right-side anchor.
- [ ] The header shows the `Audio` feature title and a clickable `settings` icon.
- [ ] Hovering the settings icon shows the feature-specific tooltip `Open pavucontrol`.
- [ ] The settings icon launches `pavucontrol` through the reviewed external-launch boundary.
- [ ] Missing or failed `pavucontrol` launches produce bounded visible errors without closing the dashboard.
- [ ] The dashboard lists output and input devices and supports selecting each default device.
- [ ] The dashboard supports output and input volume changes and mute toggles.
- [ ] The dashboard supports volume and mute controls for common per-application playback streams.
- [ ] Pending requested state is visibly distinct from confirmed PipeWire state.
- [ ] Missing devices, unavailable service state, stale state, device hot-plug, and WirePlumber loss are represented locally without blocking unrelated shell surfaces.
- [ ] Audio integration tests verify controls reconcile from service events and preserve the existing fallback boundary.
