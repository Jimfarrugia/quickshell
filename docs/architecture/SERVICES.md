# Service Contracts

Authoritative for QE domain-service interfaces, ownership, operation semantics, and service-specific degradation rules. For a tactical change, read only the service subsection that owns the affected state or operation.

## Common Service Contract

Every external-facing domain service exposes enough information for a module to
render loading, unavailable, stale, pending, and failed states consistently.
Names may be adapted to QML conventions, but the semantics are mandatory.

```text
availability: unknown | available | unavailable | degraded
freshness: current | stale | unknown
lastUpdated: timestamp or absent
lastError: structured error or absent
operation: idle | pending | succeeded | failed
```

A structured error contains:

- stable QE error code
- boundary name
- user-safe summary
- diagnostic detail
- timestamp
- retryability
- operation identifier where applicable

Services also provide `refresh()` only when explicit refresh is meaningful.
They must not expose raw command stdout as application state.

### ConfigService

Responsibilities:

- load and validate `config/qe.json`
- apply schema defaults
- publish immutable-by-convention configuration properties
- retain last-known-good configuration
- report field-level validation errors

Only `ConfigService` reads user behavior configuration.

### ThemeCatalogService and ThemeService

`ThemeCatalogService` discovers authored and generated themes, validates their
schema, and exposes catalog metadata. Theme files remain authoritative for their
own metadata; any catalog list is derived and must not duplicate editable theme
names or colors.

The authored catalog uses Qt's event-driven `FolderListModel` over `themes/` and
one watched `FileView` per readable, non-hidden JSON file. The schema document is
reserved and excluded. Publication waits for a settled complete candidate set;
malformed entries and every entry participating in a duplicate ID are excluded
with diagnostics. There is no theme-directory poller. Removing or invalidating
the active source leaves `ThemeService`'s last-known-good resolved theme
published and marks it stale until a valid matching source returns.

`ThemeService` owns the active QE theme and application operation:

1. Validate the requested ID and complete theme document.
2. Construct a candidate resolved theme projection containing the authored palette
   and resolved semantic token set.
3. Persist active QE theme state atomically.
4. Publish the theme in one binding-visible change.
5. Invoke the external switcher automatically as a separate best-effort phase.
6. Report external failure as a warning without rolling back QE.

If steps 1-4 fail, the existing QE theme remains active and the external switch
is not attempted.

Concurrent theme requests are serialized. A newer request may cancel an
external phase only if cancellation is safe; otherwise it is queued and stale
results are associated with their operation IDs rather than overwriting current
status.

### WallpaperService

Responsibilities:

- discover and validate wallpaper files through an adapter
- own the selected wallpaper after legacy migration
- request application through a stable helper/IPC contract
- maintain thumbnail cache metadata as derived data
- trigger debounced Matugen regeneration when `Wallpaper` is active
- distinguish selected path, requested path, and externally confirmed state

When `Wallpaper` is active and a wallpaper change succeeds:

1. Generate all Matugen outputs into a per-operation staging directory.
2. Validate the QE theme and required external artifacts.
3. Atomically promote the generated QE `Wallpaper` theme and each safely
   replaceable external artifact through its promotion adapter.
4. Reapply the QE `Wallpaper` theme.
5. Request external `Wallpaper` application as best effort.
6. Keep the previous generated set if generation or validation fails.

### CompositorService

Responsibilities:

- expose the adapter-backed reactive Hyprland workspace model while preserving
  native object lifetime and event updates
- expose the adapter-backed reactive monitor model so topology changes
  reevaluate screen-to-monitor mapping
- resolve a Qt screen to its compositor monitor through the integration adapter
- own monitor-scoped workspace presentation policy, including positive-ID,
  active-or-occupied visibility for the bar
- expose typed operations for workspace focus and window actions
- own Hyprland event subscriptions
- detect disconnection/staleness and refresh only when Quickshell's API requires

