# Project Model, Configuration, and State

Authoritative for repository dependency boundaries, configuration and path ownership, persistent/shared state, and the distinction between authored, generated, cached, requested, and confirmed values.

## Repository Structure

```text
.
|-- shell.qml                  # persistent process entry point
|-- lock.qml                   # isolated lock process entry point
|-- install.sh                 # installation protocol entry point
|-- install/                   # static deployment assets and capability probe
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
|   |-- architecture/           # selectively loaded domain architecture
|   |-- STATUS.md
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

Reusable action controls own the mapping from interaction state to semantic
theme roles. `ActionButton` provides neutral, primary, and destructive tones;
ghost, outlined, and filled emphasis; and normal, hover, pressed, selected,
pending, disabled, and focus treatment. `IconButton` specializes that contract
for icon-only actions. Modules select a tone and emphasis but do not choose raw
foreground, border, hover, or pressed colors. Ordinary selection uses
`primary_container`/`on_primary_container`; confirmed success, warning, and
error roles are not aliases for checked or pending state.
Outlined primary and destructive actions use their tone for the boundary while
retaining a readable content foreground on interaction surfaces. Ghost actions
omit the ordinary boundary, and keyboard focus restores a visible focus ring.
Filled emphasis is limited to primary actions because status roles do not yet
have guaranteed foreground pairs.

The bar uses a separate optical hierarchy from action controls. Ordinary text
and percentages use `on_surface_subdued`; ordinary compact icons and uniformly
tinted tray icons use `on_surface_indicator`. The SSID and clock time retain
deliberate `primary` emphasis. Confirmed domain states override the neutral
indicator: Bluetooth connectivity uses `success`, mute and DND suppression use
`warning`, idle inhibition uses `primary`, stale values use `warning`, confirmed
failure or critical state uses `error`, and ordinary charging uses `charging`.
Network connectivity and workspace focus do not change the neutral icon color;
urgent workspaces use `warning`. Precedence is critical/error, stale/warning,
pending, charging, confirmed success, active mode, then neutral indicator.

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
| `lock/`         | lock-safe theme/config readers, native UPower read, PAM, Wayland session lock | persistent shell services and nonessential adapters |

Circular dependencies are prohibited. A shared concern is promoted to a domain
service only when at least two modules need it or it owns long-lived external
state. Feature-local state remains in the module.
## Configuration and Paths

### User-authored configuration

`config/qe.json` is the user-authored QE behavior/configuration source. The
separate `config/help.json` file is the sole authoritative user-authored
reference catalog for the help surface. The current `qe.json` schema contains:

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

### Authored default desktop state

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
is the sole seed/capture/restore writer. Seed non-destructively creates missing
first-frame artifacts and recognized external links without applying a theme or
fabricating selected-wallpaper state. Capture obtains confirmed active theme state
through typed QE IPC, rejects pending theme or wallpaper operations, migrates a
missing runtime artifact from its existing live slot when needed, preflights all
runtime artifacts, and stages the complete bundle before promotion. Restore
preflights the authored bundle, restores XDG artifacts, repairs application slot
links, and requests the manifest theme and default wallpaper from a running QE
instance. When QE is absent, the external switcher applies the manifest theme
directly. Runtime application failures do not modify the authored bundle or
remove restored files.

### Paths

Runtime source files do not assume `/home/jim` or a dotfiles location. The
installer deliberately enforces the supported `$HOME/Projects/quickshell`
production checkout from ADR-045; tests may relocate it through explicit fixture
seams.

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

### Keybindings and commands

Hyprland configuration remains authoritative for key combinations because the
compositor owns global dispatch. QE exposes stable action endpoints through
Quickshell IPC or process entry points. The help catalog may duplicate key
sequences as display-only reference data; it is never authoritative live state.

Integration adapters own executable names, argument construction, and command
contracts. UI modules invoke typed domain operations such as `openLauncher()` or
`setBrightness(percent)`.
## State Ownership

| Concern                     | Authoritative owner/source                    | Representation                                | Readers                                             | Writer                                 | Propagation                                                                               | Lifetime and invalid handling                                           |
| --------------------------- | --------------------------------------------- | --------------------------------------------- | --------------------------------------------------- | -------------------------------------- | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Installation/activation result | QE installer and canonical activation | `$XDG_STATE_HOME/qe/installation.json`, schema v1 | installer, `qe-doctor` | completed install/activation attempt | atomic replace | process-independent; last result is not a current-liveness claim; malformed versions are preserved until a later completed attempt |
| QE user configuration       | User                                          | `config/qe.json`                              | `ConfigService`, modules through service properties | User only                              | watched, validate then publish                                                            | persistent; invalid file retains last-known-good or safe defaults       |
| Help reference catalog      | User                                          | `config/help.json`                              | `HelpService`, help surface                    | User only                              | refresh on help-surface open, validate then publish                                        | persistent reference data; invalid file produces an empty usable catalog and diagnostic |
| QE authored themes          | User                                          | `themes/*.json`                               | `ThemeCatalogService`                               | User only                              | discovery/watch and validation                                                            | persistent input; invalid themes excluded with diagnostics              |
| Generated `Wallpaper` theme | Matugen generation adapter                    | stable XDG data path, same theme schema        | `ThemeCatalogService`, lock reader                  | generation adapter only                | atomic replace then catalog notification                                                  | derived, regenerable; default snapshot seeds fresh installs and LKG is retained on failure |
| Active QE theme             | `ThemeService`                                | versioned process-independent QE state JSON at `$XDG_STATE_HOME/quickshell/active-theme.json` | all QE presentation, lock process | `ThemeService` only | singleton properties/signals | persistent; missing ID falls back to configured default |
| External desktop theme      | external theme switcher                       | switcher-owned versioned state after refactor | `ExternalThemeAdapter`, diagnostics                 | external switcher only                 | structured command result/file watch                                                      | independent of QE theme; unavailable state is unknown, not QE fallback  |
| Theme request in flight     | `ThemeService`                                | in-memory operation record                    | theme UI/status UI                                  | `ThemeService`                         | reactive properties                                                                       | ephemeral desired state; never authoritative confirmed theme            |
| Selected wallpaper          | `WallpaperService` after migration            | versioned QE state JSON                       | wallpaper/theme modules                             | `WallpaperService`                     | service signal after helper success                                                       | persistent requested/applied path; invalid path retains prior selection |
| Displayed wallpaper         | Hyprpaper                                     | compositor wallpaper state                    | `WallpaperIntegration` if observable                | Hyprpaper/helper                       | IPC response/events where available                                                       | external live state; never inferred solely from cached image            |
| Legacy theme/wallpaper data | existing switcher/picker                      | `~/.local/share/theme_data`                   | compatibility adapter only                          | legacy tools                           | file watch                                                                                | transitional external source, not QE state                              |
| Application feature flags   | User                                          | `config/qe.json`                              | `ConfigService` consumers                           | User only                              | validated config publication                                                              | persistent                                                              |
| AI provider quota           | OpenAI/OpenCode provider services             | normalized in-memory provider/window records | `AiQuotaService`, bar, AI quota dashboard           | provider API; QE reads only                         | bounded helper request while consumers exist                                          | live derived data; retain and explicitly mark last-known values stale; never persist credentials or quota snapshots |
| Launcher usage counts      | `LauncherService`                            | `launcher-usage.json`, versioned QE state keyed by desktop-entry ID | `LauncherService`, launcher surface              | `LauncherService`                     | successful launch updates; atomic persistence                                             | persistent generated state; malformed or incompatible data starts empty with a diagnostic |
| Hyprland workspaces/windows | Hyprland                                      | adapter-backed reactive native model plus service-owned monitor-scoped policy | `CompositorService`                     | Hyprland; QE dispatches requests       | socket events plus explicit refresh only where API requires                               | live external; mark stale/disconnected on IPC loss                      |
| Audio graph/defaults        | PipeWire/WirePlumber                          | Quickshell PipeWire objects                   | `AudioService`                                      | subsystem; QE requests updates         | PipeWire events                                                                           | live external; pending operation reconciled to events                   |
| Network state               | NetworkManager                                | Quickshell Networking objects                 | `NetworkService`                                    | NetworkManager; QE requests operations | DBus events                                                                               | live external; secrets remain with NetworkManager                       |
| Bluetooth state             | BlueZ                                         | Quickshell Bluetooth objects                  | `BluetoothService`                                  | BlueZ; QE requests operations          | DBus ObjectManager events                                                                 | live external                                                           |
| Battery and power           | UPower/power-profiles-daemon                  | Quickshell UPower objects                     | `PowerService`                                      | external daemon                        | DBus events                                                                               | live external                                                           |
| Media players               | each MPRIS application                        | Quickshell MPRIS objects                      | `MediaService`                                      | player; QE requests operations         | DBus events; bounded position timer while visible/playing                                 | live external                                                           |
| Brightness                  | kernel backlight device                       | sysfs, mediated by helper                     | `BrightnessService`                                 | helper/kernel                          | initial read, operation confirmation, justified low-rate refresh if watcher is unreliable | live external; stale marked explicitly                                  |
| Notifications               | sending applications plus QE server lifecycle | Quickshell notification objects               | notification modules                                | senders; QE tracks/dismisses           | DBus events                                                                               | process-session only; cleared on process exit                           |
| Do-not-disturb              | `NotificationService`                         | QE state JSON                                 | notification/control-center modules                 | `NotificationService`                  | service property                                                                          | persistent user preference; does not discard history by default         |
| Idle inhibition             | compositor protocol                           | `IdleInhibitor` state                         | control center/bar                                  | `IdleService`                          | Wayland state                                                                             | requested state is persistent; active inhibition remains ephemeral and loss of bound surface invalidates it |
| Selected monitor layout     | `MonitorLayoutService`                        | `monitor-layout.json`, versioned QE state     | Hyprland Lua config, control center                  | `MonitorLayoutService` via helper      | atomic write, Hyprland reload, then live-topology verification                            | persistent requested profile; live Hyprland topology remains separately confirmed         |
| View-local state            | owning QML view                               | QML properties                                | owning view                                         | owning view                            | local bindings                                                                            | ephemeral; not promoted without cross-view need                         |
| Generated thumbnails        | wallpaper cache adapter                       | QE cache directory                            | wallpaper selector                                  | cache adapter                          | manifest completion signal                                                                | cache only; malformed cache is deleted/regenerated                      |

State JSON files require a schema version from their first implementation.
Migration functions must be explicit and tested before a schema version is
incremented. Failed migration preserves the original file and starts with a
safe state accompanied by a diagnostic.
