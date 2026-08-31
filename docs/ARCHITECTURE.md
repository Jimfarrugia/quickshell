# QE Architecture

Status: Current architecture implemented through Phase 6; remaining planned
surfaces and deployment choices are tracked in `docs/PLAN.md`

This document is the authoritative description of the Quickshell Environment
(QE) architecture, ownership boundaries, runtime topology, and service
contracts. `docs/PLAN.md` is authoritative for roadmap, sequence, project status,
active/future phase scope, risks, and polling policy. `docs/DECISIONS.md` is the
authoritative architectural decision log. `AGENTS.md` defines how implementation
agents select the minimum relevant documentation for a task.

## 1. Scope

QE is a cohesive desktop-shell platform for Hyprland on Arch Linux. It is not a
set of unrelated widgets. Shared configuration, state, themes, lifecycle,
diagnostics, IPC, and failure behavior are platform responsibilities.

## 1.1 Documentation Governance

Documentation has deliberately separate authority domains:

- `docs/ARCHITECTURE.md` is authoritative for current architecture, ownership,
  boundaries, runtime topology, service contracts, lifecycle, failure, and
  security policy.
- `docs/PLAN.md` is authoritative for roadmap, project status, active/future
  phase scope, prerequisites, acceptance criteria, risks, deferred work, and
  polling policy.
- `docs/DECISIONS.md` is the authoritative architectural decision log and
  rationale. Accepted ADRs remain there unless explicitly superseded or revised.
- `docs/VALIDATION.md` is the developer validation catalogue and expected-result
  reference.
- `docs/history/` preserves old inventories, completed implementation records,
  rollback evidence, and superseded working context. Historical files are
  non-authoritative for current behavior and are not default agent reading.
- `docs/USER_GUIDE.md` is concise, user-facing, and non-authoritative for project
  status. It must not receive new or updated content without explicit user
  approval. Agents and maintainers may suggest additions or corrections, but
  must obtain approval before applying them.

Authority does not imply mandatory context. `AGENTS.md` defines selective reading
rules so implementation agents load only the live plan sections, architecture
sections, ADRs, and validation material relevant to the task.

If authoritative documents conflict, the conflict must be resolved explicitly;
agents must not infer a precedence rule and silently choose one.

The architecture must support incremental replacement of Waybar, Hyprlock,
Rofi, Dunst, Blueman Manager, `nm-connection-editor`, and `pavucontrol` without
requiring all replacements to ship together.

### Goals

- Maintain clear ownership of every shared value and external subscription.
- Keep presentation independent from system-specific commands and output.
- Prefer event-driven Quickshell, Qt, Wayland, DBus, and IPC APIs.
- Isolate optional integrations so one failure does not disable unrelated QE
  features.
- Support project-relative deployment without source changes; the final
  production location remains a Phase 12 decision.
- Make external operations observable, bounded, and independently testable.
- Preserve a safe rollback path while replacing existing desktop tools.

### Non-goals

- Supporting compositors other than Hyprland in the initial architecture.
- Building a general-purpose desktop environment or settings daemon.
- Reimplementing NetworkManager, BlueZ, PipeWire, WirePlumber, UPower, PAM, or
  the notification specification.
- Providing complete enterprise networking, VPN, OBEX transfer, or advanced
  PipeWire graph editing in the first dashboard versions.
- Persisting notification history in the initial release.
- Guaranteeing atomic theme application across unrelated applications that do
  not expose transactional configuration APIs.

## 2. Architectural Principles

### 2.1 One owner per independently editable value

A single source of truth is the one component or external subsystem authorized
to define a value. Other representations are projections, caches, pending
requests, or generated artifacts and must be labeled as such.

Two similar values may have separate owners only when they represent
intentionally separate scopes. QE's active theme and the external desktop's
active theme are intentionally independent. They are not duplicated copies of
one value.

### 2.2 Dependencies point toward external systems

The required dependency direction is:

```text
entry points and modules
    -> reusable components
    -> QE domain services
    -> integration adapters
    -> Quickshell/Qt APIs, files, IPC, commands, and external systems
```

Presentation may bind to domain service state and invoke domain operations. It
must not construct commands, parse command output, write shared state files, or
own external subscriptions.

Domain services normalize state, coordinate operations, and expose stable
QE-facing contracts. They must not contain layout or window-specific behavior.

Integration adapters encapsulate one external boundary each. They translate
native or external representations into domain data and report health and
errors. They must not decide presentation policy.

### 2.3 Declarative QML first

- QML owns presentation, bindings, animations, interaction handling, Qt object
  lifetime, and long-lived reactive services.
- JavaScript modules contain pure formatting, validation, filtering, sorting,
  and transformation functions only.
- External scripts are allowed only for functionality that lacks a suitable
  native API, must run independently of QE, or performs substantial process or
  filesystem orchestration.
- Imperative QML remains small and coordinates objects rather than becoming an
  unstructured business-logic layer.

### 2.4 Confirmed state is distinct from requested state

Every mutating service operation follows this model where applicable:

```text
confirmed state -> requested operation -> pending desired state
    -> external acknowledgement/update -> new confirmed state
    -> or timeout/error -> retain/reload confirmed state
```

UI may display pending intent, but it must not present intent as confirmed live
state. Native subsystem events remain authoritative after an operation.

### 2.5 Degradation is local

The core process may start when optional dependencies are missing. Each adapter
reports availability and staleness. A failed Bluetooth adapter must not block
the bar, audio, launcher, or lock process. Security-critical lock failures are
handled separately and never fail open.

## 3. Runtime Topology

### 3.1 Persistent shell process

One long-lived Quickshell instance owns:

- the bar
- launcher and help surfaces
- notification server, popups, and process-session history
- notification center and control center
- OSD coordination
- wallpaper and theme selectors
- audio, Bluetooth, and network dashboards
- shared domain services and integration subscriptions
- non-security-sensitive QE IPC

There must be only one persistent QE instance per graphical session. This
prevents duplicate bars, duplicate global shortcut identities, notification
DBus contention, and duplicate external subscriptions.