`workspaceVisibleOnScreen(workspace, screen)` is the service boundary for the bar's
monitor and visibility decision. Presentation may render scalar workspace state
and pass the adapter-backed workspace object back to `activateWorkspace`, but it
must not traverse nested compositor state to reconstruct monitor ownership or
occupancy policy. Empty workspaces are intentionally omitted from the bar while
remaining reachable through compositor-owned keybindings.

The current Quickshell 0.3.1 workspace model remains adapter-backed rather than a
copied JavaScript record model. This preserves native reactivity and avoids stale
object references across workspace or monitor replacement. A future normalized
model requires a separate decision and stable name-based activation contract.

Raw `Hyprland.dispatch()` strings are confined to the integration adapter.

### AudioService

QE-facing model:

- outputs and inputs
- default/preferred output and input
- volume, channel volumes, mute, availability, and device metadata
- active playback/capture streams when exposed by PipeWire

Operations include set default, set bounded volume, toggle/set mute, and later
stream routing where the native graph API proves sufficient. `PwObjectTracker`
ownership remains inside the adapter. Native PipeWire events confirm all
changes.

### NetworkService

QE-facing model:

- networking and Wi-Fi enabled state
- connectivity state
- devices and connection state
- visible Wi-Fi networks grouped by identity
- saved profile metadata exposed by the native API
- operation progress and failure reason

Initial operations are Wi-Fi toggle, scan through native behavior, connect to a
known network, connect with PSK, disconnect, and forget where supported.
Enterprise/EAP, hidden networks, VPN, proxy, and arbitrary profile editing are
deferred until their secret handling and NetworkManager contracts are designed.

The current network dashboard presents one active device, selected deterministically as connected
Wi-Fi first, then connected wired, then the first suitable device, because
Quickshell 0.3.1 does not expose NetworkManager's default-route device. Wired
controls are read-only. Open and personal PSK profiles may be created or
activated through the native API; retrying a saved PSK may update the
NetworkManager-owned profile, but QE never persists or logs the secret.

Passwords are passed as direct arguments only if the verified native API keeps
them in-process. They must not be interpolated into a shell command, logged, or
persisted by QE.

### BluetoothService

QE-facing model:

- adapters and default adapter
- power, discovery, discoverability, and pairability
- known and discovered devices
- connection, pairing, trust, block, and battery state where available

Operations use native Quickshell Bluetooth methods for connect, disconnect,
pair, cancel, and forget. Quickshell 0.3.1 exposes no pairing agent or
interactive PIN/passkey/confirmation API, so those flows remain available
through the Blueman fallback. Pairing success is confirmed only by BlueZ's
paired/bonded state; a confirmed pair is followed by a connection request.

The bar summary uses the installed `Quickshell.Bluetooth` module and is
read-only. It normalizes the default adapter, powered/transition state, known
and connected devices, aliases, and reported battery values directly from BlueZ
events; it adds no poller and treats controller/daemon loss as unavailable. The
configured bar chip remains visible for that unavailable state and presents the
same disabled/error visual as a powered-off controller, without claiming that
an adapter still exists.
Discovery is user-triggered, stops when its dashboard closes, and is bounded to
30 seconds. Discovered devices are not persisted. The dashboard's Blueman
header action is the explicit fallback for unsupported interactive pairing.

### PowerService and SystemMetricsService

`PowerService` wraps UPower and power-profiles-daemon event-driven state.
Battery state includes UPower's native time-to-full and time-to-empty estimates
in seconds; the domain service selects and formats the estimate appropriate to
confirmed charging state. Zero or invalid estimates are exposed as unavailable,
not as a fabricated duration.
Battery low and critical alerts are derived from those native events in
`OSDService`, using 20% and 15% threshold crossings. Alert latches prevent
repetition while the battery remains below a threshold; charging resets the
latches. A direct transition below 15% emits only the critical alert. There is
no full-battery alert and no battery alert poller. Charging and discharging
status OSDs use the confirmed percentage and the corresponding UPower time
estimate; invalid estimates remain explicitly unavailable. The fully charged
state uses charging semantics for its OSD and omits the time estimate when it is
not available. Discharging status OSDs likewise show only the percentage when
UPower has no valid time-to-empty estimate.

