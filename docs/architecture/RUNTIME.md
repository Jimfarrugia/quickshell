# Runtime and Lifecycle

Authoritative for QE process topology, persistent-shell and lock lifecycles, transient-surface routing, and runtime diagnostics. Read this file only when a change touches process lifetime, IPC/surface routing, reload/restart behavior, supervision, or logging.

## Runtime Topology

### Persistent shell process

One long-lived Quickshell instance owns:

- the bar
- launcher and help surfaces
- notification server, popups, and process-session history
- notification center and control center
- OSD coordination
- wallpaper and theme selectors
- audio, Bluetooth, and network dashboards
- shared domain services and integration subscriptions
- guarded QE lifecycle actions requested by recovery surfaces
- non-security-sensitive QE IPC

There must be only one persistent QE instance per graphical session. This
prevents duplicate bars, duplicate global shortcut identities, notification
DBus contention, and duplicate external subscriptions.

The canonical persistent-shell entry point is `scripts/run-qe.sh`, which uses
Quickshell's per-configuration instance lock through `--no-duplicate` and the
project-resolved `shell.qml` path. The launcher resolves its own symlink before
finding the managed project checkout. Production startup imports the current
Wayland session environment and asks systemd to restart `qe-shell.service` through
the stable `~/.local/bin/qe-shell --service-start` Hyprland autostart mode; the
unit invokes the same stable XDG user-bin entry point without that option.
Systemd owns journal capture and bounded crash restart.
An explicit `--restart` delegates to the active unit, while an unavailable unit
falls back to the guarded direct restart used for development and recovery.
Direct unguarded `quickshell --path` launches are development-only and can bypass
the single-instance guarantee. Manual direct launches that must survive terminal
closure may pass `--detach`; this starts the guarded shell in a separate session
with terminal hangups ignored.

### Lock process

The lock screen is a separate, minimal, on-demand Quickshell process. It owns:

- one `WlSessionLock`
- one `WlSessionLockSurface` per screen
- its PAM conversation and authentication state
- one read-only native UPower display-device view
- lock-local rendering and input state

It does not import the main shell module graph, notification services,
dashboards, or command adapters. The lock-local UPower view is event-driven,
starts no process, and is omitted from presentation when no laptop battery is
available. The lock reads validated configuration and the last-known-good QE
theme from disk before requesting the lock.

The lock uses `ext-session-lock-v1` through Quickshell. A fullscreen or overlay
window is never an acceptable substitute.

Once the compositor confirms `WlSessionLock.secure`, a process crash leaves the
session securely locked and visually unavailable. Another process cannot
reclaim that lock. The recovery path is compositor/session termination from a
separate TTY. For that reason:

- configuration file watching and soft reload are disabled while locked
- no unauthenticated IPC may unlock the session
- authentication and unlock remain in the process that owns `WlSessionLock`
- the lock process is not automatically restarted after a post-lock crash
- optional process/command integrations are excluded from the lock process

### External processes

The following remain separate boundaries:

- Hyprland and its IPC sockets
- the external theme-switcher project
- Matugen
- the wallpaper application helper
- `brightnessctl` or a later brightness helper
- NetworkManager, BlueZ, PipeWire, WirePlumber, UPower, and PAM
- Rofi for specialized flows that intentionally remain outside the primary QE launcher
- Blueman Manager, `nm-connection-editor`, and `pavucontrol` as supported escape
  hatches for capability scopes QE intentionally does not own

The persistent shell is supervised by a systemd user service triggered from
Hyprland after the compositor environment is imported. The installed Quickshell
0.3.1 crash handler first relaunches a crashed shell child only when its prior
launch survived at least 10 seconds; an immediate repeat crash makes the
Quickshell launcher exit. Systemd then waits two seconds before restarting a
failed launcher and limits starts to three per 60 seconds. This layered policy
prevents a tight crash loop while retaining recovery from both shell-child and
launcher failure. Failures separated by more than Quickshell's 10-second guard
may continue to relaunch and remain visible in the user journal. The separate
lock process is never supervised or automatically restarted.
## Lifecycle

### Persistent shell startup

1. Resolve project and XDG paths.
2. Initialize diagnostics.
3. Load and validate configuration.
4. Load persisted QE state and migrate if needed.
5. Load theme catalog and publish a last-known-good theme.
6. Instantiate enabled domain services and adapters.
7. Create shell surfaces only after safe configuration/theme values exist.
8. Expose IPC endpoints.
9. Report readiness and degraded integrations independently.

Hyprland remains the graphical-session trigger because this system does not
publish an active systemd graphical-session target. It imports `WAYLAND_DISPLAY`,
`HYPRLAND_INSTANCE_SIGNATURE`, and the Hyprland desktop identity before starting
or restarting `qe-shell.service`; optional daemon availability does not
participate in service ordering. Restarting rather than merely starting replaces
any process that survived a compositor restart with one using the new session
environment.

The bar can render with fallback theme and unavailable placeholders while
optional services initialize. Startup does not block on Matugen, network,
Bluetooth, external switcher, or wallpaper generation.

### Reload

Development soft reload must preserve only state explicitly supported by
Quickshell reload mechanisms or persisted QE state. Adapters must not duplicate
subscriptions after reload. Notification handling inspects `lastGeneration`.

Production configuration changes are validated before publication. Application
source reload behavior is not used as a substitute for user configuration
reload.

### Shutdown and crash

- Child processes owned by QE are terminated unless deliberately detached by a
  documented operation.
- Pending operations become unknown/failed on restart and reconcile from live
  subsystem state.
- Process-session notification history is lost by design.
- Generated and persisted files remain valid because writes are atomic.
- Lock-process shutdown without authenticated unlock is never treated as a
  successful unlock.

### Transient surface routing and IPC

`SurfaceService` owns requested visibility for non-security-sensitive transient
QE surfaces. The persistent shell lazily instantiates each surface while its
request is active; presentation objects do not own IPC handlers or duplicate
cross-entry-point visibility state.

Each surface integration owns a separate `IpcHandler` target named
`qe-<surface>`, with consistent typed `open`, `close`, `toggle`, and `isOpen`
methods where those operations apply. Module-local targets preserve independent
lifecycle and failure boundaries and avoid a growing central handler. The theme
selector uses `qe-theme`. These endpoints route intent through `SurfaceService`;
they do not mutate domain state directly. Lock and authentication operations are
never part of this convention.

The control center uses the same convention through the `qe-control-center`
target. Its centered overlay is placed on the compositor's focused output when
opened without a source module. Destination actions close the control center
before opening another major interactive surface, preventing competing exclusive
keyboard-focus surfaces.
## Logging and Diagnostics

Use Qt/Quickshell logging categories by boundary and module. Human-readable logs
include operation IDs, boundary, state transition, duration, and safe error
detail. They exclude passwords, notification private content by default, full
command environments, and unbounded stdout/stderr.

A diagnostics service exposes:

- QE and Quickshell versions
- configuration and state schema versions
- active QE theme and external theme if known
- enabled modules
- integration availability/freshness
- last error per integration
- pending operation summaries
- notification DBus ownership state
- cache/data/state paths

Quickshell encoded logs remain the base persistent log facility. Production
supervision also routes standard output and error to the user journal.

The read-only `qe-doctor` helper reports production command and stable-entry-point
availability, systemd service and single-instance state, notification and tray
DBus ownership, and conflicting retired processes. A missing optional
integration is a warning; a missing required or enabled-feature command,
incorrect owner, duplicate/missing shell, or conflicting retired owner is a
failure. It does not mutate services, packages, configuration, or QE state.
