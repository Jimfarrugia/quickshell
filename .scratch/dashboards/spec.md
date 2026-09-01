# Dashboard Foundation And Audio Dashboard

Status: ready-for-agent

## Problem Statement

QE's audio and network bar modules currently expose live status but do not open
native interactive dashboards. Users need compact, consistent surfaces for
common system controls while retaining existing desktop tools for unsupported
operations. The dashboard design must also establish a reusable foundation for
the later Bluetooth dashboard, network dashboard, and possible control center.

## Solution

Build a shared dashboard shell and an audio dashboard v1. Dashboards are
transient overlay layer-shell surfaces with one active dashboard at a time.
They open beside the source module, follow the bar edge, grow to fit content
within the screen, and scroll internally when content exceeds the available
height. Audio v1 provides native output/input and common stream controls, while
the header's clickable `settings` icon opens `pavucontrol` for unsupported
routing and patchbay work.

## User Stories

1. As a QE user, I want to click the audio bar module to open the audio dashboard, so that common audio controls are immediately available.
2. As a QE user, I want to click the network bar module to use the same dashboard opening contract when the network dashboard is implemented, so that dashboard behavior is predictable across capabilities.
3. As a QE user, I want the audio dashboard anchored to the bottom right when the bar is bottom-docked, so that it appears next to the audio module.
4. As a QE user, I want the network dashboard anchored to the bottom left when the bar is bottom-docked, so that it appears next to the network module.
5. As a QE user, I want dashboard side placement derived from the source module's resolved bar side, so that module reordering remains correct.
6. As a QE user, I want a dashboard opened from a bar module to appear on that module's monitor, so that multi-monitor interaction stays local to the initiating control.
7. As a QE user, I want dashboards opened from launcher actions or a future control center to appear on the active monitor, so that non-module entry points have deterministic placement.
8. As a QE user, I want a 20px gap between the dashboard and the bar, so that the surfaces do not visually touch.
9. As a QE user, I want a 20px gap between the dashboard and the opposite screen edge, so that the surface has balanced breathing room.
10. As a QE user, I want the dashboard relationship to follow a top-docked bar if the bar is moved, so that it appears below a top bar instead of retaining bottom-bar assumptions.
11. As a QE user, I want the dashboard to grow and shrink with its content, so that empty space is minimized.
12. As a QE user, I want an oversized dashboard to stop before the screen edge, so that it never extends beyond the usable bounded area.
13. As a QE user, I want oversized dashboard content to scroll inside the shell, so that all controls remain reachable without breaking placement.
14. As a QE user, I want the dashboard to shrink on narrow monitors, so that it remains usable without horizontal overflow.
15. As a QE user, I want 20px content insets inside the dashboard shell, so that dashboards share the Sidebar's spacing language.
16. As a QE user, I want the initial dashboard shell width to be 1.5 times the Sidebar's total outer width, so that dashboards have enough room for system controls while remaining visually related to the Sidebar.
17. As a QE user, I want dashboard corners to use the same resolved radius as the Sidebar, so that shell surfaces look like one QE family.
18. As a QE user, I want dashboard surface, border, shadow, and opacity styling to follow the Sidebar conventions, so that themes remain coherent.
19. As a QE user, I want only one dashboard open at a time, so that surfaces do not overlap or compete for interaction.
20. As a QE user, I want clicking another source module to replace the current dashboard with that module's dashboard, so that switching capabilities is immediate.
21. As a QE user, I want clicking an already-open source module to close its dashboard, so that the source module acts as a toggle.
22. As a QE user, I want clicking outside the dashboard to close it, so that I can return to the desktop naturally.
23. As a QE user, I want pressing Escape to close the dashboard without affecting the underlying application, so that dismissal is fast and safe.
24. As a QE user, I want an open dashboard to receive keyboard focus, so that Escape and future keyboard-interactive content work reliably.
25. As a QE user, I want dashboards to be created only while visible, so that closed surfaces do not consume unnecessary presentation resources.
26. As a QE user, I want reopening a dashboard to reflect current service state, so that stale closed-surface data is not shown.
27. As a QE user, I want view-local state such as scroll and focus to reset when a dashboard is recreated, so that each opening starts predictably.
28. As a QE user, I want the dashboard header to show the feature title on the left, so that I can identify the active capability.
29. As a QE user, I want a clickable `settings` icon in the header, so that fallback and advanced configuration remains discoverable without adding a large button.
30. As a QE user, I want the settings icon to show a feature-specific hover tooltip beginning with `Open ` and the fallback application's name, so that its purpose is clear.
31. As an audio user, I want to select the default output device, so that audio is routed to the device I choose.
32. As an audio user, I want to select the default input device, so that recording uses the device I choose.
33. As an audio user, I want to adjust output volume, so that I can control listening level from QE.
34. As an audio user, I want to adjust input volume, so that I can control microphone level from QE.
35. As an audio user, I want to mute and unmute output, so that I can quickly silence playback.
36. As an audio user, I want to mute and unmute input, so that I can quickly disable microphone capture.
37. As an audio user, I want to adjust common per-application playback stream volume, so that one application can be quieter or louder than others.
38. As an audio user, I want to mute and unmute common per-application playback streams, so that individual applications can be silenced.
39. As an audio user, I want pending audio changes distinguished from confirmed state, so that I know whether PipeWire has acknowledged my request.
40. As an audio user, I want device hot-plug changes reflected safely, so that newly connected and removed devices do not leave misleading controls.
41. As an audio user, I want a missing output or input section to show an unavailable state instead of disappearing, so that the dashboard explains what is unavailable.
42. As an audio user, I want an audio service failure shown as a local degraded state, so that the dashboard remains understandable and unrelated QE surfaces continue working.
43. As an audio user, I want the `settings` icon to open `pavucontrol`, so that I can access patchbay and unsupported routing controls.
44. As an audio user, I want the dashboard to remain open if `pavucontrol` is unavailable, so that native audio controls are not lost.
45. As an audio user, I want a bounded error if `pavucontrol` fails to launch, so that the failure is visible without destroying my dashboard context.
46. As a QE user, I want an audio dashboard toggle action searchable alongside applications in the launcher, so that I can open it without using the bar.
47. As a QE user, I want dashboard launcher actions to use stable curated metadata, so that their names and behavior are predictable.
48. As a QE user, I want launcher dashboard actions routed through QE surface contracts, so that they do not execute arbitrary shell commands.
49. As a QE user, I want future control-center buttons to use the same dashboard routing contract, so that the control center does not duplicate dashboard ownership.
50. As a QE user, I want the existing help catalog to remain display-only, so that adding executable dashboard actions does not change help semantics.
51. As a QE maintainer, I want audio, network, and future Bluetooth dashboards to share one shell contract, so that later phases can reuse the foundation.
52. As a QE maintainer, I want dashboard feature views to access state only through domain services, so that external integrations remain replaceable and testable.
53. As a QE maintainer, I want dashboard IPC targets such as `qe-audio` and `qe-network` to provide `open`, `close`, `toggle`, and `isOpen`, so that all transient-surface entry points behave consistently.
54. As a QE maintainer, I want service loss and fallback failures to remain local to the affected dashboard, so that one integration cannot block the persistent shell.