`SystemMetricsService` owns CPU, memory, disk, and temperature reads that lack a
native event API. It uses narrow adapters for `/proc`, `/sys`, and filesystem
statistics. Polling is visible in configuration and diagnostics:

- CPU and memory: 2 seconds while consumed
- thermal data: 5 seconds while consumed
- disk capacity: 30 seconds while consumed
- no polling when no enabled surface consumes the metric, where practical

These intervals passed the existing bar polling budget on the development machine.
Hardware sensors are discovered by stable attributes, not a hard-coded
`hwmon3` path. A bounded structured helper performs thermal discovery once;
subsequent selected-sensor reads use asynchronous `FileView` access until three
failures force rediscovery. Root-disk capacity retains a bounded structured
helper contract with a validated shell/`df` fast path; Python is restricted to
fixture parsing and thermal discovery rather than recurring reads.

### MediaService

Responsibilities:

- normalize MPRIS player metadata and capabilities
- select a current player using documented deterministic policy
- expose guarded play/pause/next/previous/seek operations
- update position only while a consumer is visible and the player is playing

Track lists and playlists are outside the current scope because Quickshell
0.3.1 does not expose them.

### BrightnessService

Quickshell 0.3.1 has no native brightness API. The integration uses a stable helper contract around `brightnessctl`.

The service exposes devices, current percent, pending percent, and bounded set
or step operations. A successful command exit triggers a fresh authoritative
read before confirmed state changes. External changes use a filesystem watcher
if reliable for the active sysfs device; otherwise a documented low-rate poll
is allowed and must mark stale data after missed reads.

The bar implementation uses the helper for backlight discovery and
writes only. While the configured bar consumer is active, the adapter reads the
validated active device's `brightness` and `max_brightness` sysfs files
asynchronously and refreshes `brightness` every 10 seconds because portable
change notifications are not reliable across backlight drivers and external
writers. The poll stops with no consumer. Three failed reads retain the last
confirmed value, mark it stale, discard the invalid device, and retry discovery.
Rapid requests are coalesced by `BrightnessService`; requested values remain
pending until the helper returns a fresh authoritative post-write read. Bar
wheel input changes the latest requested value in bounded five-percent steps.

### NotificationService

After cutover, one `NotificationServer` in the persistent process owns
`org.freedesktop.Notifications`.

The structured owner-watcher helper is bound to the persistent process lifetime
and owns exactly one child DBus monitor. Soft reload, process replacement,
normal exit, and signals must terminate the wrapper and monitor without leaving
orphaned subscriptions.

Responsibilities:

- set supported capabilities deliberately
- track popup and history lifecycle
- handle `lastGeneration` without duplicating notifications on soft reload
- own do-not-disturb policy
- invoke actions, inline replies, dismiss, and expire operations
- sanitize markup and constrain image/resource loading
- remove individual records from current-session history without dismissing the
  underlying notification

History exists only for the current QE process. DND suppresses presentation
according to urgency policy but does not claim notifications were delivered.
Low and normal popup notifications are removed from presentation after five
seconds, while critical notifications remain visible by default. Notifications
with actions hide their popup without expiring the native notification, keeping
sender action endpoints available from history. Explicit dismissal and expiry
remove only the popup from QE history presentation; history is retained
according to the existing transient and history policies. Notification action
controls remain separate from card dismissal.

Notification cards and popups share the same media-first layout and normalized
fallback icon policy. A supplied image is preferred; otherwise OpenCode uses
`robot_2`, critical notifications use `warning`, and low/normal notifications
use `notifications`. Fallback icons use `on_surface_subdued`, except critical
icons, which use the theme error color.