The canonical persistent-shell entry point is `scripts/run-qe.sh`, which uses
Quickshell's per-configuration instance lock through `--no-duplicate` and the
project-resolved `shell.qml` path. The launcher resolves its own symlink before
finding the project, and production autostart invokes it through the stable XDG
user-bin path `~/.local/bin/qe-shell`. Direct unguarded `quickshell --path`
launches are development-only and can bypass the single-instance guarantee.
Manual launches that must survive terminal closure may pass `--detach`; this
starts the guarded shell in a separate session with terminal hangups ignored.

### 3.2 Lock process

The lock screen is a separate, minimal, on-demand Quickshell process. It owns:

- one `WlSessionLock`
- one `WlSessionLockSurface` per screen
- its PAM conversation and authentication state
- lock-local rendering and input state

It does not import the main shell module graph, notification services,
dashboards, or command adapters. It reads validated configuration and the
last-known-good QE theme from disk before requesting the lock.

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
- optional integrations are excluded from the lock process

### 3.3 External processes

The following remain separate boundaries:

- Hyprland and its IPC sockets
- the external theme-switcher project
- Matugen
- the wallpaper application helper
- `brightnessctl` or a later brightness helper
- NetworkManager, BlueZ, PipeWire, WirePlumber, UPower, and PAM
- Rofi and Hyprlock until their documented replacements complete
- Blueman Manager, `nm-connection-editor`, and `pavucontrol` as dashboard
  fallbacks until their supported replacement scopes complete

Production supervision is deferred. Development launch and process identity
must not assume either Hyprland autostart or a systemd user service. A later
decision may select supervision without changing entry points or service
contracts.

## 4. Proposed Project Structure