## Implementation Decisions

- Build a reusable dashboard shell and feature-specific dashboard content rather than independent complete windows.
- Use an overlay layer-shell surface with ignored exclusive zones; dashboards remain above normal windows and do not reserve application layout.
- Maintain one active dashboard slot. Opening another dashboard replaces the current one; source-module clicks toggle their associated dashboard.
- Derive horizontal anchoring from the source module's resolved bar side. Use the source module's monitor for module launches and the active monitor for other launches.
- Follow the bar edge: 20px between the dashboard and a bottom bar, or between the dashboard and a top bar; keep 20px from the opposite screen edge. Omit the bar contribution when no bar is active.
- Use an initial outer shell width of 1.5 times the Sidebar's total outer width. With current dimensions this is 636px. Keep 20px horizontal content insets and shrink the shell for narrow outputs.
- Grow height with content up to the available screen bounds, then scroll the interior content while retaining the shell/header.
- Match Sidebar surface, border, shadow, opacity, and resolved corner-radius conventions.
- Take exclusive keyboard focus while open. Close on Escape, outside click, or source-module toggle.
- Instantiate dashboard surfaces lazily and reconstruct them from current domain-service state when reopened.
- Provide a shared header with only the feature title and a clickable `settings` icon. The icon opens the feature fallback application and has a tooltip such as `Open pavucontrol`.
- Implement audio v1 with native output/input lists, default-device selection, levels, mute, and common per-application stream volume/mute controls.
- Keep `pavucontrol` as the audio fallback for unsupported routing and patchbay operations.
- Keep feature views dependent on domain services. Do not construct external commands, parse external output, or write shared state from presentation QML.
- Expose one namespaced IPC target per implemented dashboard with `open`, `close`, `toggle`, and `isOpen` methods routed through the shared surface service.
- Add built-in curated dashboard toggle actions as first-class launcher entries alongside applications. Do not expand the display-only help catalog or add arbitrary user-authored executable actions in this phase.
- Keep service availability, freshness, pending operations, and fallback launch failures visible as local degraded states without automatically closing the dashboard.
- Reserve the shared foundation for later network and Bluetooth content without pulling their feature scope into Phase 8.