The notification center's DND control is a controlled toggle `IconButton` with
the `do_not_disturb_on` icon. Its state is owned by `NotificationService`.
Toggle buttons retain the regular `IconButton` interaction states. Their
checked state uses `primary_container`/`on_primary_container`, while enabled
off-state controls use the neutral subdued action style. Disabled styling is
reserved for controls that cannot accept an action. Non-toggle buttons retain
the regular `clicked()` behavior.

The notification center also provides a controlled icon-only critical-first
toggle using the `warning` icon. When enabled, it partitions the current and
future view history into critical and non-critical groups while preserving
newest-to-oldest order within each group. When disabled, it restores the
service's original newest-to-oldest history order. The state is view-local and
does not mutate service history, so it resets when the center is recreated.

The notification center keeps one presentation-local keyboard focus identity.
`j` and `k` move between the header and history cards, while `h` and `l` move
between controls within the focused row or card. Enter and Space activate the
focused control, `x` removes the focused history record, and `q` closes the
center. The center's layer-shell surface takes exclusive keyboard focus when it
opens; Escape releases that focus without closing the visible panel. Other
reusable sidebar instances retain their default focus policy. Focused cards are
tracked by notification ID and actions by
identifier so insertion, removal, and critical-first reordering do not redirect
focus to an unrelated record. Card close icons remain pointer-only and are not
part of keyboard navigation.

Initial keyboard focus is the first history card when history is non-empty, or
the first header control otherwise. Vertical navigation always lands on the
card itself; `l` enters its first action and subsequent `h`/`l` movement selects
adjacent actions.

When the notification center is open at its newest position, it clears visible
popups and blocks new popup presentation, including critical notifications.
Scrolling away from the newest position restores popup presentation; returning
to the newest position clears visible popups and blocks presentation again.
This policy does not dismiss tracked notifications or remove eligible history.
When history extends below the viewport, a view-local info pill overlays the
list when one or more history cards are entirely below it. It reports the
number of those cards without changing the list's available viewport or
notification service state. The pill uses `surface_hover` with centered
`on_surface` `keyboard_arrow_down` icon and count, a 1px
`outline` top edge at 30% alpha, and the theme shadow token with a
24px blur when appearance shadows are enabled.

Popup hosting uses the same 20px sidebar margin on the top and screen-facing
right edge, with a matching 20px content inset on the left and below the final
popup. Popup cards are separated by 20px. Popup cards retain a 1px border,
matching the critical notification-center card border.

The notification center uses the reusable `components/Sidebar.qml` Wayland
layer-shell surface, implemented with `PanelWindow` at `WlrLayer.Overlay`, not a
Hyprland-managed normal window. It
ignores exclusive zones, is anchored to the top, bottom, and right screen edges,
and remains visible across workspaces. Its width is the maximum notification
card width plus the existing horizontal content margins; its outer screen
margin matches those content margins, with the bottom margin additionally
including the enabled bottom bar height. The reusable sidebar surface uses the
configured appearance radius plus 2px and the configured border width with the
theme `outline_variant` color, matching the inactive border treatment used by
Hyprland floating windows.

Screenshot capture remains owned by `hyprshot`; the QE wrapper suppresses its
fixed notification and submits each saved image to one per-session persistent
D-Bus notification sender. The sender provides actions to open the captured
image or its containing directory in Thunar with the image selected. The
notification body contains the captured filename, and the sender publishes the
image through the standard `image-path` hint for notification thumbnails.
Action handling remains owned by that sender and does not add
screenshot-specific command parsing to the presentation layer. The sender keeps
the notification resident and keeps its action endpoint alive until the
notification is closed, so popup and history controls can be reused.

### OSDService

OSDs are QE-owned feedback, not synthetic desktop notifications. `OSDService`
coalesces volume, microphone, brightness, media, network, Bluetooth, battery,
and notification-related events into one active presentation slot with
replacement keys and expiry policy. New feedback replaces the active OSD
immediately and restarts expiry; superseded feedback is not replayed.