```text
.
|-- shell.qml                  # persistent process entry point
|-- lock.qml                   # isolated lock process entry point
|-- components/               # reusable presentation primitives
|-- modules/                  # user-facing feature composition
|   |-- bar/
|   |-- launcher/
|   |-- notifications/
|   |-- controlcenter/
|   |-- osd/
|   |-- audio/
|   |-- bluetooth/
|   |-- network/
|   |-- help/
|   |-- wallpaper/
|   `-- theme/
|-- lock/                     # lock-only UI and authentication coordination
|-- services/                 # QE domain singletons
|-- integrations/            # external boundary adapters
|-- config/
|   |-- qe.json               # user-authored configuration
|   `-- schema/               # documented/versioned schemas
|-- themes/                   # user-authored QE theme JSON files
|-- utils/                    # pure JavaScript transforms
|-- scripts/                  # stable external helpers only
|-- tests/
|   |-- fixtures/             # adapter inputs and malformed-data cases
|   |-- js/                   # JavaScript tests
|   |-- helpers/              # shell/helper contract tests
|   `-- qml/                  # QML/Qt tests
|-- docs/
|   |-- ARCHITECTURE.md
|   |-- PLAN.md
|   |-- DECISIONS.md
|   |-- VALIDATION.md
|   |-- USER_GUIDE.md
|   `-- history/               # non-authoritative completed/historical records
|-- .opencode/
|   |-- commands/
|   |   `-- docs-maintain.md
|   `-- skills/
|       `-- qe-doc-maintenance/
|           `-- SKILL.md
`-- AGENTS.md
```

The split between `components/` and `modules/` is intentional:

- `components/` contains reusable visual controls with no feature orchestration.
- `modules/` composes windows, panels, popups, and feature-specific views from
  components and services.

### Directory dependency rules

| Directory       | May depend on                                             | Must not depend on                                           |
| --------------- | --------------------------------------------------------- | ------------------------------------------------------------ |
| Entry points    | modules, services, integrations for assembly              | feature internals not needed by that process                 |
| `components/`   | QtQuick, theme facade, explicit input properties          | integrations, external commands, shared mutable state        |
| `modules/`      | components, services                                      | raw command construction, direct shared-file writes          |
| `services/`     | integrations, pure utilities                              | windows, layout, module delegates                            |
| `integrations/` | Quickshell/Qt APIs, external contracts                    | presentation policy, feature layouts                         |
| `utils/`        | no stateful QML objects                                   | Qt object ownership, process ownership, mutable global state |
| `scripts/`      | documented external tools                                 | presentation assumptions, undocumented stdout consumed by UI |
| `lock/`         | lock-safe theme/config readers, PAM, Wayland session lock | persistent shell services and nonessential adapters          |

Circular dependencies are prohibited. A shared concern is promoted to a domain
service only when at least two modules need it or it owns long-lived external
state. Feature-local state remains in the module.

## 5. Configuration and Paths

### 5.1 User-authored configuration

`config/qe.json` is the only user-authored QE behavior/configuration source.
The initial schema contains:

- schema version
- enabled modules and feature flags
- bar placement and per-monitor policy
- module ordering and presentation preferences
- typography, spacing, radius, border, opacity, shadow, and animation settings
- bounded command timeouts and executable overrides
- system metric polling intervals
- notification and OSD behavior
- dashboard feature options

Behavior defaults live in the schema-aware `ConfigService` implementation and apply only
when a key is absent. They are not separately editable configuration. Invalid
values produce diagnostics and fall back per field; an unreadable root document
uses a complete safe default configuration and retains the last-known-good
loaded configuration in memory.

Configuration reload must be transactional at the document level:

1. Read the changed file.
2. Parse and validate into a candidate model.
3. Publish the candidate only when required fields are valid.
4. Otherwise keep the last-known-good model and expose the validation error.

### 5.2 Authored default desktop state

`defaults/manifest.json` is the authoritative owner of the default theme ID.
`DefaultsService` validates it independently from behavior configuration,
retains its last-known-good value after a rejected reload, and provides a safe
`poimandres` fallback when no valid manifest has loaded. Persisted active theme
state remains authoritative for the current session and machine;
the default theme is the startup and explicit restore fallback.

The complete authored bundle lives under `defaults/`. Wallpaper images are
stored under `defaults/wallpaper/images`; the generated QE wallpaper theme and
application artifacts are stored under
`defaults/wallpaper/generated-theme/{qe,applications}`. `scripts/qe-defaults`
is the sole capture/restore writer. Capture obtains confirmed active theme state
through typed QE IPC, rejects pending theme or wallpaper operations, migrates a
missing runtime artifact from its existing live slot when needed, preflights all
runtime artifacts, and stages the complete bundle before promotion. Restore
preflights the authored bundle, restores XDG artifacts, repairs application slot
links, and requests the manifest theme and default wallpaper from a running QE
instance. When QE is absent, the external switcher applies the manifest theme
directly. Runtime application failures do not modify the authored bundle or
remove restored files.

### 5.3 Paths

No source file may assume `/home/jim`, `~/Projects/quickshell`, or the eventual
dotfiles location.

- Repository assets use paths relative to Quickshell's shell directory property.
  `Quickshell.shellDir` is canonical in installed Quickshell 0.3.1 and current source; the older
  `shellRoot` and `configDir` aliases are deprecated. The exact property must
  still be verified before a Quickshell upgrade.
- QE persistent state uses `Quickshell.statePath(...)`.
- QE operation staging uses `Quickshell.dataPath(...)`. The generated
  `Wallpaper.json` uses `$XDG_DATA_HOME/qe/wallpaper/Wallpaper.json` so a
  default snapshot can be restored before QE starts on a fresh installation.
- Regenerable caches use `Quickshell.cachePath(...)`.
- External paths are resolved from XDG environment variables or explicit
  configuration.
- Paths passed to commands are array arguments, never interpolated shell text.

The `PathsService` is the sole QE-facing owner of resolved paths. Components do
not derive paths from `$HOME`.

### 5.4 Keybindings and commands

Hyprland configuration remains authoritative for key combinations because the
compositor owns global dispatch. QE exposes stable action endpoints through
Quickshell IPC or process entry points. Key sequences are not duplicated in QE
configuration.

Integration adapters own executable names, argument construction, and command
contracts. UI modules invoke typed domain operations such as `openLauncher()` or
`setBrightness(percent)`.

## 6. State Ownership

| Concern                     | Authoritative owner/source                    | Representation                                | Readers                                             | Writer                                 | Propagation                                                                               | Lifetime and invalid handling                                           |
| --------------------------- | --------------------------------------------- | --------------------------------------------- | --------------------------------------------------- | -------------------------------------- | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| QE user configuration       | User                                          | `config/qe.json`                              | `ConfigService`, modules through service properties | User only                              | watched, validate then publish                                                            | persistent; invalid file retains last-known-good or safe defaults       |
| QE authored themes          | User                                          | `themes/*.json`                               | `ThemeCatalogService`                               | User only                              | discovery/watch and validation                                                            | persistent input; invalid themes excluded with diagnostics              |
| Generated `Wallpaper` theme | Matugen generation adapter                    | stable XDG data path, same theme schema        | `ThemeCatalogService`, lock reader                  | generation adapter only                | atomic replace then catalog notification                                                  | derived, regenerable; default snapshot seeds fresh installs and LKG is retained on failure |
| Active QE theme             | `ThemeService`                                | versioned QE state JSON                       | all QE presentation, lock process                   | `ThemeService` only                    | singleton properties/signals                                                              | persistent; missing ID falls back to configured default                 |
| External desktop theme      | external theme switcher                       | switcher-owned versioned state after refactor | `ExternalThemeAdapter`, diagnostics                 | external switcher only                 | structured command result/file watch                                                      | independent of QE theme; unavailable state is unknown, not QE fallback  |
| Theme request in flight     | `ThemeService`                                | in-memory operation record                    | theme UI/status UI                                  | `ThemeService`                         | reactive properties                                                                       | ephemeral desired state; never authoritative confirmed theme            |
| Selected wallpaper          | `WallpaperService` after migration            | versioned QE state JSON                       | wallpaper/theme modules                             | `WallpaperService`                     | service signal after helper success                                                       | persistent requested/applied path; invalid path retains prior selection |
| Displayed wallpaper         | Hyprpaper                                     | compositor wallpaper state                    | `WallpaperIntegration` if observable                | Hyprpaper/helper                       | IPC response/events where available                                                       | external live state; never inferred solely from cached image            |
| Legacy theme/wallpaper data | existing switcher/picker                      | `~/.local/share/theme_data`                   | compatibility adapter only                          | legacy tools                           | file watch                                                                                | transitional external source, not QE state                              |
| Application feature flags   | User                                          | `config/qe.json`                              | `ConfigService` consumers                           | User only                              | validated config publication                                                              | persistent                                                              |
| Hyprland workspaces/windows | Hyprland                                      | native IPC state                              | `CompositorService`                                 | Hyprland; QE dispatches requests       | socket events plus explicit refresh only where API requires                               | live external; mark stale/disconnected on IPC loss                      |
| Audio graph/defaults        | PipeWire/WirePlumber                          | Quickshell PipeWire objects                   | `AudioService`                                      | subsystem; QE requests updates         | PipeWire events                                                                           | live external; pending operation reconciled to events                   |
| Network state               | NetworkManager                                | Quickshell Networking objects                 | `NetworkService`                                    | NetworkManager; QE requests operations | DBus events                                                                               | live external; secrets remain with NetworkManager                       |
| Bluetooth state             | BlueZ                                         | Quickshell Bluetooth objects                  | `BluetoothService`                                  | BlueZ; QE requests operations          | DBus ObjectManager events                                                                 | live external                                                           |
| Battery and power           | UPower/power-profiles-daemon                  | Quickshell UPower objects                     | `PowerService`                                      | external daemon                        | DBus events                                                                               | live external                                                           |
| Media players               | each MPRIS application                        | Quickshell MPRIS objects                      | `MediaService`                                      | player; QE requests operations         | DBus events; bounded position timer while visible/playing                                 | live external                                                           |
| Brightness                  | kernel backlight device                       | sysfs, mediated by helper                     | `BrightnessService`                                 | helper/kernel                          | initial read, operation confirmation, justified low-rate refresh if watcher is unreliable | live external; stale marked explicitly                                  |
| Notifications               | sending applications plus QE server lifecycle | Quickshell notification objects               | notification modules                                | senders; QE tracks/dismisses           | DBus events                                                                               | process-session only; cleared on process exit                           |
| Do-not-disturb              | `NotificationService`                         | QE state JSON                                 | notification/control-center modules                 | `NotificationService`                  | service property                                                                          | persistent user preference; does not discard history by default         |
| Idle inhibition             | compositor protocol                           | `IdleInhibitor` state                         | control center/bar                                  | `IdleService`                          | Wayland state                                                                             | ephemeral; loss of bound surface invalidates inhibition                 |
| View-local state            | owning QML view                               | QML properties                                | owning view                                         | owning view                            | local bindings                                                                            | ephemeral; not promoted without cross-view need                         |
| Generated thumbnails        | wallpaper cache adapter                       | QE cache directory                            | wallpaper selector                                  | cache adapter                          | manifest completion signal                                                                | cache only; malformed cache is deleted/regenerated                      |

State JSON files require a schema version from their first implementation.
Migration functions must be explicit and tested before a schema version is
incremented. Failed migration preserves the original file and starts with a
safe state accompanied by a diagnostic.

## 7. Common Service Contract

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

### 7.1 ConfigService

Responsibilities:

- load and validate `config/qe.json`
- apply schema defaults
- publish immutable-by-convention configuration properties
- retain last-known-good configuration
- report field-level validation errors

Only `ConfigService` reads user behavior configuration.

### 7.2 ThemeCatalogService and ThemeService

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

### 7.3 WallpaperService

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

### 7.4 CompositorService

Responsibilities:

- normalize Hyprland monitors, workspaces, focused workspace, and toplevels
- expose typed operations for workspace focus and window actions
- own Hyprland event subscriptions
- detect disconnection/staleness and refresh only when Quickshell's API requires

Raw `Hyprland.dispatch()` strings are confined to the integration adapter.

### 7.5 AudioService

QE-facing model:

- outputs and inputs
- default/preferred output and input
- volume, channel volumes, mute, availability, and device metadata
- active playback/capture streams when exposed by PipeWire

Operations include set default, set bounded volume, toggle/set mute, and later
stream routing where the native graph API proves sufficient. `PwObjectTracker`
ownership remains inside the adapter. Native PipeWire events confirm all
changes.

### 7.6 NetworkService

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

Passwords are passed as direct arguments only if the verified native API keeps
them in-process. They must not be interpolated into a shell command, logged, or
persisted by QE.

### 7.7 BluetoothService

QE-facing model:

- adapters and default adapter
- power, discovery, discoverability, and pairability
- known and discovered devices
- connection, pairing, trust, block, and battery state where available

Operations use native Quickshell Bluetooth methods for connect, disconnect,
pair, cancel, and forget. Pairing-agent capabilities and interactive PIN/passkey
flows must be verified before claiming full Blueman replacement.

The Phase 3 bar summary uses the installed `Quickshell.Bluetooth` module and is
read-only. It normalizes the default adapter, powered/transition state, known
and connected devices, aliases, and reported battery values directly from BlueZ
events; it adds no poller and treats controller/daemon loss as unavailable. The
configured bar chip remains visible for that unavailable state and presents the
same disabled/error visual as a powered-off controller, without claiming that
an adapter still exists.
Interactive connect, pair, and manager-launch behavior remains deferred until
the pairing-agent and application-launch boundaries are established.

### 7.8 PowerService and SystemMetricsService

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

These intervals passed the Phase 3 bar budget on the development machine.
Hardware sensors are discovered by stable attributes, not a hard-coded
`hwmon3` path. A bounded structured helper performs thermal discovery once;
subsequent selected-sensor reads use asynchronous `FileView` access until three
failures force rediscovery. Root-disk capacity retains a bounded structured
helper contract with a validated shell/`df` fast path; Python is restricted to
fixture parsing and thermal discovery rather than recurring reads.

### 7.9 MediaService

Responsibilities:

- normalize MPRIS player metadata and capabilities
- select a current player using documented deterministic policy
- expose guarded play/pause/next/previous/seek operations
- update position only while a consumer is visible and the player is playing

Track lists and playlists are not initial goals because Quickshell 0.3.1 does
not expose them.

### 7.10 BrightnessService

Quickshell 0.3.1 has no native brightness API. The integration uses a stable
helper contract around `brightnessctl` initially.

The service exposes devices, current percent, pending percent, and bounded set
or step operations. A successful command exit triggers a fresh authoritative
read before confirmed state changes. External changes use a filesystem watcher
if reliable for the active sysfs device; otherwise a documented low-rate poll
is allowed and must mark stale data after missed reads.

The Phase 3 bar implementation uses the helper for backlight discovery and
writes only. While the configured bar consumer is active, the adapter reads the
validated active device's `brightness` and `max_brightness` sysfs files
asynchronously and refreshes `brightness` every 10 seconds because portable
change notifications are not reliable across backlight drivers and external
writers. The poll stops with no consumer. Three failed reads retain the last
confirmed value, mark it stale, discard the invalid device, and retry discovery.
Rapid requests are coalesced by `BrightnessService`; requested values remain
pending until the helper returns a fresh authoritative post-write read. Bar
wheel input changes the latest requested value in bounded five-percent steps.

### 7.11 NotificationService

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
use `notifications`. Fallback icons use `on_surface_disabled`, except critical
icons, which use the theme error color.

The notification center's DND control is a controlled toggle `IconButton` with
the `do_not_disturb_on` icon. Its state is owned by `NotificationService`.
Toggle buttons retain the regular `IconButton` background states and expose the
next state through `toggled(bool)`; while toggled on, their foreground and
border use `toggleColor`, which defaults to the theme `success` token. The
notification-center instances override their foreground, border, and DND
off-state colors with `on_surface_disabled`, while
DND retains `warning` for its toggled-on foreground and border.
Non-toggle buttons retain the regular `clicked()` behavior.

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
`on_surface_variant` `keyboard_arrow_down` icon and count, a 1px
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
fixed notification and starts a persistent D-Bus notification sender with
actions to open the captured image or its containing directory in Thunar with
the image selected. The notification body contains the captured filename, and
the sender publishes the image through the standard `image-path` hint for
notification thumbnails.
Action handling remains owned by that sender and does not add
screenshot-specific command parsing to the presentation layer. The sender keeps
the notification resident and keeps its action endpoint alive until the
notification is closed, so popup and history controls can be reused.

### 7.12 OSDService

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

### 7.13 IdleService

`IdleService` owns the compositor `IdleInhibitor` and binds it to a persistent QE
window. Quickshell 0.3.1 exposes only the local `enabled` request and bound
window; it provides no compositor-confirmed active state or failure signal.
`IdleService` therefore exposes requested state only and never presents it as
confirmed external state. The request is process-session local, defaults off,
is not persisted, and is released when disabled, when the owner window is lost,
or when QE exits. Confirmed-active reporting is deferred until Quickshell
exposes it or QE gains a reviewed native extension. Idle inhibition does not
replace Hypridle's timeout, manual lock, or suspend policy. QE applies no
automatic inhibitor timeout: requested state remains unchanged until the user
toggles it or the configuration/window/process lifecycle forces safe release.

### 7.14 LauncherService and HelpService

`LauncherService` consumes Quickshell `DesktopEntries`, applies pure filtering
and ranking, and launches the structured `DesktopEntry.command` with its working
directory. It does not execute raw desktop `Exec` strings through a shell.

`HelpService` reads a user-authored JSON reference catalog. Hyprland remains
authoritative for actual keybindings unless a future verified parser derives
the catalog. Help entries that describe keybindings must be labeled reference
data and may become stale; duplication is accepted only until derivation from
the Lua config is feasible.

### 7.15 Hardware action IPC

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

## 8. Theme Architecture

### 8.1 Theme scopes

There are two independent theme scopes:

- QE theme: owned and persisted by `ThemeService`
- external desktop theme: owned and persisted by the external theme switcher

Selecting a QE theme automatically requests the same ID externally after QE
succeeds. External failure does not invalidate QE success. The selector shows
QE success and external warning separately. Running the external switcher from
the CLI may change external applications without changing QE.

### 8.2 Theme schema

Every authored and generated QE theme uses the same versioned strict JSON
contract. The initial shape is:

```json
{
  "schemaVersion": 1,
  "id": "poimandres",
  "name": "Poimandres",
  "variant": "dark",
  "palette": {
    "background": "#1b1e28",
    "foreground": "#e4f0fb",
    "muted": "#8290a5",
    "black": "#171922",
    "gray": "#303340",
    "grayLight": "#41434F",
    "blueGrayDark": "#506477",
    "blueGray": "#7390aa",
    "blueGrayLight": "#91B4D5",
    "blue": "#add7ff",
    "cyan": "#89DDFF",
    "purple": "#767C9D",
    "purpleLight": "#a6accd",
    "pink": "#fcc5e9",
    "red": "#d0679d",
    "green": "#5fb3a1",
    "greenLight": "#5de4c7",
    "yellow": "#fffac2"
  },
  "tokens": {
    "background": "{palette.background}",
    "on_background": "{palette.foreground}",
    "surface": "{palette.gray}",
    "on_surface": "{palette.foreground}",
    "surface_variant": "{palette.blueGrayDark}",
    "on_surface_variant": "{palette.foreground}",
    "surface_panel": "#f21b1e28",
    "surface_sidebar": "#f5171922",
    "on_surface_panel": "{palette.foreground}",
    "surface_tooltip": "{palette.black}",
    "on_surface_tooltip": "{palette.muted}",
    "surface_hover": "{palette.grayLight}",
    "surface_pressed": "{palette.blueGrayDark}",
    "primary": "{palette.green}",
    "on_primary": "{palette.black}",
    "primary_container": "{palette.blueGray}",
    "on_primary_container": "{palette.black}",
    "secondary": "{palette.blueGray}",
    "on_secondary": "{palette.black}",
    "outline": "{palette.purple}",
    "outline_variant": "{palette.blueGrayDark}",
    "focus_ring": "{palette.cyan}",
    "on_surface_disabled": "{palette.blueGrayDark}",
    "on_surface_placeholder": "{palette.muted}",
    "link": "{palette.cyan}",
    "highlight": "{palette.yellow}",
    "on_highlight": "{palette.black}",
    "success": "{palette.greenLight}",
    "warning": "{palette.yellow}",
    "error": "{palette.red}",
    "shadow": "#80000000",
    "scrim": "#99000000",
    "charging": "{palette.yellow}"
  }
}
```

The approved 33-role token names use Matugen-style `snake_case` and paired
`on_*` foregrounds. ADR-015 records the Phase 4 pre-release contract revision
that supersedes the provisional vocabulary and the individual additions in
ADR-012 and ADR-014 while retaining their charging and tooltip semantics.
Any explicit pre-release contract revision is recorded in an ADR and updates all
themes, fixtures, fallbacks, and validators together. Token references are
resolved once by pure validation logic; normal components consume resolved
semantic tokens only.

Raw palette names describe source colors. Semantic tokens describe UI roles.
Normal components never consume palette entries directly, which allows Matugen
and manually authored palettes to map different raw vocabularies to the same UI.
The palette viewer is an explicit inspection surface and may display any validated
catalog theme's raw palette and resolved tokens without applying that theme.
Its selected theme is view-local and its viewer chrome remains styled by the
active QE theme.

Authored and generated `on_*` pairs target at least 4.5:1 contrast for normal
text. Meaningful icons, focus indicators, and strong boundaries target at least
3:1 against their intended surface. `surface_panel` and `surface_sidebar` may
contain alpha, so static validation composites them over the theme background;
live acceptance also checks
representative wallpapers because no fixed foreground can guarantee contrast
over every external image.

Typography, spacing, radii, border widths, shadows parameters, opacity policy,
and animation durations belong to user configuration initially, not individual
color themes. Color-valued shadow, scrim, panel-alpha, and interaction-state
tokens remain in themes.
This prevents theme changes from unexpectedly altering layout and motion. A
future theme schema may add explicit style profiles through a migration.

### 8.3 Validation and fallback

- Reject unknown schema versions.
- Require unique normalized IDs and all mandatory semantic tokens.
- Accept only validated color strings and supported variants.
- Resolve references with cycle detection.
- Exclude invalid catalog entries and report their path and validation errors.
- Never partially publish a theme.
- Keep the current last-known-good theme if its source becomes invalid.
- At cold start, use the persisted active ID, then configured default, then a
  built-in minimal emergency palette embedded in `ThemeService`.

The emergency palette is fallback code, not an independently editable theme.
The isolated lock reader has a separate fail-safe opaque-black palette for the
case where no validated persisted theme can be loaded. That lock-only safety
fallback is not the active QE theme and is intentionally independent of the
main `ThemeService` module graph.

### 8.4 Reactive propagation

`ThemeService` publishes one resolved theme object/property set. All windows and
components bind to semantic properties from that service. Existing windows
update without recreation. No component copies theme colors into local mutable
properties unless the copy is temporary animation state.

### 8.5 Matugen

Matugen is an external generator, not a runtime source of live state.

- Input: validated selected wallpaper path and explicit dark/light mode.
- Command: array arguments; no shell interpolation.
- Output: staging directory containing QE `Wallpaper` JSON and configured
  external application artifacts.
- Validation: QE schema plus target-specific validators before promotion.
- Promotion: atomic replace per artifact where supported.
- Failure: preserve the complete previous last-known-good generated set.
- Hooks: not used for opaque application orchestration; QE and the external
  switcher control apply order and observe results.

Matugen's JSON output or templates are mapped into QE semantic tokens by a
versioned template. The generated `Wallpaper` file is derived data and is never
edited by users. User overrides, if later needed, must be a separate authored
input layered before generation rather than edits to generated output.

Wallpaper generation also captures the focused Kitty appearance at apply time.
`scripts/qe-window-opacity.sh` reads Kitty's effective `background_opacity`,
including nested includes, and queries Hyprland's live
`decoration:active_opacity` through `hyprctl`. Missing, unavailable, malformed,
or out-of-range upstream values fall back to `1.0`; the snapshot is not watched
at runtime. The generated wallpaper `surface_panel` uses the palette background
with the product of those opacities as its alpha. `surface_sidebar` applies the
same alpha to a hue-preserving HSL darkening of the palette background by 9/255
lightness units, matching the measured difference between `#282828` and
`#1d2021`. Later upstream config changes take effect on the next wallpaper-theme
generation or application.

The current adapter boundary requires `QE_MATUGEN` to name the executable; an
unset or missing executable is an isolated unavailable state. `MatugenAdapter`
requests noninteractive JSON output with an explicit mode and source-color
preference, bounds the process, and validates the mapped 33-role theme before
the service stages it. `WallpaperPromotionAdapter` then promotes the staged QE
`Wallpaper.json` into its stable XDG data path, preserving the previous artifact
when staging or promotion fails. External Matugen artifacts use the separate
validated promotion contract described below.

The compatibility wallpaper boundary requires `QE_WALLPAPER_HELPER` and passes
the selected path as a discrete argument. The QE helper validates and stages
derived images, restarts Hyprpaper, and waits for the bounded
`hyprctl hyprpaper wallpaper` request before promoting those images. A
successful helper result confirms Hyprpaper IPC acceptance, not pixel display;
`WallpaperService` therefore keeps requested, applied, and generation state
separate. No legacy helper is used unless explicitly configured.

QE also owns a localized wallpaper selector
(`modules/wallpaper/WallpaperSelector.qml`) opened through the `qe-wallpaper`
  IPC target. It uses QE-owned thumbnail cache and apply state, remains open after
  a successful apply, and reuses the same apply/generation pipeline as the helper.
The Hyprpaper and Hyprlock configurations resolve their image paths through
`$XDG_DATA_HOME` with a `$HOME/.local/share` fallback so both configs and both
wallpaper scripts stay aligned. Temporary `.desktop` entries launch the theme
and wallpaper selectors through `scripts/qe-launch.sh`, which discovers the
running `--no-duplicate` QE shell and calls the corresponding IPC target; these
launchers will be replaced by the planned control center.

When the active QE theme is the generated `wallpaper` theme, QE also generates
standalone "wallpaper" theme slot files for external applications and the
external switcher applies them. `ExternalWallpaperTheme` maps the same Matugen
Material palette into per-application formats (kitty, bat, btop, eza, dunst,
fzf, hyprland, hyprlock, imv, mpv, rofi, starship, tmux, opencode, and Yazi's
semantic palette plus TextMate syntax file, and a Palette JSON for Neovim), and
`WallpaperExternalThemeAdapter` materializes them through
`scripts/promote-external-theme.sh`, which writes each file into the app's
the app-specific `wallpaper` slot with staging and atomic same-filesystem
replacement, skipping targets whose executables are absent, preserving unchanged
files, and reporting per-target results. Stow-managed installations keep these
live slots as ignored, restore-managed symlinks to XDG state; promotion resolves
the link before replacing the runtime target so the QE repository's authored
defaults remain separate from runtime state. The explicit `qe-defaults restore` operation
preflights and restores the generated QE theme, wallpaper/lockscreen images,
Neovim palette, and external slots before creating or repairing the live links.
It applies the manifest's default theme through running QE or, when QE is
absent, directly through the external switcher. A missing or failed switcher
leaves restored files in place and reports the failure. `capture` is the only
operation that updates the authored default bundle.
QE never writes an app's active configuration; the external switcher owns that
copy. After promotion succeeds, QE delegates external application to the
switcher with `--machine --theme wallpaper --skip-gtk` (GTK is excluded because
Matugen does not generate GTK themes). Applying a wallpaper always regenerates
QE's validated `Wallpaper` theme and the external slot files so the generated
"wallpaper" theme becomes selectable, but QE delegates external application
only while the wallpaper theme is active, so a wallpaper change never overwrites
fixed external themes. Neovim consumes the generated palette through a local
`colors/wallpaper.vim` colorscheme that reloads the palette on every
`:colorscheme wallpaper`, so the switcher's existing name-based Neovim apply
path works without an extra plugin. The generated catalog entry is re-read
after atomic replacement so repeated wallpaper generations update the live
catalog without a QE restart. Selecting `wallpaper` defers external switcher
dispatch until its generation/promotion phase completes, preventing duplicate
external requests from racing one another. A wallpaper change issued while a
generation is in flight is queued as the latest requested path instead of being
dropped, and regenerating the already-published theme skips the redundant
promotion while still running the external dispatch phase.

### 8.6 External theme switcher contract

The switcher remains usable independently and exposes this stable
machine-facing interface:

```text
run.sh --machine --theme <id> [--skip-gtk]
```

Required contract:

- validate IDs against a catalog; reject path traversal and arbitrary names
- accept arguments as discrete values
- never require QE to parse human log lines
- emit one versioned JSON result with per-target status
- reserve stdout for structured output in machine mode and stderr for logs
- return distinct codes for success, partial failure, invalid request, and
  orchestrator failure
- support bounded execution and TERM handling
- persist external active theme only according to documented external policy
- skip targets retired by QE without deleting their source themes
- avoid automatically opening a wallpaper picker for QE-issued requests

Machine mode exits 0 for success, 3 for partial application, 4 for failed
application or orchestration, and 2 for usage. It atomically writes the same
successful persistence document to
`${XDG_STATE_HOME:-$HOME/.local/state}/theme-switcher/active-theme.json`; this
switcher-owned document contains no QE operation identity. Per ADR-017, QE
assigns operation IDs at its adapter boundary, serializes requests through the
bounded process phase, and uses those IDs only to associate direct command
results. Independent state-file updates report external state but never complete
a QE operation or overwrite the active QE theme.

`ExternalThemeAdapter` resolves the executable from `QE_THEME_SWITCHER`. An
unset, missing, or removed executable is an isolated unavailable state rather
than a startup failure; QE does not assume an external repository location.

External application is best effort. Partial application is retained and
reported; global rollback is not attempted because many targets cannot be
reverted atomically and rollback can also fail.

## 9. Integration Boundaries

| Integration       | Live authority                   | Initial discovery                 | Ongoing updates                   | QE operations                      | Reconnect/failure policy                                                                                                       | Independent test boundary                                     |
| ----------------- | -------------------------------- | --------------------------------- | --------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------- |
| Hyprland          | Hyprland IPC                     | native singleton models           | socket events                     | typed dispatch adapter             | mark stale on disconnect; explicit refresh only for known API gaps                                                             | recorded events/models and live opt-in test                   |
| PipeWire          | PipeWire/WirePlumber             | `Pipewire.ready`, nodes/defaults  | libpipewire events                | defaults, volume, mute             | native adapter reconnects; clear stale object references                                                                       | mock node model and live audio test                           |
| NetworkManager    | NetworkManager                   | native Networking models; bounded `nmcli` IPv4 enrichment because 0.3.1 exposes only hardware addresses | DBus signals trigger native updates and active-interface address refresh; no polling | toggle/connect/disconnect/forget   | unavailable/degraded while daemon absent; cancel or supersede stale IPv4 lookups; repopulate on return                          | fixture model plus isolated live test network and loopback IPv4 lookup |
| BlueZ             | BlueZ                            | DBus ObjectManager via native API | DBus object/property signals      | power/discover/pair/connect/forget | preserve no false connected state; repopulate on service return                                                                | mock devices and manual hardware test                         |
| UPower            | UPower and power-profiles-daemon | native singleton                  | DBus signals                      | profile selection                  | battery may remain absent on desktop; profile feature degrades separately                                                      | fixture devices and live read-only test                       |
| MPRIS             | player applications              | service watcher                   | DBus properties/signals           | capability-guarded controls        | remove vanished player; deterministic reselection                                                                              | mock player capabilities                                      |
| System tray       | status notifier services         | native singleton                  | DBus watcher/menu events          | activate/menu/scroll               | remove vanished items; malformed menu affects only item; do not instantiate the QE tray host in a second shell instance; once instantiated, 0.3.1 ownership is process-lifetime and returning ownership requires stopping QE | mock item delegate and live tray apps                         |
| Notifications     | sending apps                     | DBus service acquisition          | notification calls                | action/reply/dismiss               | cannot coexist with Dunst; ownership state visible                                                                             | `notify-send` acceptance suite in isolated session            |
| Brightness        | kernel backlight                 | helper structured read            | watcher or documented poll        | bounded set/step                   | timeout, malformed output, permission error; retain stale last value                                                           | helper fixtures and fake sysfs root                           |
| System metrics    | procfs/sysfs/filesystem          | adapter reads                     | documented polling                | read only                          | per-metric stale/error; no bar-wide failure                                                                                    | fixture roots and parser tests                                |
| Idle inhibit      | Wayland compositor               | protocol object                   | compositor state/lifetime         | enable/disable                     | requested state separate from active; surface loss disables                                                                    | compositor/manual protocol test                               |
| Session lock      | compositor                       | lock request and `secure`         | protocol events                   | unlock only after PAM success      | fail closed; no automatic reclaim after crash                                                                                  | nested/test compositor where possible plus manual checklist   |
| PAM               | configured PAM service           | `PamContext.start()`              | PAM conversation signals          | respond/cancel through context     | bounded attempts; generic UI errors; never log response                                                                        | test PAM profile if safely available; manual login-stack test |
| Desktop entries   | XDG application dirs             | `DesktopEntries.applications`     | native file monitoring            | structured launch                  | invalid entries omitted; launch failure visible                                                                                | fixture desktop files where API permits                       |
| Wallpaper         | Hyprpaper/helper                 | compatibility state then QE state | IPC/file changes where observable | apply processed wallpaper          | helper success is not compositor proof unless IPC confirms; bound decode dimensions/time and retain prior on failure           | temporary paths and image fixtures                            |
| External switcher | switcher-owned state             | versioned state/status            | result and optional file watch    | request apply                      | timeout/partial status; no QE rollback                                                                                         | fake target scripts and contract tests                        |
| Matugen           | generated command output         | on-demand generation              | wallpaper-triggered only          | generate staged set                | debounce, timeout, validate, keep LKG                                                                                          | golden wallpaper and expected schema fixtures                 |

### 9.1 Command adapter rules

Every command boundary defines:

- executable discovery and missing-dependency behavior
- array-form arguments
- accepted input validation
- timeout and TERM-to-KILL grace period
- maximum stdout/stderr retained in diagnostics
- output schema and version
- exit-code meanings
- cancellation and supersession behavior
- whether retries are safe and idempotent

Commands do not run through `sh -c` unless shell semantics are the purpose of a
reviewed helper script. Secrets never appear in arguments when a native API can
avoid it, logs, state files, or diagnostic UI.

### 9.2 Polling policy

Polling is allowed only for values lacking reliable events. Every poller must be
listed in `docs/PLAN.md`, configured or constant with rationale, suspended when not
needed where practical, and expose staleness after failures.

Expected pollers are clock display cadence, CPU/memory, temperature, disk
capacity, MPRIS playback position while active, and potentially brightness if
sysfs watching proves unreliable. Network, Bluetooth, audio, battery,
workspaces, tray, and notifications must use native events.

## 10. Lifecycle

### 10.1 Persistent shell startup

1. Resolve project and XDG paths.
2. Initialize diagnostics.
3. Load and validate configuration.
4. Load persisted QE state and migrate if needed.
5. Load theme catalog and publish a last-known-good theme.
6. Instantiate enabled domain services and adapters.
7. Create shell surfaces only after safe configuration/theme values exist.
8. Expose IPC endpoints.
9. Report readiness and degraded integrations independently.

The bar can render with fallback theme and unavailable placeholders while
optional services initialize. Startup does not block on Matugen, network,
Bluetooth, external switcher, or wallpaper generation.

### 10.2 Reload

Development soft reload must preserve only state explicitly supported by
Quickshell reload mechanisms or persisted QE state. Adapters must not duplicate
subscriptions after reload. Notification handling inspects `lastGeneration`.

Production configuration changes are validated before publication. Application
source reload behavior is not used as a substitute for user configuration
reload.

### 10.3 Shutdown and crash

- Child processes owned by QE are terminated unless deliberately detached by a
  documented operation.
- Pending operations become unknown/failed on restart and reconcile from live
  subsystem state.
- Process-session notification history is lost by design.
- Generated and persisted files remain valid because writes are atomic.
- Lock-process shutdown without authenticated unlock is never treated as a
  successful unlock.

### 10.4 Transient surface routing and IPC

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

## 11. Failure and Degraded Behavior

| Failure                              | Required behavior                                                                                                                 |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| Missing optional executable          | integration unavailable; hide destructive controls, retain explanatory status                                                     |
| Native daemon unavailable at startup | shell starts; module shows unavailable; adapter waits for native reconnection or documented backoff                               |
| Permission denied                    | operation fails visibly; do not repeatedly prompt or retry without user action                                                    |
| Timeout                              | terminate operation safely, mark outcome unknown where side effects may have occurred, then refresh live state                    |
| Malformed structured output          | reject entire result; retain confirmed/LKG state; capture bounded diagnostic detail                                               |
| Missing/invalid config               | retain last-known-good in process or use safe defaults at cold start; expose persistent diagnostic                                |
| Missing/invalid active theme         | fall back through configured default to emergency palette; do not rewrite authored theme                                          |
| Event subscription disconnect        | mark state stale immediately; reconnect through native mechanism or bounded exponential backoff with jitter                       |
| External subsystem restart           | discard invalid object references and repopulate from fresh discovery                                                             |
| Partial theme apply                  | QE remains successful if its phase committed; external status is partial and retryable per target                                 |
| Wallpaper generation failure         | keep previous generated `Wallpaper`; retain newly selected wallpaper if wallpaper apply itself succeeded; show generation failure |
| Requested change unconfirmed         | clear pending on timeout, report failure/unknown, refresh authority; never silently commit intent                                 |
| Optional module failure              | module degrades independently; persistent shell remains running                                                                   |
| Notification ownership conflict      | do not claim readiness; keep staged migration mode and identify current owner                                                     |
| Lock authentication failure          | remain securely locked; clear secret response; apply bounded retry delay without revealing account details                        |
| Lock process crash after secure      | compositor remains locked; document TTY/session recovery; never attempt unauthenticated unlock                                    |

Retries are limited to transient discovery/reconnection. User operations are not
blindly retried unless idempotence is proven. Backoff state is adapter-owned.

## 12. Security

- The lock uses `WlSessionLock` and checks `secure` before presenting itself as
  fully locked.
- PAM responses remain in lock-process memory only and are cleared immediately
  after response submission.
- The initial PAM service uses a verified existing stack such as `login` or
  `hyprlock`; a custom `/etc/pam.d` file requires separate approval and system
  change procedure.
- QE IPC is not an authentication boundary and never exposes unlock or raw PAM
  response methods.
- Network secrets are not persisted or logged by QE.
- Notification markup, images, links, and actions are untrusted application
  input and require constrained rendering.
- Theme IDs, paths, desktop entries, notification actions, and helper output are
  validated before use.
- Helpers quote all paths, avoid shell interpolation, and reject path traversal.
- Diagnostics redact secrets and bound external output size.
- Power actions require explicit user activation and confirmation according to
  configuration; command availability does not imply authorization.

## 13. Logging and Diagnostics

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
supervision may additionally route output to the user journal later.

## 14. Testing Strategy

### 14.1 Static validation

- `qmllint` all QML files with installed Quickshell module metadata.
- Parse every JSON configuration, schema fixture, and theme.
- Validate every authored theme against the same runtime contract.
- Run `shellcheck` on new shell helpers.
- Search for forbidden absolute home paths and direct command execution in
  presentation directories.

### 14.2 Unit and contract tests

- Pure JavaScript token resolution, validation, formatting, sorting, and state
  transformations use deterministic fixtures.
- QML services are tested with injected fake adapters where practical.
- Command helpers are tested against temporary directories and structured
  golden outputs.
- Malformed, empty, oversized, timeout, missing executable, and partial failure
  cases are first-class tests.
- State schema migration tests preserve originals and verify idempotence.

### 14.3 Smoke and integration tests

- Start the development shell with `quickshell -p shell.qml` under a timeout and
  inspect stderr/logs.
- Exercise native services against the current session only in opt-in tests.
- Use non-exclusive development surfaces or a non-conflicting alternate edge
  when intentionally testing alongside a legacy bar. Verify that any
  development reservation does not alter the other bar's edge reservation.
- Test notification ownership only in an isolated test window/session using the
  current QE owner. Dunst restoration applies only to an explicit rollback test;
  the normal post-cutover state is masked/inactive Dunst with QE owning the name.
- Test lock behavior in a disposable session or nested compositor where
  protocol support permits, followed by a documented real-session checklist.

### 14.4 Acceptance testing

Each module requires tests for unavailable dependencies, daemon restart,
operation timeout, stale state, multi-monitor behavior where relevant, theme
change while visible, and QE reload. Replacement cutovers additionally require
a rollback exercise.

## 15. Architectural Constraints Pending Verification

These are not approved implementation facts until their milestone verifies
them against installed Quickshell 0.3.1:

- Hyprland IPC reconnection behavior after compositor restart
- NetworkManager behavior for hidden and enterprise networks
- Bluetooth interactive pairing-agent coverage
- reliable external brightness change detection through sysfs watching
- Hyprpaper's best available confirmation/IPC contract
- practical automated testing of `WlSessionLock` in a nested compositor
- whether a built-in QML test harness can instantiate all Quickshell singleton
  types without a live compositor

Until verified, adapters must preserve replaceable boundaries and milestones
must not claim unsupported functionality.