## Testing Decisions

- Prefer one high-level dashboard-shell integration seam driven by fake domain services and fake monitor/bar geometry. Test externally observable surface behavior rather than QML implementation details.
- Verify source-module side and monitor selection for module-triggered opens, plus active-monitor selection for launcher-triggered opens.
- Verify bottom-bar and top-bar offsets, no-bar behavior, 20px margins, 636px initial width, narrow-output width constraints, content-driven height, and internal scrolling.
- Verify single-dashboard replacement, source-module toggling, outside-click dismissal, Escape dismissal, focus acquisition, and lazy recreation.
- Verify confirmed versus pending service state, service degradation, device absence, hot-plug updates, and daemon restart handling.
- Verify native audio output/input selection, default-device updates, volume/mute controls, common stream controls, and reconciliation from PipeWire events.
- Verify the settings icon opens the fallback application through the reviewed launch boundary, reports missing/failing fallback tools without closing the dashboard, and exposes the feature-specific tooltip.
- Verify the `qe-audio` public IPC methods and the searchable launcher toggle action without testing private object structure.
- Use the existing fake audio integration and QML service-test patterns as prior art. Add fixtures for missing devices, malformed/unavailable state, daemon loss, pending operations, and fallback launch failure.
- Preserve the phase validation requirements for fake-model tests, live audio operations, daemon restart/hot-plug behavior, and pavucontrol rollback availability.

## Out of Scope

- Full PipeWire graph editing or patchbay replacement.
- Unsupported or advanced routing that remains covered by `pavucontrol`.
- Bluetooth dashboard content, including pairing and OBEX behavior.
- Network dashboard content, including enterprise Wi-Fi, VPN, proxy, hidden networks, and full profile editing.
- Control-center composition and its final set of tiles.
- Changing the existing help catalog from display-only to actionable.
- Arbitrary user-authored dashboard commands or executable action definitions.
- Persistent dashboard view state such as scroll position or focus.
- A separate dashboard width per feature.
- A new visual animation language beyond existing QE conventions.
- Lock-screen surfaces or any unlock pathway through dashboard IPC.

## Further Notes

- The current Sidebar total outer width is 424px: 384px content plus 20px on each side. The initial 636px dashboard width is based on that total.
- Audio is the Phase 8 feature and establishes the reusable foundation. Network and Bluetooth source-module routing should remain compatible with the foundation without implementing their dashboard content early.
- The dashboard settings icon is intentionally icon-only visually; its hover tooltip must identify the fallback application using the `Open <application>` wording.
- The phase retains existing fallback applications and must not cut them over until native dashboard acceptance and rollback checks pass.