Hardware-key operations call the relevant domain service. The OSD appears from
confirmed or clearly marked pending state and reports failed operations.
OSD presentation is independent of `NotificationServer`; disabling notifications
does not route OSDs through a desktop notification daemon. OSD values are
bounded and display duration is configuration-controlled. Startup snapshots of
network, Bluetooth, and battery state suppress synthetic initial-change OSDs.

`MediaService` uses the native Quickshell MPRIS model and capability guards; it
does not invoke `playerctl`. `AudioService` owns default PipeWire sink and
source mute/volume actions. `KeyboardBrightnessService` reuses the bounded
brightness adapter with the `leds` class and keyboard-device selection.

### IdleService

`IdleService` owns the compositor `IdleInhibitor` and binds it to a persistent QE
window. Quickshell 0.3.1 exposes only the local `enabled` request and bound
window; it provides no compositor-confirmed active state or failure signal.
`IdleService` therefore exposes requested state only and never presents it as
confirmed external state. The request defaults off when no state exists and is
persisted in versioned QE state. It is released from the compositor when
disabled, when the owner window is lost, or when QE exits; a subsequent QE
process restores the requested state once a bar window is available.
Confirmed-active reporting is deferred until Quickshell
exposes it or QE gains a reviewed native extension. Idle inhibition does not
replace Hypridle's timeout, manual lock, or suspend policy. QE applies no
automatic inhibitor timeout: requested state remains unchanged until the user
toggles it or the configuration/window/process lifecycle forces safe release.

### LauncherService and HelpService

`LauncherService` consumes Quickshell `DesktopEntries`, excludes hidden,
`NoDisplay`, and empty-command entries, applies pure filtering and ranking, and
launches the structured `DesktopEntry.command` with its working directory. For
entries marked `Terminal=true`, it prepends the configured `$TERMINAL` command
and `--` as separate arguments. It does not execute raw desktop `Exec` strings
through a shell. The launcher presentation is a transparent, non-exclusive
`PanelWindow` on the overlay layer for the focused monitor; its content surface
is centered at 35% of the monitor width, sizes to one through six result rows
(with one row as the minimum for empty results), and shrinks from the bottom
while retaining the six-row centered position. It does not reserve screen
space.

Focused-monitor transient `PanelWindow` surfaces leave `screen` unset so
Hyprland's layer-shell placement selects the currently focused output. Do not
derive this placement from `Quickshell.screens`: under Wayland, Qt may expose
fewer `QScreen` objects than Hyprland's IPC monitor list, and falling back to
the first Qt screen can place a surface on the wrong monitor. This applies to
the launcher, help, and control-center surfaces.

When a launch fails, `LauncherService` retains the failed desktop entry separately
from the current selection, and Retry always invokes that retained entry.

Successful launches increment a persisted, QE-owned usage count keyed by stable
desktop-entry ID in `launcher-usage.json` under the XDG state directory. The
versioned document has an `entries` object mapping each ID to a `launchCount`.
The record set is bounded to 512 entries and pruned when IDs disappear.
Empty-query results rank by count, normalized name, and stable ID;
non-empty queries rank search relevance before count and those deterministic
tie-breakers. Search covers normalized name, generic name, keywords, and
comment, using Unicode case-folding, collapsed whitespace, and punctuation as
separators. Persistence failures do not fail launches and are exposed as
bounded diagnostics.

`HelpService` reads the sole user-authored JSON reference catalog. The catalog
contains display-only entries in the `keybindings` and `commands` categories.
Hyprland remains authoritative for actual keybindings; catalog values may
become stale and are never presented as live compositor state. Invalid user
entries are discarded individually while valid entries remain usable. A
malformed or unreadable catalog produces an empty usable catalog and a bounded
diagnostic; there is no repository default merge path.

