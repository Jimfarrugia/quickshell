# ADR-026: Notification center as a layer-shell sidebar

Status: Accepted by user on 2026-08-30

Decision: implement a reusable `components/Sidebar.qml` around a Quickshell
`PanelWindow` on the Wayland `WlrLayer.Overlay` layer instead of a normal
Hyprland-managed window. The panel uses ignored exclusive zones,
top/bottom/right anchors, and
20px outer screen margins. Its bottom margin additionally includes the enabled
bottom bar height when the bar is docked at the bottom. Its width is the 384px
notification-card maximum plus the existing 20px content margins. Notification
card layout and styling remain unchanged.

Context: the existing `FloatingWindow` is a normal compositor-managed window,
so its visibility and workspace placement are subject to Hyprland window
behavior. The notification center must overlay normal windows and remain
available while switching workspaces.

Rationale: layer-shell surfaces are compositor-owned panels and are presented
independently of normal workspace window placement. The overlay layer places
the sidebar above normal windows, while ignored exclusive zones prevent it from
altering application layout. Matching the card maximum and existing margins
avoids unnecessary width and preserves the established card presentation.

Consequences: the notification center is Wayland-specific in its overlay
behavior and is no longer represented as a normal Hyprland client. Pointer
interaction remains available without taking keyboard focus. Multi-monitor
placement continues to follow the existing notification surface screen
selection.

Affected areas: `components/Sidebar.qml`, `NotificationCenter.qml`,
notification-center lifecycle tests, and overlay/sidebar validation.

Revisit if: notification-center placement must become configurable per monitor,
or a non-Wayland backend requires an alternate surface implementation.