### Hardware action IPC

The persistent shell exposes typed, non-security-sensitive hardware actions
through the namespaced `qe-actions` IPC target. The stable user-bin
`qe-action` wrapper allowlists those operations and forwards them to the
guarded QE instance. Hyprland remains authoritative for key combinations; its
bindings invoke the wrapper rather than constructing commands for PipeWire,
MPRIS, or brightness state directly. Volume and brightness press/release
bindings share one 250-millisecond repeat timer whose owner is replaced on each
press and cleared on every bound release, leaving the global keyboard repeat
settings unchanged. The single owner prevents opposite-direction timers from
remaining active concurrently. Missing QE makes an action fail visibly without
activating a retired desktop notification service.

### Dashboard surfaces

Dashboards are transient QE surfaces hosted by a shared dashboard shell. The
shell is a transparent, non-exclusive-zone `PanelWindow` on the overlay layer,
with the same surface, border, shadow, opacity, and resolved corner-radius
conventions as `Sidebar.qml`. It remains above normal windows and does not alter
the application layout.

The shell has one active dashboard slot. Opening a dashboard closes or replaces
the current dashboard; clicking its source bar module toggles it closed. Audio
and network source modules determine right and left anchoring through their
resolved bar side, rather than through hardcoded dashboard placement. The shell
follows the bar edge: it sits 20px above a bottom bar or 20px below a top bar,
and stays 20px from the opposite screen edge. If no bar is active, the bar
contribution is omitted. Module-triggered opens use the module's monitor; other
triggers use the active monitor.

The shell width is `1.5` times the Sidebar's total outer width, with
20px horizontal content insets. It shrinks to fit narrow outputs. Height is
content-driven up to the available screen bounds; excess content scrolls inside
the shell. Open dashboards take exclusive keyboard focus and close on Escape,
outside click, or source-module toggle. Surfaces are instantiated lazily and
recreated from current service state when reopened.

The shared header contains the feature title and feature controls. The
clickable `settings` icon opens the feature's fallback application and exposes a
feature-specific hover tooltip such as `Open pavucontrol`. The AI quota header
also exposes a `refresh` control that requests one quota refresh cycle and is
disabled while that cycle is pending. Audio v1 owns native
output/input selection, default-device state, levels, mute, and common stream
volume/mute controls. Unsupported routing remains delegated to `pavucontrol`.

Dashboard content depends on domain services only. Service loss, missing
devices, stale state, and fallback-launch failures remain visible as local
degraded states without closing the dashboard or blocking unrelated surfaces.
Each implemented dashboard exposes the standard namespaced IPC target
(`qe-audio`, `qe-network`, and so on) with `open`, `close`, `toggle`, and
`isOpen`; launcher entries are built-in curated QE actions and the help catalog
remains display-only.

### Control center

The control center is a separate transient composition surface, not a dashboard
slot. It is hosted by a full-output overlay `PanelWindow` with a centered panel,
exclusive keyboard focus, and no exclusive zone. `SurfaceService` owns its
visibility and `qe-control-center` owns its typed IPC endpoint. Opening the
control center closes other major interactive surfaces; selecting a dashboard,
notification center, selector, or power menu closes the control center before
the destination opens.

The surface binds to existing domain services for Wi-Fi, Bluetooth, DND, idle
inhibition, audio, themes, wallpaper, and notifications. It does not construct
commands, parse output, or write shared state. Wi-Fi and Bluetooth tiles expose
the existing network and Bluetooth dashboards as their detailed views. Volume
and microphone wheel changes use the audio service's confirmed/pending model.

The control center uses two explicitly scoped command boundaries: a
power-menu adapter that launches the existing `rofi_power_menu` interactive
program, and a defaults adapter that launches the project-owned
`qe-defaults capture|restore` helper.
The former does not expose direct session power actions. The latter is serialized,
bounded, confirmation-gated, and reports timeout outcomes as potentially partial.

`MonitorLayoutService` owns the control center's X1 Carbon monitor-layout state.
The authored `jim-x1c` profiles remain in Hyprland's `monitors.lua`; the service's
narrow helper persists only a versioned `mirror|extended` selector and the last
`left|up|right|down` extension direction plus independent per-output scales under
the XDG state directory. For the configured 1920x1080 modes, scale selection is
limited to `1.00`, `1.20`, `1.25`, `1.50`, `1.60`, and `2.00`; each divides both
dimensions into whole logical pixels. Directional positions are derived from the
scaled logical dimensions so adjacent output edges remain aligned. Applying a
profile requires both `eDP-1` and `HDMI-A-1`, reloads Hyprland, and publishes
success only after `hyprctl monitors all -j` confirms topology and both scales.
Invalid input, unsupported hosts, a disconnected secondary output, reload failure,
and unconfirmed topology fail locally. Other host branches and the X1 Carbon's
built-in monitor rule are unchanged. Mirror-to-extended transitions restart QE
after confirmation because Qt may not otherwise discover the newly independent
screen. Mirror confirmation accepts Hyprland's numeric monitor-ID `mirrorOf`
representation and the output-name representation used by older fixtures.
Version-1 selector documents remain readable with `1.00` scale defaults and are
written as version 2 on the next accepted change. Malformed version-2 scale data
falls back to the complete default profile rather than partially applying state.
In mirrored mode, `eDP-1` is the source logical layout. The HDMI scale remains
persisted for the next extended layout but its slider is hidden because changing
that field does not visibly rescale mirrored content. Unequal logical output
sizes remain top-aligned; pointer crossing exists only along their shared virtual
edge. The service re-queries after `monitoradded`/`monitorremoved` Hyprland events
(debounced through the `CompositorService` topology signal) so the control center
reflects secondary-output connect/disconnect without being reopened; this is
event-driven and is not polling. When the primary output is absent, monitor
layout is unavailable. When only the secondary output is absent, only the
primary scale may be changed.

### AI quota service

`AiQuotaService` owns the normalized quota projection for OpenAI Codex/ChatGPT
and OpenCode Go. `AiQuotaAdapter` owns the bounded helper process, sequential
provider eligibility, and per-provider retry/backoff state. The helper owns the
HTTPS requests, provider response parsing, and read-only credential lookup. The
service exposes independent `fiveHour` and `weekly` windows for each
provider and an additional `monthly` window for OpenCode Go. Each exposed
window has remaining/used percentages, reset time, availability, freshness,
and a safe error record.

The helper reads OpenCode's `${XDG_DATA_HOME:-$HOME/.local/share}/opencode/auth.json`
as the unprivileged desktop user and maps the `opencode-go` record to the
OpenCode Go provider. QE never writes, refreshes, removes, or
migrates that file. Expired OpenAI OAuth access is unavailable until OpenCode
refreshes its own credential. Tokens, account identifiers, headers, raw upstream
responses, and refresh tokens never enter QML state, process arguments,
diagnostics, logs, fixtures, or QE state.

Quota data is consumer-scoped polling because the provider endpoints have no
usable event source. The adapter also subscribes to systemd-logind's
`PrepareForSleep` signal through `dbus-monitor` while a consumer exists and the
service starts an immediate refresh after the resume event. A pre-sleep event
cancels an in-flight helper without recording a provider failure; a resume
request is coalesced and starts only after cancellation has completed. One
singleton adapter operation serves all bars and the dashboard; a sequential
provider refresh cycle remains one logical pending operation between helper
processes. Requests arriving during a cycle are coalesced, with manual and
resume requests taking precedence over polling. Manual refresh may retry a
QE-generated timeout or network backoff once, but never bypasses a provider
rate-limit or its `Retry-After` deadline. Polling and the resume watcher stop
when no consumer remains. Provider or window failure does not block shell
startup or hide unrelated confirmed data.
