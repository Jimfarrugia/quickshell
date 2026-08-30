# QE Implementation Plan

Status: Phases 1-6 complete; Phase 7 not started

Last inventory: 2026-08-29

This is the authoritative roadmap, implementation sequence, dependency map,
project-status reference, risk register, and architectural decision log for the
Quickshell Environment (QE). `docs/ARCHITECTURE.md` is authoritative for system
architecture, boundaries, ownership, and service contracts. If the documents
conflict, resolve the conflict explicitly and update both; do not silently pick
one.

## 1. Status Legend

- Verified fact: observed in current files, installed metadata, runtime state,
  official documentation, or Quickshell source.
- Accepted decision: selected by the user or required by an accepted constraint.
- Proposed detail: an implementation-level choice to verify in its scheduled
  phase without changing the architectural boundary.
- Assumption: temporary premise that must be tested or confirmed.
- Open question: unresolved and potentially blocking the named phase.
- Deferred decision: intentionally postponed until evidence is available.

## 2. Project Status

| Area | Status | Notes |
| --- | --- | --- |
| Discovery | Complete | Existing Hyprland, theme, wallpaper, desktop tools, and installed Quickshell inspected |
| Architecture | Complete for implementation start | Authoritative boundaries are in `docs/ARCHITECTURE.md` |
| Project code | Foundation implemented | Executable shell bootstrap, services, integration convention, schemas, themes, and tests exist |
| Foundation | Complete | Phase 1 acceptance passed on 2026-08-24 |
| Bar vertical slice | Complete | Phase 2; top reserved edge selected, tray host disabled during Waybar coexistence |
| Bar parity and Waybar cutover | Complete | Phase 3 acceptance passed 2026-08-25 |
| Theme/Matugen integration | Complete | Manual selector and external machine integration complete; Matugen mapping, staged promotion, QE-localized wallpaper selector, and Hyprpaper XDG-path application complete; external generated Matugen artifacts now delivered as QE-generated `wallpaper` theme slots applied by the external switcher, including imv, mpv, and Yazi; runtime/default artifact separation and idempotent promotion added; `QE_THEME_SWITCHER` wired for production through the installed `qe-theme-switcher` wrapper. Phase 4 acceptance passed on 2026-08-26 |
| Notifications/OSDs | Complete | QE owns notifications and OSDs; reversible Dunst cutover and rollback passed 2026-08-29 |
| Launcher/help | Not started | Phase 7 |
| Dashboards/control center | Not started | Phases 8-10 |
| Lock replacement | Not started | Phase 11 |
| Production hardening | Not started | Phase 12; final deployment location remains undecided |

### 2.1 Next-session handoff

- Read `AGENTS.md`, `docs/ARCHITECTURE.md`, and this plan in that order before making
  changes. Phases 1-4 are complete; Phase 4's approved semantic-token migration,
  transactional active-theme hot reload, dynamic catalog discovery, manual
  selector, and external machine integration are complete. Matugen mapping,
  staged promotion, the QE-localized wallpaper selector, and Hyprpaper
  IPC-confirmed application are complete.
- Phase 4's 33-role Matugen-style semantic-token contract was approved on
  2026-08-25 and its atomic in-repository migration is complete. Matugen and
  external-project work retain their separate approval gate.
- The semantic-token audit is complete. ADR-015 and ADR-027 record the approved
  33-role vocabulary and contrast policy; do not reopen the contract without
  concrete evidence and the planning change procedure.
- The reviewed Waybar module classification, metrics adapter contract, and
  narrow permission to edit `~/Projects/theme-switcher` were approved on
  2026-08-24. The authorization and implementation boundaries are recorded in
  the Phase 3 prerequisite and implementation records.
- Normal runtime is one guarded QE shell from `shell.qml`, reserving 26 pixels
  at the bottom with `trayHostEnabled` true. Waybar is absent from autostart and
  retired in theme-switcher; QE owns `org.kde.StatusNotifierWatcher`.
- The active authored/default QE theme is Poimandres. ADR-015 supersedes the
  provisional Phase 1 vocabulary while retaining the charging and tooltip
  semantics from ADR-012 and ADR-014.
- Full developer commands and expected markers are in `docs/VALIDATION.md`.
- QE-internal wallpaper-theme startup self-heal and external wallpaper source
  recovery are documented deferred items (see Deferred decisions); neither
  changes current behavior.
  The live NetworkManager loopback test is opt-in. Relocation was revalidated
  from `/tmp` at the Phase 2 exit.
- The palette viewer is implemented as a transient `qe-palette` surface. It
  displays the selected validated catalog theme's canonical semantic-token order
  (with `charging` last) or validated raw palette order, and copies normalized hex
  values through the native Quickshell clipboard property. Its view-local theme
  dropdown never applies or persists a theme; viewer chrome remains styled by the
  active theme. The dropdown, mode toggle, and grid are keyboard-focusable;
  dropdown options support j/k navigation, Enter/l selection, and h/Escape
  dismissal; l opens the focused dropdown. The mode toggle uses the shared binary
  `SegmentedToggle` and supports Enter/Space switching. q closes from every focus
  layer, while Escape closes an open
  dropdown before closing the viewer. The grid supports Tab mode switching, hjkl
  navigation, Enter/Space-to-copy, and a responsive second column above 25% of
  the active display width.
- Physical external-monitor attach, independent-output startup, reorder, detach,
  and mirror restoration passed in Phase 3. A connected mirror changed to
  extended does not create a new Qt `QScreen`; reconnect the output or restart
  QE after that specific transition.
- The project is not yet production-managed or installed in its final location;
  explicit development launch remains intentional until Phase 12.

## 3. Current-System Inventory

### 3.1 Configuration and session

Verified facts:

- `~/.config/hypr` is a symlink to
  `~/dotfiles/_hyprland/hypr/.config/hypr`.
- The active Hyprland configuration is Lua-based. `hyprland.lua` loads
  environment, monitors, keybindings, autostart, style, current theme, input,
  and window rules.
- Hyprland `0.56.2` is installed and was running during inventory.
- The session desktop file launches `/usr/bin/start-hyprland` directly.
- One internal monitor, `eDP-1`, was active at 1920x1080, scale 1.2, with a
  28-pixel bottom reserved area from Waybar.
- The repository currently runs from `~/Projects/quickshell`; Phase 12 will
  decide whether relocation provides enough benefit to justify migration.

Relevant files:

- `~/.config/hypr/hyprland.lua`
- `~/.config/hypr/autostart.lua`
- `~/.config/hypr/keybinds.lua`
- `~/.config/hypr/config/programs.lua`
- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/hyprlock.conf`
- `~/.config/hypr/hyprpaper.conf`

### 3.2 Current autostart and lifecycle

`~/.config/hypr/autostart.lua` currently starts:

- DBus/systemd environment import
- GNOME keyring secrets component
- Hyprpaper
- Hypridle
- Waybar
- `wl-paste --type text --watch cliphist store`
- `sudo keyd`, despite keyd also being an enabled system service
- Nextcloud
- terminal/tmux sessions

Dunst is DBus-activated through a static systemd user service and is not
explicitly launched by the Hyprland autostart file.

Migration implication: QE must not kill or replace these processes implicitly.
Each cutover changes the owning configuration explicitly and has a documented
revert.

### 3.3 Current bar

Waybar is configured at `~/.config/waybar` and starts on the bottom edge.

Current modules:

- network
- disk
- memory
- CPU
- temperature
- Pomodoro
- Hyprland workspaces
- system tray
- clipboard history
- idle inhibitor
- Bluetooth
- PipeWire/PulseAudio
- backlight
- battery
- clock

Current interactions and dependencies:

- network opens `nm-connection-editor`
- Bluetooth opens `blueman-manager`
- audio opens `pavucontrol`
- clipboard uses `cliphist`, Rofi, and `wl-copy`
- Pomodoro uses the external `waybar-module-pomodoro` executable
- temperature uses a hard-coded `/sys/class/hwmon/hwmon3/temp1_input`
- tray icon configuration contains an absolute `/home/jim` path
- Hyprland window rules assume a 28-pixel bar

Migration implication: a development QE bar must not reserve the same edge
while Waybar is active. Essential parity and reserved-area behavior must be
verified before Waybar autostart changes.

### 3.4 Current launcher and menus

- Super+R launches `rofi -show drun`.
- Super+Shift+R opens clipboard history through Rofi.
- Super+Escape opens a Rofi power menu.
- Theme and wallpaper selection are exposed through desktop entries/scripts.
- The power menu invokes `loginctl` and `systemctl` for lock/logout/power actions.

Rofi can coexist with QE until keybindings are deliberately switched.

### 3.5 Current lock and idle behavior

- Super+Backspace launches Hyprlock.
- Hypridle lowers brightness after 60 seconds and restores it on activity.
- Hypridle calls `loginctl lock-session` after 300 seconds and before sleep.
- Hyprlock uses `~/.local/share/current_lockscreen.png`, a profile image, battery
  helper output, and a periodically refreshed `fortune` quote.
- `/etc/pam.d/hyprlock` includes the system `login` PAM stack.
- Fingerprint packages were not installed during inventory.

Migration implication: the QE lock must cover manual lock, idle lock, and
before-sleep paths before Hyprlock is disabled. The existing visuals are parity
references, not security requirements.

### 3.6 Current notifications

- Dunst `1.13.2` owns `org.freedesktop.Notifications` through DBus activation.
- Super+N invokes `dunstctl history-pop`.
- Super+Shift+N invokes `dunstctl close-all`.
- Existing hardware scripts send replaceable Dunst notifications for volume,
  microphone mute, and brightness.

Only one notification server can own the DBus name. QE and Dunst cannot provide
notifications concurrently in one user bus. The accepted migration is staged.

### 3.7 Current audio, network, Bluetooth, power, and media stack

Verified installed versions during inventory:

| Dependency | Version/condition |
| --- | --- |
| Quickshell | 0.3.1-1 |
| Qt Declarative | 6.11.2-1 |
| PipeWire | 1.6.8 |
| WirePlumber | 0.5.15 |
| NetworkManager | 1.58.0 |
| BlueZ | 5.87 |
| UPower | 1.91.3 |
| `brightnessctl` | 0.5.1 |
| `playerctl` | 2.4.1 |
| Matugen | not installed |

Runtime observations:

- PipeWire exposed one built-in analog sink and source.
- NetworkManager reported connected/full connectivity.
- One powered BlueZ controller was present.
- `pavucontrol`, Blueman, and NetworkManager applet/editor packages were
  installed as fallbacks.

Current keybindings call:

- `~/.local/bin/volume` using `wpctl`
- `~/.local/bin/mic-mute-toggle` using `wpctl`
- `~/.local/bin/brightness` using `brightnessctl`
- `playerctl` for media actions

These scripts parse human command output and send Dunst notifications. QE will
replace their UI feedback only after corresponding domain services and OSDs are
ready.

### 3.8 Current theme workflow

The selector `~/.local/bin/select_theme` enumerates desktop entries under
`~/.local/share/applications/themes`, opens Rofi, and calls:

```text
~/Projects/theme-switcher/run.sh <theme>
```

The switcher:

- runs every `apply/apply_*.sh` in lexical glob order
- is fail-fast because it uses `set -euo pipefail`
- applies themes to bat, btop, Dunst, eza, FZF, GTK, Hyprland, Hyprlock, imv,
  Kitty, mpv, Neovim, OpenCode, Rofi, Starship, tmux, Waybar, and Yazi
- emits human-oriented stdout rather than structured status
- writes `~/.local/share/theme_data` only after all apply scripts succeed
- automatically launches the wallpaper picker outside KDE
- mutates or copies active files in many application configuration directories
- restarts Dunst and Waybar and signals several running applications

Nine currently selected theme IDs were found:

```text
catppuccin
dracula
eldritch
everforest
gruvbox
nord
poimandres
rose_pine
tokyo_night
```

The collections are not complete for every application. FZF and OpenCode have
known gaps or mappings to built-in themes.

Current theme state is effectively split across:

- `~/.local/share/theme_data`
- copied/generated active files
- Neovim's `.current_theme`
- OpenCode's `tui.json`
- live application state

`~/.local/share/theme_data` is a legacy compatibility source, not a suitable QE
state file.

### 3.9 Current wallpaper workflow

The external theme switcher launches `~/Projects/wallpaper-picker`, a separate
Quickshell project. It:

- reads the selected theme from `~/.local/share/theme_data`
- lists wallpapers under `~/Pictures/Wallpaper/themes/<theme>`
- generates cached ImageMagick thumbnails and a manifest
- runs `set_wallpaper.sh` asynchronously after selection

The wallpaper helper:

- queries focused monitor resolution through `hyprctl` and `jq`
- validates and transforms an image with ImageMagick
- writes `~/.local/share/current_wallpaper.png`
- writes a gradient `~/.local/share/current_lockscreen.png`
- kills and restarts Hyprpaper
- records the source wallpaper in `theme_data`

The generated display and lock images are derived artifacts. The source image
path is the selected input. The current helper does not provide structured
confirmation that Hyprpaper displayed the image.

### 3.10 Verified Quickshell 0.3.0 capabilities

Native installed modules include:

- Hyprland IPC and global shortcuts
- Bluetooth/BlueZ
- Networking/NetworkManager
- PipeWire
- MPRIS
- UPower and power profiles
- system tray and DBus menus
- notification server
- PAM
- `WlSessionLock`
- Wayland idle inhibition/monitoring
- desktop entry discovery
- file watching, JSON adapters, processes, IPC, and persistent properties

Important limits:

- no native brightness API
- no general QML DBus binding
- MPRIS playback position needs a bounded timer for continuous display
- notification history must be implemented by QE
- complex NetworkManager profiles are not trivial through the native API
- Bluetooth pairing-agent completeness needs verification
- only the process that owns a secure `WlSessionLock` can release it
- a lock-owner crash leaves the compositor securely locked and unrecoverable by
  a replacement client

The installed Quickshell package is now 0.3.1-1 and the local source reference is
0.3.1. Notification APIs used in Phase 5 are verified against the installed
0.3.1 metadata; future upgrades must repeat this check.

## 4. Accepted Requirements and Decisions

Accepted decisions:

- Use a persistent QE process and a separate lock process.
- Use strict JSON for QE user configuration and themes.
- Treat QE and external desktop themes as independently authoritative scopes.
- A QE theme selection commits QE first, then automatically requests the same
  external theme as best effort.
- External failure warns but does not roll back or invalidate QE success.
- If QE theme validation or persistence fails, do not invoke the external apply.
- Matugen generates both the QE `Wallpaper` theme and supported external app
  artifacts.
- Changing wallpaper while `Wallpaper` is active regenerates and reapplies it.
- Refactor the external theme switcher to provide a stable machine contract.
- Keep notification history only for the current QE process initially.
- Keep Dunst until QE notifications pass staged acceptance and rollback tests.
- Use a bar as the first user-visible vertical slice.
- Defer production supervision until runtime evidence exists.

Documentation requirement: keep `docs/USER_GUIDE.md` concise and user-facing.
Do not add or update content in the user guide without explicit user approval.
Suggestions for additions or updates may be made, but approval is required
before implementation. Record technical detail, implementation status,
validation procedures, and internal decisions in the authoritative project
documents instead.

Known requirements:

- No absolute project path assumptions.
- UI components never directly own external commands or output parsing.
- Every integration has explicit startup, update, timeout, reconnection, stale,
  and degraded behavior.
- Native event-driven APIs are preferred over polling.
- All generated artifacts remain separate from authored inputs.
- Replacements coexist safely and preserve fallbacks until cutover criteria pass.
- Lock security is compositor-enforced and must fail closed.

## 5. Assumptions, Open Questions, and Deferred Decisions

### Assumptions to verify

- Quickshell 0.3.0's installed native services are stable enough for the first
  bar slice.
- A non-exclusive or alternate-edge development bar can coexist with Waybar
  without disrupting daily use.
- Current manually authored theme palettes can be mapped to one complete QE
  semantic-token schema without changing their visual identity.
- Matugen templates can generate valid artifacts for the selected external
  target set before any apply step runs.
- The existing PAM stack is suitable for initial password authentication.

### Open questions that block named phases

| Question | Blocking phase | Resolution point |
| --- | --- | --- |
| Which Hyprpaper IPC path gives reliable apply confirmation? | Phase 4 | Compare current helper with current Hyprpaper documentation/runtime |
| Does native Bluetooth cover required interactive pairing prompts? | Phase 9 full dashboard | Test with new device and inspect API behavior |
| Which NetworkManager features are required beyond PSK/known networks? | Phase 10 | Define dashboard v1 acceptance before profile editor work |
| Which PAM service should QE use in production? | Phase 11 | Security review of `login`, `hyprlock`, or dedicated approved config |

### Deferred decisions

- systemd user service versus Hyprland autostart for production
- final visual design and animation language
- persistent notification history and retention/privacy schema
- fingerprint authentication
- enterprise Wi-Fi, hidden networks, VPN, proxy, and full profile editing
- Bluetooth OBEX and advanced profile management
- advanced PipeWire graph/routing editor
- automatic external-to-QE theme synchronization
- cross-compositor portability
- exact multi-monitor bar policy beyond supporting safe per-screen construction
- startup self-heal for the generated `wallpaper` theme: on QE start, regenerate
  only when the active wallpaper theme was not produced from the currently
  selected source image (identity-checked via a QE-owned fingerprint; skips the
  current unconditional startup regeneration and self-heals a replaced source
  file). No behavior change is requested now; it would be a small QE-internal
  addition.
- external wallpaper source recovery: sync the selectable `wallpaper` theme with
  a wallpaper set outside QE while QE was stopped. This blocks on the standalone
  `wallpaper` script recording its source path somewhere QE can read, or on QE
  generating from the derived raster (palette approximation; violates the
  source-versus-derived and `wallpaperRoot` boundaries). Requires an external
  change or an accepted approximation, so it is deferred.

These deferred decisions must not be silently implemented as defaults.

## 6. Dependency Map

```text
Phase 1 Foundation
  |-- configuration, paths, diagnostics, adapter health
  |-- theme contract and state schema
  `-- test harness
        |
        +--> Phase 2 Bar vertical slice
        |      `--> Phase 3 Bar parity and Waybar cutover
        |
        +--> Phase 4 Theme switcher + Matugen + wallpaper/theme selectors
        |
        +--> Phase 5 Notification prototype
        |      `--> Phase 6 Notification cutover + OSDs
        |
        +--> Phase 7 Launcher + help
        |
        +--> Phase 8 Control center + audio dashboard
        |      +--> Phase 9 Bluetooth dashboard
        |      `--> Phase 10 Network dashboard
        |
        `--> Phase 11 Secure lock replacement

Phases 3-11 complete enough for daily use
        `--> Phase 12 production supervision, deployment decision, and cleanup
```

Interfaces that must be stable before parallel feature work:

- configuration access and validation
- resolved semantic theme facade
- common service health/error model
- operation IDs and pending/confirmed semantics
- paths and persistent state APIs
- command runner timeout/result contract
- module registration/surface-opening convention
- diagnostics logging categories

The Phase 2 bar review must classify every current Waybar module into the
essential cutover set, an explicit deferred QE feature, or an external fallback.
The initial proposed essential set is workspaces, tray, network, audio,
brightness, battery, clock, CPU, memory, disk, and temperature. Bluetooth and
idle inhibition are expected unless their adapters miss Phase 3 criteria.
Clipboard history remains available through its existing keybinding while its
QE surface is deferred. Pomodoro remains an external Waybar module or separate
tool and is not required for the first Waybar cutover.

After Phase 1, independent agents may safely work on native integration adapters
and reusable components. They must not concurrently change the shared service
contract without coordinating through an architecture decision.

## 7. Feature Responsibility Matrix

| Feature | Responsibilities | Explicit non-goals for first version | Dependencies/services | Degraded behavior | Deferrable? |
| --- | --- | --- | --- | --- | --- |
| Bar | Workspaces, clock, tray, selected system indicators, module launch points | Every current custom Waybar module before first slice | Theme, config, compositor, tray, power, audio, network, Bluetooth, metrics | Per-module unavailable state; bar remains usable | No, first slice |
| Lock | Secure surfaces, PAM conversation, time/battery/background | Fingerprint, rich dashboards, notification handling | lock-safe config/theme, PAM, session lock, UPower optional | Fail closed; optional visuals omitted | Yes until Phase 11 |
| Launcher | Discover, filter, rank, launch desktop entries | File search, arbitrary shell evaluation, plugins | DesktopEntries, theme, config | Explain launch failure; omit invalid entries | Yes |
| Notification popups | Own DBus server, lifecycle, actions, urgency, DND policy | Disk history initially | NotificationService, theme, config | Ownership conflict prevents readiness; no silent loss claim | No before notification center |
| Notification center | Current-process history, dismiss/actions, DND controls | Cross-restart history | NotificationService | Empty/unavailable state if server not owner | Yes until popups stable |
| Control center | Compose quick settings and health/system information | Reimplement every dashboard inline | Domain services, module router | Individual tile unavailable | Yes |
| OSDs | Coalesced feedback for confirmed/pending operations | Use desktop notifications as OSD transport | OSD plus domain services | Show failure or suppress if source unknown | No before keybind migration |
| Bluetooth dashboard | Adapter/device discovery and common lifecycle actions | OBEX, guaranteed every pairing-agent mode | BluetoothService | Existing Blueman remains fallback | Yes |
| Network dashboard | Connectivity, Wi-Fi, known/PSK connections | Enterprise/VPN/full editor initially | NetworkService | Existing NM editor remains fallback | Yes |
| Audio dashboard | Input/output defaults, levels, mute, common streams | Full patchbay initially | AudioService | Existing pavucontrol remains fallback | Yes |
| Help | Curated keybindings/commands/reference | Claim live keybind authority from duplicated data | HelpService, config | Show source age/error | Yes |
| Wallpaper selector | Discovery, previews, apply, generated cache | Own image editing suite | WallpaperService, theme, helper | Prior wallpaper remains; cache regenerates | Yes |
| Theme selector | QE theme discovery/apply and external result status | Force external scope to match QE permanently | ThemeService, external switcher | QE can succeed with external warning | No for theme phase |
| Clipboard history | Open/search/decode clipboard history without duplicating clipboard storage ownership | Replace `cliphist` storage daemon initially | Clipboard adapter, launcher-style surface | Existing Rofi flow remains available | Yes |
| Pomodoro | Surface timer state/actions if a stable external contract is established | Reimplement or parse undocumented process state during bar cutover | Future timer service/adapter | Existing external tool remains separate | Yes |

## 8. Implementation Phases

### Phase 0: Planning baseline

Status: Complete

Objective: establish verified inventory, architectural boundaries, ownership,
risks, and implementation sequencing.

Deliverables:

- `docs/PLAN.md`
- `docs/ARCHITECTURE.md`
- `AGENTS.md`

Exit criteria:

- blocking ownership questions answered
- current integration points identified
- phases have measurable criteria and rollback paths
- planning documents contain no contradictory source of truth

Validation:

- cross-document review
- source/path spot checks against current system

Out of scope:

- all application code and production configuration changes

### Phase 1: Platform foundation

Status: Complete (2026-08-24)

Objective: create the smallest executable shell architecture with validated
configuration, paths, theme state, diagnostics, tests, and adapter conventions.

Prerequisites:

- Phase 0 complete
- installed Quickshell 0.3.0 APIs reconfirmed

Scope:

- `shell.qml` bootstrap only; no replacement cutover
- directory/module structure from `docs/ARCHITECTURE.md`
- `ConfigService`, `PathsService`, diagnostics, persistent state schema
- common integration health/error and operation semantics
- command runner with timeout, cancellation, bounded output, and structured result
- QE theme schema v1 and `ThemeService`
- convert Poimandres and at least one visually contrasting existing palette
- fallback emergency palette
- QML lint, JSON/theme validation, helper lint, and smoke-test commands
- test fixtures for valid/invalid config, theme, state, and command output

Likely affected files/subsystems:

- `shell.qml`
- `services/`
- `integrations/`
- `config/`
- `themes/`
- `utils/`
- `tests/`

Deliverables:

- shell starts without opening conflicting desktop surfaces
- config and active theme load without absolute paths
- live theme switching updates a harmless test surface
- invalid updates retain last-known-good state and emit diagnostics
- documented developer validation command set

Acceptance criteria:

- all QML passes `qmllint`
- shell remains alive through the smoke-test timeout
- every authored theme fixture passes schema validation
- malformed config/theme/state fixtures produce expected fallback behavior
- command timeout and malformed-output fixtures cannot mutate confirmed state
- moving a copy of the project to a temporary path does not break asset paths

Validation:

- static lint and schema tests
- automated QML/service tests where supported
- smoke launch with optional dependencies unavailable or mocked
- inspect logs for duplicate subscriptions after a soft reload

Rollback/recovery:

- no production process is replaced; stop QE and remove its XDG test state

Out of scope:

- full bar, notification ownership, Matugen installation, dashboards, lock

Implementation record:

- Installed Quickshell `0.3.0-2` metadata reconfirmed for `ShellRoot`, reload-safe
  `Singleton`, `FileView`, XDG path helpers, `Process`, and stream parsers.
- The provisional Phase 1 theme-v1 semantic tokens were `surfaceBase`, `surfaceRaised`,
  `surfaceOverlay`, `textPrimary`, `textSecondary`, `accentPrimary`,
  `accentSecondary`, `border`, `tooltip`, `success`, `charging`, `warning`,
  `error`, `shadow`, and `scrim`. `charging` and `tooltip` were added by explicit
  pre-release contract revisions. Palette keys remain theme-authored color
  names. ADR-015 supersedes this pre-Phase-4 vocabulary.
- Poimandres and Gruvbox Dark validate against the runtime contract and JSON
  Schema. Invalid themes degrade the catalog locally without blocking valid
  entries.
- Config and active-theme state retain confirmed or last-known-good values after
  malformed input. A cold-start test confirmed persisted-theme precedence over
  the configured default.
- Command contract tests cover timeout with TERM-to-KILL escalation, malformed
  structured output, missing executable, bounded streaming output retention,
  and a valid structured result. Failed results do not mutate fixture-confirmed
  state.
- `qmllint`, runtime and JSON Schema fixture tests, service tests, and the
  persistent-shell smoke test pass. A relocated copy under `/tmp` passes the
  same JSON tests and starts without source-path changes.
- A disposable relocated shell completed one watched-source soft reload with a
  single reload event and no duplicate-subscription diagnostics.
- No production process, desktop owner, autostart, keybinding, or external
  project was changed. The preview remains an ordinary harmless window.

### Phase 2: Bar vertical slice in coexistence mode

Status: Complete (2026-08-24)

Selected coexistence profile: top edge with its own reserved area, while the QE
tray host remains disabled and the existing bottom Waybar continues to own the
desktop tray. This replaces the initial non-exclusive profile after live testing
showed that overlaying application windows was undesirable.

Objective: validate the architecture end-to-end with a useful bar that does not
replace Waybar yet.

Prerequisites:

- Phase 1 exit criteria pass
- bar placement/coexistence mode selected for the active monitor

Scope:

- reusable panel/module components
- Hyprland workspaces and focused-window summary
- clock
- system tray
- UPower battery
- PipeWire output volume/mute indicator
- NetworkManager connectivity summary
- integration status representation
- non-exclusive or alternate-edge development mode
- a coexistence configuration that does not instantiate the QE tray host while
  Waybar is active; enable it only during an explicit Waybar-absent tray test

Likely affected files/subsystems:

- `modules/bar/`
- `components/`
- `services/CompositorService.qml`
- `services/AudioService.qml`
- `services/PowerService.qml`
- `services/NetworkService.qml`
- corresponding `integrations/`

Deliverables:

- one themed bar surface per configured screen policy
- essential modules consume domain services only
- tray menu and activation behavior
- unavailable-state fixtures for every included integration
- reviewed cutover classification for every current Waybar module

Acceptance criteria:

- no direct `Process` or external path appears in bar presentation files
- workspace changes and focus update reactively
- tray items appear/disappear without restarting QE
- audio, battery, and network changes update from native events
- daemon loss degrades only its module
- Waybar remains usable and its reserved area is not disturbed
- QE's tray host is disabled during normal Waybar coexistence, so the tray
  renders in exactly one bar; QE tray behavior is tested during an explicit
  temporary Waybar-absent test and Waybar is restored
- theme changes update the live bar without recreation

Validation:

- lint/tests/smoke launch
- disconnect/restart optional daemons where safe or use fixtures
- attach/detach an external monitor if available, otherwise defer physical test
- measure idle CPU and check for undocumented polling

Implementation and validation record:

- The development bar uses a 26-pixel reserved top edge; the existing Waybar
  retains its 28-pixel bottom edge. Hyprland reported reserved areas
  `[0, 26, 0, 28]` with both bars active, and application windows no longer sit
  beneath QE.
- The workspace module renders only positive-ID numbered workspaces and is
  centered independently of the right-side indicators. The focused-window title
  was removed from the bar after live review.
- The Phase 2 styling baseline uses a borderless 26-pixel bar with no vertical
  component inset, JetBrainsMono Nerd Font at 14 pixels for bar text, and
  Material Symbols Rounded at 16 pixels for project icons. Inter remains the
  configured sans-serif family outside this bar baseline. Workspaces use
  `circle`/`adjust`; audio uses `volume_mute`, `volume_down`, or `volume_up` by
  level and `volume_off` while muted; battery state
  uses the `battery_android_alert` and `battery_android_frame_1` through
  `battery_android_frame_full` level sequence. Network is
  anchored on the left while numbered workspaces remain centered; workspace
  glyphs use a 6-pixel visual gap.
- Bar icons default to `accentSecondary`; non-icon labels default to
  `textSecondary`. Active workspace icons use `accentSecondary` while inactive
  workspace icons use `textSecondary`. The clock keeps its date in
  `textSecondary` and renders its 12-hour time plus uppercase AM/PM in
  `accentSecondary`; date/time spacing is 16 pixels. The
  visible left and right edge gaps are half their previous size.
- Battery levels at 15% or below use the error token for text and icon; 16-24%
  uses warning. Higher levels retain normal text and icon colors, with the
  charging token applied to the icon while charging.
- UPower 0.3.0 exposes charge as a normalized `0.0` to `1.0` value. The adapter
  now converts it to a percentage; live comparison showed QE at 88% and Waybar
  at 87%, replacing the incorrect 1% display.
- PipeWire, NetworkManager, UPower, Hyprland, and clock services use native
  event-driven APIs. Fixture injection verifies localized unavailable and stale
  states without degrading unrelated services.
- Network presentation prefers connected Wi-Fi and shows its SSID in
  `accentSecondary`, signal percentage, and `wifi` icon. It falls back to a
  connected wired interface's IPv4 address and `lan`, or `Disconnected` with an
  error-colored `signal_wifi_bad`. Quickshell 0.3.0 does not expose IP addresses,
  so native NetworkManager events trigger a bounded, validated `nmcli` IPv4
  enrichment lookup without polling; stale in-flight lookups are cancelled or
  superseded. Fixture states and a live loopback lookup cover the contract.
- During the approved Waybar-absent test, QE acquired
  `org.kde.StatusNotifierWatcher`, discovered the existing Nextcloud item, and
  rendered its SNI icon in the top bar without reload errors. After enabling
  Quickshell's required `UseQApplication` mode, right-click menu positioning and
  left-click activation passed live review. QE was then stopped,
  `trayHostEnabled` restored to `false`, and Waybar restarted; DBus ownership
  returned to Waybar while QE ran in normal coexistence mode.
- Static QML lint, JSON/runtime schema tests, Phase 1 regressions, Phase 2
  service fixtures, live shell smoke tests, and the reserved-area check pass.
- The persistent shell averaged 0.4% CPU during the sampled idle interval. The
  only production timer is the documented consumer-gated, minute-aligned clock;
  other timers are command deadlines or test watchdogs.
- Physical external-monitor attach/detach was unavailable with only `eDP-1`
  connected and is explicitly carried into the Phase 3 multi-monitor validation.

Reviewed Waybar cutover classification:

| Current Waybar module | Classification | Phase/rollback disposition |
| --- | --- | --- |
| `hyprland/workspaces` | Essential cutover | Implemented in Phase 2; retain Waybar until Phase 3 cutover |
| `network` | Essential cutover | Implemented in Phase 2; `nm-connection-editor` remains an external fallback |
| `pulseaudio` | Essential cutover | Output summary implemented in Phase 2; `pavucontrol` remains available |
| `battery` | Essential cutover | Implemented in Phase 2 with UPower-native state |
| `clock` | Essential cutover | Implemented in Phase 2 |
| `tray` | Essential cutover | Adapter/UI implemented; enable host only when Waybar is stopped at cutover |
| `disk` | Essential cutover | Phase 3 system-metrics adapter |
| `memory` | Essential cutover | Phase 3 system-metrics adapter |
| `cpu` | Essential cutover | Phase 3 system-metrics adapter |
| `temperature` | Essential cutover | Phase 3 system-metrics adapter with discovered sensor selection |
| `backlight` | Essential cutover | Phase 3 brightness adapter; preserve `brightnessctl` fallback |
| `bluetooth` | Conditional essential | Phase 3 if native adapter acceptance passes; preserve Blueman fallback |
| `idle_inhibitor` | Conditional essential | Phase 3 if native protocol acceptance passes |
| `custom/cliphist` | Deferred QE feature | Preserve existing clipboard keybinding/tool through cutover |
| `custom/pomodoro` | External fallback | Not required for first cutover; keep separate tool or Waybar fallback profile |
| `custom/power` (inactive) | External fallback | Existing Rofi power menu remains available |
| `custom/nextcloud` (inactive) | Deferred | Status notifier item covers active tray use; custom poller remains disabled |

Rollback/recovery:

- stop the development QE process; Waybar remains unchanged

Out of scope:

- Waybar autostart changes, all existing modules, final visual polish

### Phase 3: Essential bar parity and Waybar cutover

Status: Complete (2026-08-25; acceptance, cutover, fresh-login, rollback, and
physical multi-monitor validation passed)

Objective: make the QE bar sufficient for daily use and replace Waybar through a
reversible configuration change.

Prerequisites:

- Phase 2 stable during regular use
- system metrics adapter design contract approved; implementation and validation
  occur in this phase
- Phase 2's current-module classification and essential cutover set are approved
- explicit approval to edit the separate `~/Projects/theme-switcher` project for
  the target-retirement prerequisite

Prerequisite record:

- The user confirmed Phase 2 stability during regular use and approved the
  reviewed current-module classification and essential cutover set on
  2026-08-24.
- The user approved the Phase 3 system-metrics adapter contract on 2026-08-24:
  `SystemMetricsService` owns normalized per-metric health, values, and consumer
  lifecycle; `/proc/stat` and `/proc/meminfo` use asynchronous `FileView` reads
  on one two-second cadence with pure fixture-tested parsers; a bounded
  structured helper owns thermal discovery/read and disk capacity; stable
  sensor attributes replace `hwmonN` assumptions; last-known values become
  stale at the Poller Registry thresholds; pollers stop with no configured
  consumers.
- Phase 3 cost validation refined that approved boundary without changing its
  normalized service contract or cadence: the helper performs thermal
  discovery/rediscovery, while recurring selected-sensor reads use asynchronous
  `FileView`; live root-disk reads use a validated shell/`df` fast path under the
  same structured helper contract. This removed recurring Python startup cost.
- The user authorized the narrow `~/Projects/theme-switcher` target-retirement
  implementation on 2026-08-24 after reviewing its planned files, validation,
  inactive initial state, activation timing, and rollback. This approval does
  not authorize a theme application or the Waybar/Hyprland cutover itself.

Scope:

- CPU, memory, disk, and discovered temperature sensors
- Bluetooth summary
- brightness summary
- idle inhibition control
- clipboard launch point or explicit deferral
- configured module ordering and monitor policy
- bar spacing/reserved-area parity
- remove reliance on hard-coded `hwmon3`
- add and test an external theme-switcher target-retirement control that skips
  Waybar before Waybar autostart is disabled; this narrow compatibility change
  precedes the complete machine-contract refactor in Phase 4

Likely affected files/subsystems:

- bar modules and system metric/brightness/idle services
- `config/qe.json`
- narrow target-retirement support in `~/Projects/theme-switcher`
- eventually `~/.config/hypr/autostart.lua` and affected window rules

Deliverables:

- daily-use bar profile
- migration checklist and one-command/config revert instructions
- comparison record against current Waybar behavior

Acceptance criteria:

- all agreed essential modules pass normal/unavailable/stale tests
- polling intervals are documented and measured
- pollers satisfy the budget and consumer-lifecycle rules in the authoritative
  Poller Registry
- QE reserves the correct edge on each configured monitor
- starting a second QE instance is prevented or fails clearly
- Waybar can be disabled without losing essential indicators or tray
- the QE tray host is enabled as part of removing Waybar autostart
- applying an external theme after cutover does not start or restart Waybar
- restoring the prior autostart/window configuration restores Waybar

Validation:

- full-session trial with Waybar manually absent before permanent config edit
- login/restart test after cutover
- rollback exercise

Implementation record (initial slice, 2026-08-24):

- Added consumer-gated CPU and memory reads from `/proc/stat` and
  `/proc/meminfo` on one two-second cadence, plus bounded structured thermal and
  root-disk helper reads at five and thirty seconds. CPU/memory, thermal, and
  disk poll independently according to configured visible consumers.
- Thermal discovery selects by sensor name/label, retains the selected sensor
  path for subsequent reads, and rediscovers after three failures. No `hwmonN`
  index is hard-coded. Structured helper output is schema-versioned, bounded,
  and validated as a complete document before state publication.
- The first five-minute poller measurement failed at 1.84% average CPU, with
  1.56 percentage points isolated to recurring helper children. Replacing
  five-second Python sensor reads with selected-path `FileView` reads and adding
  the validated live disk fast path reduced a diagnostic minute to 0.25%. The
  authoritative 300-second repeat on persistent QE PID 3072743 measured 0.22%
  total CPU including reaped children (60 parent ticks, 8 child ticks at 100 Hz)
  and RSS changed from 143920 KiB to 143976 KiB (+56 KiB), passing the under-0.5
  percentage-point bar budget. A direct selected-sensor adapter fixture proves
  recurring reads do not launch the discovery helper.
- Current monitor validation covers one 1920x1080 `eDP-1` output at scale 1.2,
  with QE reserving 26 pixels top and Waybar 28 pixels bottom. Multi-monitor
  validation remains pending because no second output is available.
- Added compact ordered CPU, memory, disk, and temperature bar modules backed
  only by `SystemMetricsService`, including loading, unavailable, stale,
  last-known-value, and recovery fixture coverage. Metric enablement and order
  mismatches fall back transactionally to a consistent enabled order.
- Live follow-up fixed initial procfs reads after consumer activation and cached
  hwmon reads through `/sys/class/hwmon` symlinks. The selected `coretemp`
  package sensor now remains readable between discovery cycles. Metrics render
  immediately to the right of network on the bar's left side; temperature uses
  warning above 70 C and error above 80 C.
- Added an optional delayed `BarChip` hover popup that renders outside the panel
  through a themed `PopupWindow`. The reviewed initial content contract leaves
  brightness empty, shows UPower's native time-to-full while charging and
  time-to-empty otherwise, and shows `Fully charged.` for confirmed fully charged
  state (with unavailable rather than a fabricated duration). Idle inhibition is
  labeled `Requested` or `Disabled`. All bar hover text uses the configured
  sans-serif family at 13 pixels. The reviewed content also covers disk mount and
  capacity, memory used/total, aggregate CPU source/status, selected temperature
  sensor, connected Bluetooth device batteries, active audio output, and network
  type/interface/SSID/IPv4/connectivity. Brightness intentionally remains empty.
- Added the brightness vertical slice on the right side immediately left of
  battery. `BrightnessService` separates confirmed and pending percentages,
  clamps writes to 1-100 percent, and coalesces rapid five-percent wheel steps.
  A bounded `brightnessctl` helper owns discovery and writes; successful writes
  include an authoritative post-write read before confirmation. The active bar
  consumer uses asynchronous reads of the validated sysfs device on the Poller
  Registry's 10-second cadence and stops all polling when disabled. Fixture and
  live read-only adapter tests cover parsing, clamping, coalescing, failures,
  consumer lifecycle, icon thresholds, and confirmed-versus-requested state.
- Added matching five-percent wheel control to the audio bar module through
  `AudioService`. Requested volume is visibly distinct from the confirmed
  PipeWire value and reconciles only from native volume events; unavailable
  audio rejects wheel operations without reaching the adapter.
- Added a read-only Bluetooth bar summary before audio on the right side using
  the installed `Quickshell.Bluetooth` API. It distinguishes no controller,
  powered off, powered on, transition, and connected service states; no
  controller and powered-off states intentionally share the persistent
  disabled/error bar visual. It normalizes device
  names and reported battery values for hover detail; and updates only
  from BlueZ events. Fixture tests cover disabled, connected, multiple-device,
  pending, in-place device-property changes, and daemon/controller-loss states,
  while a live read-only test verifies the development controller without
  changing its power or devices.
  Blueman launch and interactive connect/pair controls remain pending their
  application-launch and pairing-agent contracts.
- Added the ADR-013 requested-only idle-inhibitor toggle before Bluetooth. One
  `IdleService` session request owns one native Wayland `IdleInhibitor`, selects
  a visible registered bar window, fails over across monitor-window loss, and
  releases the request when disabled, when configuration hides the control,
  when the final owner disappears, or when QE exits. The request defaults off,
  is not persisted, leaves Hypridle/manual lock/suspend policy unchanged, and
  is never labeled compositor-confirmed active because Quickshell 0.3.0 exposes
  no confirmation signal. Unlike the previous Waybar module, QE applies no
  automatic timeout; the requested state remains until explicitly toggled or
  forced release by configuration/window/process loss. Lifecycle fixtures
  cover unavailable requests,
  toggle state, owner failover, final-owner loss, and configuration disable.
- Added `scripts/run-qe.sh` as the canonical persistent-shell entry point. It
  resolves the project path and uses Quickshell 0.3.0's per-configuration lock
  through `--no-duplicate`; a sandbox test proves a duplicate launch reports
  the running instance, exits without disturbing it, and leaves exactly one
  process. Production autostart must use this wrapper when cutover is approved;
  no live autostart change has been made.
- Started the approved controlled full-session Waybar-absent trial on
  2026-08-25 at 01:36 local time. Waybar stopped cleanly; one guarded QE process
  (initial PID 4035870) remained; a duplicate guarded launch was rejected; and
  `eDP-1` changed from `[0, 26, 0, 28]` coexistence reservations to
  `[0, 26, 0, 0]`. QE's PID owns `org.kde.StatusNotifierWatcher`, reports a
  registered host, and exposes the registered Nextcloud status-notifier item.
  At trial start, `config.bar.trayHostEnabled` was temporarily `true` while
  autostart, Hyprland configuration, and theme-switcher retirement remained
  unchanged pending manual
  tray activation/menu and daily-use review; avoid applying an external theme
  during this trial because the still-active Waybar target would restart it.
- The user accepted the live trial at 2026-08-25 07:06 AEST after confirming the
  Nextcloud tray activation/menu, module interactions and tooltips, workspace
  behavior, idle inhibition, brightness/volume scrolling, and general
  Waybar-absent layout. The trial remains active; this acceptance does not by
  itself activate theme-switcher retirement or modify live autostart.
- The user approved permanent cutover after the accepted trial. At 2026-08-25
  07:12 AEST, `~/.local/bin/qe-shell` was linked to the symlink-safe guarded
  launcher, `~/.config/hypr/autostart.lua` replaced its Waybar launch with that
  stable QE launcher, and `~/Projects/theme-switcher/retired-targets` activated
  `waybar`. The original autostart is backed up at
  `~/.config/hypr/autostart.lua.qe-phase3-20260825-0706.bak`. Lua syntax,
  launcher duplicate rejection, switcher syntax/ShellCheck/all 22 sandbox tests,
  active retirement-list validation, one-QE/no-Waybar process state, top-only
  reservation, and QE watcher ownership pass. At that point, fresh-login and
  exercised rollback/re-cutover validation remained before Phase 3 completion.
- The approved rollback/re-cutover exercise passed on 2026-08-25. Rollback
  stopped QE first, restored `trayHostEnabled: false`, Waybar autostart, an empty
  retirement list, and removed the stable launcher link. Guarded coexistence QE
  plus Waybar then restored `[0, 26, 0, 28]`; Waybar PID 4091716 owned the
  watcher and recovered the pre-registered Nextcloud item. Re-cutover stopped
  both bars, restored `trayHostEnabled: true`, QE autostart, active Waybar
  retirement, and the launcher link. One guarded QE process (initial PID
  4094581), no Waybar, `[0, 26, 0, 0]`, duplicate rejection, and QE watcher
  ownership all revalidated. Only a real fresh-login test remains before Phase
  3 completion; the original autostart backup is retained.
- After re-cutover review, the user selected the bottom edge as the authored and
  fallback QE bar position. `bar.edge` defaults to `bottom`; the shared tooltip
  anchor uses its bottom-edge branch to position hover surfaces above their
  associated modules. One persistent guarded QE instance produced the expected
  live Hyprland reservation `[0, 0, 0, 26]`, with Waybar still absent and QE
  retaining watcher ownership.
- Fresh-login validation passed on 2026-08-25 at 07:52 AEST. Hyprland autostart
  launched exactly one guarded QE process (PID 1132) through the stable launcher;
  Waybar was absent; a duplicate launch was rejected; `eDP-1` reserved
  `[0, 0, 0, 26]`; QE's PID owned `org.kde.StatusNotifierWatcher`; the Nextcloud
  item was registered; and active Waybar retirement remained valid. The user
  confirmed the rebooted bar appeared and functioned normally.
- The user declined a temporary Hyprland headless-output test and chose to defer
  multi-monitor acceptance until physical hardware became available. At that
  point Phase 3 remained open; no virtual output was created or changed.
- Physical multi-monitor acceptance subsequently passed with `eDP-1` and an LG
  `HDMI-A-1` display. With HDMI physically absent, a temporary extended rule was
  loaded; physical attach created a second logical output, workspace 2, one QE
  layer, and `[0, 0, 0, 26]` reservation while eDP retained workspace 1, one QE
  layer, and the same reservation. Moving HDMI from logical x=1600 to x=-1536
  preserved both bars, reservations, independent workspaces, one QE process,
  and tray ownership. Physical detach removed only HDMI's output/layer while
  eDP remained unchanged. The original mirrored `monitors.lua` was restored
  byte-for-byte from its backup, reloaded without errors, and the user confirmed
  normal mirroring after reconnect.
- A connected mirror changed to extended at runtime does not cause Qt 6.11 to
  expose a second `QScreen`, so QE cannot add a bar for that specific transition
  until the connector is reannounced or QE restarts. A fresh physical attach
  under an extended rule works correctly; this limitation and recovery are now
  documented rather than misrepresented as QE state.
- Post-acceptance tray polish gives each tray delegate the same eight-pixel
  horizontal padding, configured inter-module spacing, seven-pixel radius, and
  `tooltip` hover background as other bar modules.
  Every tray item retains its native reactive pixmap source for
  application-controlled variants, while a `ColorOverlay` replaces source RGB
  with the current default bar icon token, `secondary`, using only source alpha
  as the mask. This intentionally presents all tray icons with one uniform
  monochrome color while preserving their transparency, shape, and source
  updates. A fixture proves universal tinting, theme-token selection, and native
  source reactivity across multiple items.
- Added the approved target-retirement mechanism to
  `~/Projects/theme-switcher`: a validated repository-local list can skip an
  existing target without modifying its apply script. Missing, malformed,
  duplicate, or unknown entries abort before any target runs. The list is
  active for `waybar` after the completed cutover.
- JavaScript/schema/helper tests, `shellcheck`, switcher sandbox tests,
  `qmllint`, Phase 1-3 service regressions, and the persistent-shell timeout
  smoke test pass. All Phase 3 acceptance items are complete.

Rollback/recovery:

- Stop the persistent QE process first with
  `qs kill --path <qe-project>/shell.qml`; changing `trayHostEnabled` in a live
  0.3.0 process does not return status-notifier watcher ownership.
- Remove `waybar` from `~/Projects/theme-switcher/retired-targets`, restore the
  prior Waybar autostart entry and any changed window/reserved-area assumptions,
  then start Waybar.
- Restore `config.bar.trayHostEnabled` to `false` before restarting QE in
  coexistence mode. Verify exactly one bar owns the tray and confirm the
  expected reserved edges before considering rollback complete.
- Production autostart currently uses the guarded `~/.local/bin/qe-shell`
  launcher. Full rollback restores the retained Hyprland autostart backup and
  removes that launcher link before Waybar is restored.

Out of scope:

- notification, launcher, dashboard, and lock replacements

### Phase 4: Theme, Matugen, and wallpaper platform

Status: Complete (2026-08-26; catalog/selector, Matugen generation, external
wallpaper-theme slot dispatch, and real-session regression cycles passed)

Objective: deliver complete QE theming and a stable cross-project best-effort
desktop theme workflow, including generated `Wallpaper` themes.

Prerequisites:

- Phases 1-3 complete
- current authored themes, schema, fallback, and validation suite provide the
  provisional audit baseline

Phase foundation gates:

- no Phase 4 work beyond the semantic-token audit/proposal may proceed until the
  revised minimal pre-release theme-v1 contract is explicitly approved by the
  user
- obtain separate approval before installing Matugen or editing external
  projects; confirm each external repository is backed up/version controlled
  before its first edit

Required implementation order:

1. Audit semantic roles across current and planned QE surfaces.
2. Present the minimal revised token vocabulary, alternatives, affected
   consumers, migration impact, and Matugen implications for user approval.
3. Record the decision in an ADR and update architecture, schema, emergency
   fallback, authored themes, fixtures, validation, and token-use documentation
   atomically.
4. Fix active-theme hot reload and prove transactional live updates for manual
   themes against the approved contract.
5. Only then proceed to catalog discovery, selectors, external machine
   contracts, Matugen installation/mappings, and wallpaper generation.

Semantic-token audit and proposal (2026-08-25):

- The provisional contract has 15 required tokens and no presentation consumer
  reads raw palette entries. Current consumers nevertheless expose four forced
  role-sharing problems: selected text borrows `surfaceBase`; disabled content
  has only `textSecondary`; inline hover fills borrow the tooltip surface; and
  pending operations borrow warning or success-like presentation.
- `surfaceOverlay` is currently used only for the persistent translucent bar and
  is ambiguous beside raised surfaces, transient popups, and the modal `scrim`.
  `tooltip` is a surface role but has no paired foreground, so readable tooltip
  text currently depends on the unrelated `textPrimary` role.
- `charging`, `shadow`, and `scrim` have no current QML consumer, but they are
  retained because charging is an accepted distinct power state and shadows and
  scrims are required by planned selectors, notifications, dashboards, and the
  lock. `surfaceBase`, `surfaceRaised`, and `accentPrimary` are currently used
  mainly by the disabled foundation preview but are likewise required by those
  planned surfaces.
- Two current consumers violate already accepted semantics independently of the
  vocabulary size. The battery uses `accentSecondary` instead of `charging`, and
  requested-only idle inhibition uses `success` despite ADR-013 forbidding a
  confirmed-success claim. Both must be corrected with the contract migration.
- The initial 19-role audit proposal was not approved. The user requested a
  broader vocabulary covering surfaces and interaction, focus and accessibility,
  and links and highlights; Matugen-style naming; and mappings that preserve
  each authored theme's identity while enforcing contrast.
- Matugen's documented color scheme uses `snake_case`, paired foreground roles
  such as `primary`/`on_primary`, `surface`/`on_surface`, and
  `primary_container`/`on_primary_container`, and role names such as `outline`,
  `shadow`, and `scrim`. The revised proposal adopts that convention rather than
  converting Matugen output into QE's provisional camelCase primary/secondary
  text vocabulary.
- The revised pre-release theme-v1 proposal has 32 roles: paired base roles
  `background`/`on_background`, `surface`/`on_surface`,
  `surface_variant`/`on_surface_variant`,
  `surface_panel`/`on_surface_panel`, and
  `surface_tooltip`/`on_surface_tooltip`; interaction surfaces `surface_hover`
  and `surface_pressed`; accent and selection pairs `primary`/`on_primary`,
  `primary_container`/`on_primary_container`, and
  `secondary`/`on_secondary`; structure `outline` and `outline_variant`;
  accessibility `focus_ring`, `on_surface_disabled`, and
  `on_surface_placeholder`; content emphasis `link`, `highlight`, and
  `on_highlight`; state `success`, `charging`, `warning`, and `error`; and
  utilities `shadow` and `scrim`.
- `surface_variant` owns recessed inputs and alternate cards;
  `primary_container`/`on_primary_container` own selected items without forcing
  them onto the stronger primary action color; hover and pressed colors are
  independent state layers; every authored solid surface has an intentional
  foreground pair; and tooltip contrast no longer depends on a generic text
  token. Disabled and placeholder foregrounds remain separate because disabled
  controls and editable hints have different meaning and contrast needs.
- `focus_ring` is independent from the selected or primary fill so keyboard
  focus remains visible on active controls. `link` is a foreground role, while
  `highlight`/`on_highlight` form a readable pair for search matches and marked
  content. Component-specific notification, slider, dashboard, and lock tokens
  remain rejected; those surfaces compose the shared roles.
- A dedicated pending/status expansion remains outside this revision because the
  user did not select status/urgency expansion. Pending intent will use primary
  emphasis plus motion or operation text rather than warning or success, while
  confirmed positive, charging, warning, and failure states retain their
  existing semantic roles.
- Approval would trigger one atomic contract revision across runtime validation,
  JSON Schema, emergency fallback, both authored themes, fixtures, consumer
  coverage tests, architecture vocabulary, and a new ADR. Current QML migration
  includes the bar panel, chip/tray hover, tooltip surface and foreground,
  selected preview pair, Bluetooth pending treatment, battery charging state,
  and idle-inhibitor requested state plus their tests. There are no shipped
  external QE theme consumers, so the pre-release revision requires no
  compatibility parser or schema v2.
- Manual mappings will preserve recognizable Poimandres and Gruvbox hues while
  validating each `on_*` pair. Normal text targets at least 4.5:1 contrast;
  large text, icons, focus indicators, and meaningful boundaries target at least
  3:1. Disabled content may be lower emphasis but must remain distinguishable;
  placeholder text remains readable as user-facing text. New derived palette
  values are allowed when a source palette lacks a suitable role, but authored
  semantic tokens remain references or literals rather than runtime blending.
- Matugen maps its `background`, `surface`, `surface_variant`, primary,
  primary-container, secondary, `outline`, `outline_variant`, `shadow`, and
  `scrim` pairs directly. The QE template derives literal panel alpha, hover and
  pressed state layers, disabled and placeholder foregrounds, link/highlight
  roles from tertiary colors, and QE's success/charging/warning colors. Generated
  values must pass the same pairwise contrast and complete-document validation
  as manual themes before promotion.
- No schema, theme, QML consumer, external project, Matugen configuration, or
  package state was changed by the audit itself. The user approved the revised
  32-role vocabulary and contrast policy on 2026-08-25, authorizing the atomic
  in-repository contract migration. Matugen installation and external-project
  edits still require their separate Phase 4 approvals.

Implementation record (foundation, 2026-08-25):

- Migrated runtime validation, JSON Schema, emergency fallback, Poimandres,
  Gruvbox, fixtures, and every current QML consumer atomically to ADR-015's 32
  roles. No old token access remains in QML or theme JSON. Existing bar semantics
  now use distinct panel, hover, pressed, tooltip, selection, disabled, charging,
  and requested-state roles.
- Authored solid surface/foreground pairs pass the 4.5:1 normal-text target;
  focus rings and strong outlines pass 3:1 against their intended surfaces.
  Panel text is checked against the alpha panel composited over the theme
  background; representative wallpaper contrast remains a live visual boundary.
- Runtime and JSON Schema now agree that an authored palette cannot be empty.
  The foundation service test also proves the emergency fallback exposes exactly
  the approved token set.
- Fixed active-theme hot reload so a changed file republishes only a complete,
  validated catalog candidate matching the confirmed active ID. Invalid edits
  remain excluded while the last-known-good resolved theme stays published; a
  valid recovery republishes without restarting QE.
- A disposable-copy test performs a valid Poimandres edit, invalid missing-token
  edit, and recovery in one uninterrupted shell process. JavaScript/schema tests,
  `shellcheck`, full `qmllint`, affected Phase 1-3 QML regressions, and the
  persistent-shell timeout smoke test pass.
- Added `ThemeCatalogService` as the architecture-owned discovery and validation
  boundary. Installed Qt 6.11's event-driven `FolderListModel` discovers readable
  non-hidden `*.json` files without polling, and an `Instantiator` owns one
  watched `FileView` per path. The reserved `themes/schema.json` is excluded from
  authored catalog input.
- Catalog publication waits until the directory model and every file reader are
  settled. Valid entries are sorted by display name; malformed documents are
  excluded locally; and every file involved in a duplicate ID is excluded until
  the conflict is removed. `ThemeService` retains active-theme ownership and
  exposes the catalog as a compatibility facade for current consumers.
- The disposable lifecycle test covers dynamic add, malformed input, duplicate
  IDs, removal, active-source loss with stale last-known-good state, and recovery.
  Full Phase 1-3 regressions and the persistent-shell smoke test pass after the
  catalog/service split.
- Added the manual `ThemeSelector` as a lazy persistent-shell surface. The
  `SurfaceService` owns requested visibility and the module-scoped `qe-theme`
  IPC adapter exposes typed `open`, `close`, `toggle`, and `isOpen` methods per
  ADR-016. Selector interaction and exact-process IPC fixtures pass without
  changing existing Hyprland keybindings or external desktop entries.
- Refactored the approved external `~/Projects/theme-switcher` boundary without
  changing its positional human CLI. Machine mode is
  `run.sh --machine --theme <id> [--skip-gtk]`, reserves stdout for one strict
  schema-v1 JSON result, continues across target failures, reports deterministic
  per-target applied/skipped/failed results, never opens the wallpaper picker,
  never writes legacy `theme_data`, and exits 0/3/4 for success/partial/failed
  with exit 2 reserved for usage. It atomically persists switcher-owned state at
  `${XDG_STATE_HOME:-$HOME/.local/state}/theme-switcher/active-theme.json`.
- `ExternalThemeAdapter` resolves its executable only from the explicit
  `QE_THEME_SWITCHER` environment path, passes arguments as an array, enforces a
  120-second timeout with a two-second TERM grace, bounds retained output, and
  strictly validates status, exit code, timestamp, persistence, and per-target
  consistency. An unset, missing, or removed executable degrades only external
  theming; no project checkout path is assumed.
- `ThemeService` persists and publishes QE first, then runs the external phase
  as best effort. Requests are serialized through that bounded phase; QE-owned
  operation IDs associate results locally because switcher-owned persisted state
  intentionally contains no QE operation identity. Partial or failed external
  results never roll QE back, and independent CLI state updates never overwrite
  the active QE theme. The selector reports external status separately and names
  failed targets.
- The theme selector rejects the already-active theme and disables every theme
  card while an apply operation is pending. Disabled cards use reduced opacity
  and cannot receive pointer or hover interaction; the active card is labeled
  `Currently active`, and pending cards show `Theme apply in progress`. The
  selector interaction fixture verifies that reselecting the active theme cannot
  start an operation.
- The current production launcher environment now wires external theming. The
  installed `qe-theme-switcher` helper forwards QE's array arguments to the
  theme-switcher machine CLI, and `run-qe.sh` discovers it solely from
  `QE_THEME_SWITCHER` (via `command -v` with a `~/.local/bin` fallback). An
  unset, missing, or removed executable still degrades only external theming;
  no project checkout path is assumed. Applying the QE `wallpaper` theme now
  invokes the switcher with `--skip-gtk`, because Matugen generates no GTK
  theme; all other themes apply without the flag.
- While the QE `wallpaper` theme is active, QE generates `wallpaper` theme slot
  files for external applications from the same Matugen palette it already
  captures. `utils/ExternalWallpaperTheme.mjs` maps palette roles to kitty,
  bat, btop, eza, dunst, fzf, hyprland, hyprlock, rofi, starship, tmux,
  opencode, and a documented `qe-nvim-palette` JSON for Neovim, validating each
  generated file. `scripts/promote-external-theme.sh` materializes and
  atomically promotes each slot file (same-filesystem rename, skipped when the
  target executable is absent, 0/3/4/2 exit semantics) under the contracts in
  ADR-019.
- After external slot promotion succeeds, QE delegates application to the
  external switcher (`--machine --theme wallpaper --skip-gtk`). Applying a
  wallpaper always runs Matugen generation so the validated `wallpaper` QE
  theme enters the catalog and becomes selectable, but QE delegates external
  application only while the wallpaper theme is active, so changing a wallpaper
  never overwrites fixed external themes. Neovim consumes the generated palette
  through a local `colors/wallpaper.vim` colorscheme that reloads the palette
  on each `:colorscheme wallpaper`, so the switcher's existing name-based
  Neovim apply path works without an extra plugin. Generated-theme catalog files
  are explicitly re-read after atomic replacement, and wallpaper external
  dispatch is deferred until generation/promotion completes so repeated
  generations remain current without duplicate switcher requests. Wallpaper
  changes issued while a generation is running are queued to the latest
  requested path, and regenerating an already-published theme skips the
  redundant promotion while still dispatching external application.
  Known limitation: opencode loads and caches its theme colors at launch, so a
  regenerated wallpaper theme's colors take effect only after opencode
  restarts. The switcher can live-update the *selected theme name* in opencode
  running inside tmux (driving the picker with `tmux send-keys`), but that
  cannot reload the cached palette, so it does not change colors. This is an
  external application path owned by the switcher, not a QE defect.
- Added the first Matugen/wallpaper foundation without changing package state or
  the legacy wallpaper-picker repository. `MatugenAdapter` accepts only an
  explicit `QE_MATUGEN` executable, requests noninteractive JSON color output,
  and maps it through the normal 32-role QE validator. `WallpaperService` owns
  versioned selected-wallpaper state, and `WallpaperAdapter` keeps the legacy
  helper behind an explicit `QE_WALLPAPER_HELPER` boundary. Generated
  `Wallpaper.json` is stored at the stable XDG data path
  `$XDG_DATA_HOME/qe/wallpaper/Wallpaper.json`, outside authored `themes/`, and
  is admitted to the catalog only after validation.
- The mapper, adapter, and service fixtures pass with a fake Matugen executable,
  and the real Matugen 4.1.0 command was verified against a user wallpaper.
  The QE-owned cache helper now generates bounded thumbnails and a validated
   manifest in the QE cache directory; malformed entries and stale thumbnails
   are excluded. The production launcher now wires the QE-owned wallpaper apply
   helper by default; it validates the source image, derives the Hyprpaper and
    lockscreen artifacts under XDG data, and leaves the legacy wallpaper-picker
    repository untouched. External generated Matugen artifacts were initially
    deferred pending approved target contracts and later resolved by ADR-019's
    wallpaper-theme slot generation; wallpaper-picker migration is resolved by
    keeping QE's own selector localized in this repository.
- QE `Wallpaper.json` generation now writes to a per-operation staging path and
  promotes through `WallpaperPromotionAdapter` only after Matugen mapping and
  schema validation succeed. Same-filesystem promotion preserves the prior
  artifact on staging/promotion failure; success, promotion failure, and
  malformed-generation last-known-good fixtures pass. External generated
  Matugen artifacts were deferred at this point and later resolved by ADR-019.
- Hyprpaper IPC application is now confirmed through the QE helper after its
  derived images are staged, with rollback of those images if bounded IPC
  startup/acceptance fails. The standalone picker's `wallpaper` script and the
  QE helper are interchangeable when used sequentially: both write
  `current_wallpaper.png` and `current_lockscreen.png` and restart Hyprpaper,
  while QE additionally validates, confirms IPC, and rolls back on failure.
- A QE-localized wallpaper selector (`modules/wallpaper/WallpaperSelector.qml`)
  opens through the `qe-wallpaper` IPC target, remains open after a successful
  apply, prevents selection while an apply is pending, excludes the confirmed
  active wallpaper, and uses QE-owned thumbnail cache and apply state. Its
  responsive one-to-four-column grid presents full-bleed, rounded 16:9 previews
  with layered focus borders and publishes the focused filename in the footer.
  Theme and wallpaper selectors are launched via temporary `.desktop` entries
  (`qe-theme-selector.desktop`, `qe-wallpaper-selector.desktop`) and a
  `scripts/qe-launch.sh` helper that discovers the running `--no-duplicate` QE
  shell. These temporary launchers will be superseded by the planned control
  center (Phases 8-10), which will host both selectors.
- The approved Hyprpaper and Hyprlock configuration changes now resolve the
  wallpaper and lockscreen image paths through `$XDG_DATA_HOME` with a
  `$HOME/.local/share` fallback (`hyprpaper.conf`, `hyprlock.conf`). This keeps
  both configs and both wallpaper scripts aligned even when `XDG_DATA_HOME` is
  exported; the two config files are the only dotfiles changed for this work.
- Pure parser fixtures, fake-service coverage, and sandboxed adapter tests cover
  success, partial failure, malformed stdout, timeout, invalid IDs, missing
  executable, executable loss, independent state updates, and malformed-state
  last-known-good retention. The external repository's 22 retirement and 54
  machine-contract assertions pass with ShellCheck. Existing target validation
  helpers now resolve relative to the exported switcher root, preserving
  relocation without changing their target behavior.
- Phase 4 acceptance passed on 2026-08-26 after real-session regression cycles
  covering: repeated and queued wallpaper generation, live generated-theme
  catalog refresh, single external `wallpaper` dispatch with `--skip-gtk`,
  the wallpaper theme's dedicated image directory, authored-convention
  `#AARRGGBB` alpha tokens, and the full rofi colorscheme variable set. The
  full JS, helper, `qmllint`, and persistent-shell smoke suites pass. Known
  limitation: opencode caches its theme colors at launch, so regenerated
  wallpaper colors take effect after an opencode restart even when the switcher
  re-selects the theme name in tmux-hosted instances.

Scope:

- semantic-token vocabulary audit and explicit pre-release theme-v1 revision
- convert all current manual palettes to the approved QE theme schema
- transactional active-theme hot reload without requiring a QE restart
- theme catalog discovery and validation
- theme selector module
- refactor `~/Projects/theme-switcher` machine contract
- external per-target structured results and target retirement flags
- install/configure Matugen in an explicitly approved implementation step
- Matugen staging, validation, promotion, and last-known-good behavior
- generate QE and external `Wallpaper` artifacts
- integrate/migrate current wallpaper picker into QE module boundaries
- preserve source wallpaper and derived image distinctions

Likely affected files/subsystems:

- `themes/`
- theme/wallpaper services and modules
- `scripts/` and tests
- `~/Projects/theme-switcher`
- `~/Projects/wallpaper-picker` during migration
- approved Matugen user configuration

Deliverables:

- selectable manual QE themes
- selectable generated `Wallpaper` theme
- QE-first plus external-best-effort status UI
- structured switcher result contract and compatibility CLI
- wallpaper selector with cache and failure handling

Acceptance criteria:

- revised semantic vocabulary is explicitly approved, documented by ADR, and
  used consistently by current consumers without direct palette coupling
- valid edits to the active authored theme update live QE surfaces without a
  process restart; invalid edits retain the last-known-good active theme and
  emit diagnostics
- invalid themes never enter the catalog
- selecting a manual theme updates all live QE surfaces
- QE persistence failure prevents external invocation
- external partial failure leaves QE committed and displays target-level warning
- external CLI changes do not silently overwrite QE theme
- changing wallpaper while `Wallpaper` is active regenerates and reapplies
- failed Matugen generation preserves prior generated artifacts
- malformed wallpaper paths and image failures preserve prior wallpaper
- no generated file is mixed with authored `themes/`
- switcher no longer opens the wallpaper picker for machine-mode QE requests
- retired Waybar targets remain skipped after the Phase 3 cutover

Validation:

- semantic-token consumer inventory and required-role coverage tests
- active-theme valid-edit, invalid-edit, recovery, and last-known-good fixtures
- validate all nine current themes
- golden Matugen fixture tests
- missing Matugen, timeout, malformed result, and partial target simulations
- live tests with one deliberately failing external target
- relocate project copy and repeat path tests

Rollback/recovery:

- retain old switcher CLI mode and external wallpaper tools until acceptance
- restore previous generated set on generation failure
- QE can select a manual theme if Matugen is unavailable

Out of scope:

- forcing external CLI changes back into QE
- atomic rollback across every application

### Phase 5: Notification prototype in isolated ownership mode

Status: Complete (2026-08-29)

Objective: validate notification correctness without disrupting daily Dunst use.

Prerequisites:

- Phase 1 services/theme/components stable
- explicit test procedure for stopping and restoring Dunst

Scope:

- `NotificationService` capability policy
- popup lifecycle, urgency, progress, actions, replacement, timeout, images, and
  safe markup subset
- process-session history model
- DND policy
- reload handling using `lastGeneration`
- current notification owner diagnostics

Likely affected files/subsystems:

- `services/NotificationService.qml`
- `integrations/NotificationsIntegration.qml`
- `modules/notifications/`
- fixtures and acceptance scripts

Deliverables:

- isolated QE notification session
- popup and history components
- action and dismissal behavior
- Dunst restore checklist

Acceptance criteria:

- QE never reports notification readiness while Dunst owns the DBus name
- representative `notify-send` cases render correctly
- replacements do not duplicate history entries
- soft reload does not duplicate visible/history notifications
- DND behavior is explicit by urgency
- malformed markup/image/action data cannot crash the shell
- process exit clears history as designed

Validation:

- stop Dunst only for the test, run notification matrix, stop QE, restart Dunst
- verify DBus owner at each transition
- run malformed and oversized fixtures

Rollback/recovery:

- stop QE notification instance and restore Dunst service/activation

Implementation decisions:

- DND suppresses Low and Normal popup presentation while retaining those
  notifications in current-process history; Critical notifications remain visible.
- Native `NotificationServer` owns notification delivery. A reviewed structured
  DBus owner watcher reports owner transitions because Quickshell does not expose
  server registration state to QML.
- The exclusive acceptance test may stop Dunst in the current graphical session,
  but only inside a trapped script that verifies ownership at every transition and
  restores Dunst on success or failure. Production service, autostart, keybinding,
  and legacy producer changes remain out of scope.
- The initial capability policy advertises body, actions, images, and standard
  progress hints after bounded rendering validation; persistence, action icons,
  hyperlinks, and inline replies remain disabled.

Out of scope:

- production Dunst disablement, persistent history, hardware OSD migration

### Phase 6: Notification cutover and OSD migration

Status: Complete (implementation and reversible production cutover validated 2026-08-29)

Objective: make QE the production notification owner and replace Dunst-based
hardware feedback with native QE OSDs.

Prerequisites:

- Phase 5 acceptance passes
- notification center interaction accepted
- AudioService and BrightnessService operations stable

Scope:

- disable Dunst ownership through an explicit reversible user-service/config
  change
- retire the external switcher's Dunst target before disabling Dunst so a theme
  application cannot restart it
- bind existing notification key actions to QE IPC
- notification-center sidebar
- `OSDService` coalescing and presentation
- volume, microphone, brightness, media, network, Bluetooth, and battery OSD
  event policy
- migrate hardware keybindings from legacy scripts to QE service actions

Likely affected files/subsystems:

- notifications and OSD modules/services
- Hyprland keybindings
- Dunst user-service configuration
- legacy volume/brightness/mic scripts only after fallback decision

Deliverables:

- QE-owned notification service
- notification center and DND control
- confirmed-state OSDs
- rollback instructions restoring Dunst and old keybindings

Acceptance criteria:

- exactly one notification DBus owner after login
- applying an external theme does not restart Dunst after cutover
- critical/action/replacement/progress cases pass
- hardware keys update subsystem state and show correct OSD
- failed operations display failure rather than a success value
- notification and OSD traffic do not starve the main shell
- reverting restores Dunst and legacy hardware behavior

Validation:

- login/restart and sender matrix
- daemon restart and operation timeout tests
- rollback exercise

Rollback/recovery:

- restore Dunst service/activation and original Hyprland keybindings

Implementation record:

- Added the versioned `osd` configuration block with bounded duration and queue
  length. `OSDService` owns a priority/replacement-key queue and remains
  independent from the notification DBus server.
- Added native PipeWire output mute, microphone mute, and bounded volume
  actions. Volume stepping preserves the existing behavior of unmuting and
  allowing values through 200 percent; native events remain authoritative.
- Added native MPRIS media actions with capability checks instead of
  `playerctl`.
- Added class-aware brightness helper discovery and a keyboard LED service;
  keyboard devices are selected by stable name hints rather than the previous
  machine-specific `smc::kbd_backlight` value.
- Added the typed `qe-actions` IPC target and allowlisted `qe-action` wrapper.
  Production keybindings remain unchanged until the cutover gate passes.
- Added notification-center dismiss-all, per-notification dismissal, and
  action invocation controls. Existing process-session history and DND policy
  remain unchanged.
- QML action, OSD, schema, brightness, ShellCheck, and persistent-shell smoke
  checks pass. Full Phase 1-5 regression validation and live cutover remain
  pending.

Cutover decision record:

- Persistent Dunst blocking will use a user-service mask in the symlinked
  dotfiles systemd directory; `disable` is not suitable because the packaged
  unit is static and DBus-activated.
- The Dunst target must be added to `~/Projects/theme-switcher/retired-targets`
  before the mask is activated. The apply script itself remains preserved.
- The active Lua keybindings will call the stable `qe-action` wrapper. The
  inactive `hyprlang/_keybinds.conf` remains unchanged.

Completion record:

- Full JavaScript, helper, QML, theme-switcher, QML-lint, ShellCheck, and
  persistent-shell validation passed. Headless QML tests are accepted by their
  success markers because this installed Quickshell build may leave `Qt.quit()`
  for the timeout to reap.
- Production checks passed with Dunst masked and inactive, QE owning
  `org.freedesktop.Notifications`, the active `qe-action` wrapper and Lua
  bindings loaded, and the external theme switcher explicitly skipping Dunst.
- Rollback passed by stopping QE, restoring the pre-cutover config and active
  bindings, removing the wrapper, unmasking/starting Dunst, and confirming
  Dunst reclaimed the notification bus. The cutover was then re-applied and
  re-verified.
- Follow-up user-testing fixes preserve PipeWire volume confirmation through
  200 percent, propagate brightness step results, suppress transient non-full
  battery `Fully charged` OSDs, and align brightness/charging battery text
  with the muted bar color contract.
- A second user-test pass confirmed the volume ceiling now produces a confirmed
  200 percent OSD without issuing another setter request, while brightness
  actions defer OSD presentation until the fast external operation confirms or
  fails, avoiding a misleading transient pending state.
- Native battery alerts now emit latched low and critical OSDs at 20% and 15%,
  respectively, with critical escalation and charging reset behavior. The
  legacy `battery-alert.timer` was disabled after the native alert tests passed;
  its scripts and unit files remain available for rollback.

Phase 6 follow-up implementation:

- Volume and screen/keyboard brightness active Hyprland bindings share one
  250ms repeat timer whose owner is replaced on press and cleared on release,
  leaving the global keyboard repeat rate and delay unchanged.
- Low and normal notification popups now expire after five seconds. Critical
  popups remain visible until explicitly dismissed or closed by their sender.
  Card dismissal removes the popup while retaining eligible history entries;
  action buttons remain independent of card dismissal.
- Opening the notification center at its newest position clears visible popups
  and blocks new popup presentation, including critical notifications. Scrolling
  away from the newest position restores popup presentation; returning to the
  newest position blocks it again. The center no longer exposes dismiss-all or
  per-history-notification dismiss controls. New history entries prepended while
  scrolled preserve the existing visible scroll anchor.
- Each notification-center history card now provides an icon-only remove action
  that deletes only that record from current-session history; it does not
  dismiss the underlying notification or alter popup state.
- Notification-center keyboard navigation uses `j`/`k` between the header and
  history cards and `h`/`l` between controls within the selected row. Enter and
  Space activate the focused control, `x` removes the focused history record,
  and `q` closes the center. The notification-center layer surface takes
  exclusive keyboard focus when opened; Escape releases focus while leaving the
  panel visible. Stable notification IDs and action identifiers preserve focus
  through list changes; card close icons remain pointer-only and excluded from
  keyboard focus. Initial focus selects the first history card when present,
  and vertical navigation selects each card before `l` enters its first action.
- Notification popups and history cards share the media-first card layout. Popup
  cards retain their existing maximum width and omit the close control; supplied
  images are preferred over fallback icons, with `robot_2` for OpenCode,
  `warning` for critical notifications, and `notifications` for low/normal
  notifications.
- Notification popups use the sidebar's 20px top and screen-facing right margin
  treatment, with a 20px left inset and final bottom margin, plus 20px between
  popup cards. Their 1px border matches the border size of critical
  notification-center cards.
- The notification center uses the reusable `components/Sidebar.qml` layer-shell
  sidebar on the overlay layer rather than a Hyprland-managed window. It spans
  the available vertical space with 20px outer screen margins and is sized to
  the 384px card maximum
  plus the existing content margins, so it remains visible across workspaces
  without changing card layout or sizing.
- The notification center overlays a horizontally centered `surface_hover` info pill
  40px above its bottom edge when history cards remain entirely below the list
  viewport. The pill reports the view-local below-fold count in
  `on_surface_variant` `keyboard_arrow_down` icon plus count, adds a 1px
  `outline` top edge at 30% alpha and a 24px blurred theme shadow
  when shadows are enabled, and does not reserve list space or add service
  state.
- The reusable sidebar now owns a dedicated `surface_sidebar` background role.
  Authored themes use their prepared alpha colors, while generated wallpaper
  themes derive the role by reducing background HSL lightness by 9/255 while
  preserving hue and saturation. Its surface radius matches theme-selector
  cards, and its configured border width and `outline_variant` color match the
  inactive border treatment used by Hyprland floating windows.
- The reusable `IconButton` now supports controlled toggle state without
  changing non-toggle behavior. The notification center uses it for DND with
  `do_not_disturb_on`. Toggle buttons retain regular background states; a
  toggled-on button uses the default `success` token for its foreground and
  border. Notification-center IconButtons override those colors with
  `outline_variant` to match normal notification cards, while DND uses
  `warning` when toggled on.
- The notification center includes a view-local controlled `warning` toggle
  beside Clear All. When enabled, it partitions current and future history into
  critical-first and non-critical groups while preserving newest-to-oldest order
  within each group; disabling it restores the service order. The service
  history is not mutated, and the toggle resets when the center is recreated.
- Active screenshot bindings now use `scripts/qe-hyprshot.sh`, which preserves
  `hyprshot` capture behavior while replacing its fixed notification with
  `View Image` and `Open Folder` actions. The latter opens the screenshot
  directory directly in Thunar. The notification body contains the saved
  filename and publishes the screenshot through the standard `image-path` hint.
  A persistent D-Bus sender keeps both action endpoints reusable from popup and
  history and marks the notification resident so action dispatch does not close
  it after the first click.
- Charging and discharging battery status OSDs now use `Charging` and
  `Discharging` titles with percentage and confirmed UPower time estimates in
  the body. Unavailable estimates are omitted; a fully charged battery uses
  charging semantics without a time estimate. Low/critical alert presentations
  remain unchanged.
- OSD presentation now uses one centered 56px row with a `surface` surface,
  sidebar radius, `on_surface` foregrounds, and an `outline` top edge matching
  the notification-center info pill. Volume, screen/keyboard brightness, and
  battery use an icon, `primary` meter, and percentage; other OSDs shrink to an
  icon and body text. The surface has the same optional 24px shadow and is
  horizontally centered 20px below the top screen edge.
- Text-only OSDs use their natural body width without elision, and muted volume
  uses the icon-and-`Muted` text layout instead of exposing a meter or level.
  New OSD feedback immediately replaces the active presentation and restarts
  expiry; superseded feedback is discarded rather than queued for stale replay.
- Network OSDs identify Wi-Fi connections as `Connected to <SSID>`, identify
  wired connections by their confirmed LAN IPv4 address with the `lan` icon,
  and use `Disconnected` for offline state. Wired presentation waits for the
  asynchronous address adapter rather than showing an empty transient OSD.
- Volume and screen/keyboard brightness holds now share one 250ms repeat timer.
  Each press cancels and replaces its owner, while every bound release stops the
  sole timer, preventing rapid opposite-direction presses from leaving an
  independent timer running.
- The bar now places a DND toggle between idle inhibition and Bluetooth. It uses
  `do_not_disturb_off` with the default `secondary` icon foreground while off,
  and `do_not_disturb_on` with a `warning` foreground while on. Clicking it
  updates the persisted state through `NotificationService.setDnd()`; the bar
  does not own a duplicate DND value.

Deferred dotfiles cleanup:

- After the Phase 6 rollback window is closed, move the following deprecated
  files owned by the dotfiles repository into `~/dotfiles/_legacy`, preserving
  their history and documenting the recovery path: `scripts/.local/bin/battery-alert`,
  `scripts/.local/bin/battery-charging`, `scripts/.local/bin/volume` (the legacy
  audio control script), `scripts/.local/bin/brightness`,
  `scripts/.local/bin/mic-mute-toggle`, `scripts/.local/bin/kbd_brightness`,
  `_hyprland/systemd/.config/systemd/user/battery-alert.service`,
  `_hyprland/systemd/.config/systemd/user/battery-alert.timer`, and the full
  `_hyprland/dunst/.config/dunst/` configuration and icon tree, plus the full
  unstowed `_unstowed/walker/` configuration and desktop-entry tree.
- Do not move or delete these files as part of the native-alert cutover. Native
  QE alerts and hardware controls must remain independently verified before
  legacy cleanup.

Native hardware-control ownership:

- Active audio, microphone, and screen-brightness bindings are QE-owned through
  `scripts/qe-action.sh`, `integrations/ActionsIpc.qml`, `services/AudioService.qml`,
  `integrations/PipewireIntegration.qml`, `services/BrightnessService.qml`, and
  `scripts/qe-brightness.sh`.
- The dotfiles `volume`, `brightness`, and `mic-mute-toggle` scripts are no
  longer used by active Hyprland bindings. The inactive
  `_hyprland/hypr/.config/hypr/hyprlang/_keybinds.conf` still references them
  and remains outside QE project scope. Before the legacy cleanup milestone,
  remind the user to move the `hyprlang` files to `~/dotfiles/_legacy`.

Native media ownership:

- Active media keybindings are QE-owned through `services/MediaService.qml`,
  `integrations/MprisIntegration.qml`, and `qe-actions`; they do not invoke
  `playerctl`.
- The unstowed Walker configuration is not active because Walker is not
  installed or deployed. Its `playerctl` lock-screen entry is retained only as
  a legacy reference and is included in the planned `_legacy` move. The
  `playerctl` package itself is not scheduled for removal.

Native battery ownership:

- QE owns native battery state through `integrations/UPowerIntegration.qml` and
  `services/PowerService.qml`.
- QE owns low/critical alert policy and OSD presentation through
  `services/OSDService.qml`; `modules/bar/BatteryModule.qml` owns the bar
  presentation.
- No dotfiles script, systemd unit, `acpi` command, or `dunstify` call is part
  of the native alert path. The deprecated files above are fallback/legacy
  producers only and are currently retained for rollback.

Out of scope:

- persistent notification history

### Phase 7: Launcher and help

Objective: replace primary Rofi application launch and provide a curated help
surface while leaving specialized Rofi flows available.

Prerequisites:

- Phase 1 platform and theme stable
- stable surface-opening IPC convention

Scope:

- DesktopEntries-based app model
- search/ranking pure utilities
- keyboard and pointer navigation
- structured launch and launch errors
- help JSON schema and source labeling
- migrate Super+R after acceptance

Likely affected files/subsystems:

- launcher/help modules and services
- `config/`
- Hyprland keybindings at cutover

Deliverables:

- app launcher
- help/reference window
- Rofi fallback command retained

Acceptance criteria:

- hidden/invalid desktop entries are handled correctly
- launch uses structured commands and working directories
- search remains responsive with the installed application set
- focus and dismissal work across configured monitors
- help never claims duplicated reference data is live authoritative state
- Super+R rollback to Rofi is documented and tested

Validation:

- desktop entry fixture matrix
- keyboard-only and multi-monitor/manual focus tests
- missing executable/launch failure tests

Rollback/recovery:

- restore Super+R to `rofi -show drun`; QE launcher can remain disabled

Out of scope:

- replacing every Rofi script-mode tool, file search, plugin framework

### Phase 8: Control center and audio dashboard

Objective: establish the shared dashboard/window pattern and replace common
`pavucontrol` use cases first because PipeWire has a strong native API.

Prerequisites:

- bar module launch points and surface routing stable
- AudioService proven in bar/OSD usage

Scope:

- control-center shell and quick-setting tile contract
- DND, idle inhibition, connectivity, Bluetooth, audio, brightness, battery,
  power profile, and diagnostics summaries
- audio output/input lists, defaults, levels, mute, and common stream controls
- explicit `pavucontrol` escape hatch for unsupported operations

Likely affected files/subsystems:

- `modules/controlcenter/`
- `modules/audio/`
- audio/power/idle services

Deliverables:

- control-center sidebar
- audio dashboard v1

Acceptance criteria:

- tiles reflect confirmed and pending state distinctly
- unavailable integrations do not block the panel
- default device, volume, and mute changes reconcile from PipeWire events
- hot-plug and WirePlumber restart behavior is safe
- unsupported routing opens or points to pavucontrol rather than faking support

Validation:

- fake model tests and live device operations
- daemon restart/hot-plug manual test

Rollback/recovery:

- pavucontrol remains installed and launchable

Out of scope:

- full PipeWire graph patchbay

### Phase 9: Bluetooth dashboard

Objective: replace common Blueman Manager use cases after native pairing
behavior is verified.

Prerequisites:

- control-center dashboard pattern
- native Bluetooth pairing-agent capability investigation

Scope:

- adapter power/discovery controls
- known/discovered device grouping
- connect, disconnect, pair, cancel, forget
- battery and operation status
- explicit fallback for unsupported pairing interactions

Likely affected files/subsystems:

- Bluetooth module/service/integration and fixtures

Deliverables:

- Bluetooth dashboard v1
- capability gap report

Acceptance criteria:

- adapter missing/off/on states are distinct
- discovery has bounded lifecycle and stops on close/configured timeout
- operations reconcile from BlueZ state
- BlueZ restart removes stale objects and repopulates safely
- unsupported pairing flow leaves Blueman available

Validation:

- model fixtures
- pair/connect/disconnect a disposable device
- BlueZ restart test only with explicit approval

Rollback/recovery:

- Blueman Manager remains installed and accessible

Out of scope:

- OBEX transfer and unverified advanced profile management

### Phase 10: Network dashboard

Objective: replace common network inspection and personal Wi-Fi management
without overclaiming full NetworkManager editor parity.

Prerequisites:

- control-center pattern
- agreed v1 boundary for connection types and secrets

Scope:

- device/connectivity state
- Wi-Fi enable/disable
- known network connect/disconnect/forget
- PSK network connection through native API
- signal/security metadata and operation errors
- fallback launch for unsupported profiles

Likely affected files/subsystems:

- network module/service/integration and fixtures

Deliverables:

- network dashboard v1
- explicit unsupported-profile UX

Acceptance criteria:

- network secrets never enter logs or QE persistence
- duplicate SSIDs are represented without conflating distinct networks
- NetworkManager restart produces unavailable then fresh state
- failed authentication is not shown as connected
- unsupported enterprise/VPN/profile cases retain `nm-connection-editor` fallback

Validation:

- fixture matrix for security/state/failure reasons
- connect/disconnect test on an approved network
- missing NetworkManager test through fixtures or isolated environment

Rollback/recovery:

- NetworkManager editor remains installed and accessible

Out of scope:

- enterprise EAP, VPN, proxy, hidden-network creation, full profile editor unless
  separately approved after the v1 investigation

### Phase 11: Secure lock replacement

Objective: replace Hyprlock with an isolated, compositor-enforced QE lock after
security and recovery behavior are validated.

Prerequisites:

- stable lock-safe theme/config readers
- verified installed `WlSessionLock` and PAM behavior
- approved test environment and emergency TTY recovery procedure
- chosen PAM service

Scope:

- minimal `lock.qml` process graph
- one session-lock surface per screen
- PAM password conversation
- secure-state and authentication state machine
- battery/time/background as optional read-only visuals
- manual lock entry point
- idle and before-sleep integration
- file watching/reload disabled while locked

Likely affected files/subsystems:

- `lock.qml`
- `lock/`
- lock-safe config/theme adapter
- Hyprland keybindings and Hypridle config at final cutover

Deliverables:

- secure lock process
- threat/failure checklist
- emergency recovery instructions
- Hyprlock rollback configuration

Acceptance criteria:

- compositor `secure` is confirmed on all active outputs
- no ordinary fullscreen fallback exists
- wrong/empty/cancelled PAM responses remain locked
- successful PAM completion is the only UI path to `locked = false`
- secrets are cleared and absent from logs
- monitor hot-plug behavior is tested
- suspend/resume remains locked
- pre-secure surface creation failure does not expose a false locked state
- post-secure process crash behavior and TTY recovery are explicitly tested in
  a disposable session where feasible
- no IPC method can unlock
- Hyprlock can be restored through documented config rollback

Validation:

- automated state-machine tests with fake PAM results where possible
- nested/disposable compositor tests
- controlled real-session manual checklist with TTY access confirmed first
- idle and before-sleep tests

Rollback/recovery:

- restore Hyprlock command/keybinding and Hypridle lock command
- a crash after secure lock requires compositor/session recovery, not QE restart

Out of scope:

- fingerprint, face authentication, remote unlock, lock-screen dashboards

### Phase 12: Production hardening and deployment

Objective: make QE suitable for daily startup, managed deployment, diagnostics,
and clean retirement of replaced tools.

Prerequisites:

- selected features stable in daily use
- cutover rollback procedures exercised

Scope:

- decide systemd user service versus Hyprland autostart
- single-instance and restart policy
- startup ordering and environment
- journal/Quickshell log integration
- decide whether QE remains a managed project checkout or moves to another
  production location; no relocation is assumed
- update all external contracts to XDG/project-independent paths
- retire only replaced autostarts, keybindings, and generated target application
  themes
- final dependency manifest and recovery guide

Likely affected files/subsystems:

- QE entry/lifecycle configuration
- dotfiles repository
- Hyprland autostart/keybindings
- user services if selected
- external theme target registry

Deliverables:

- production launch configuration
- documented, reproducible QE deployment in the selected location
- dependency and troubleshooting documentation
- clean fallback profile

Acceptance criteria:

- fresh login starts exactly one persistent QE instance
- optional daemon delay does not block startup
- crash/restart behavior matches documented policy
- all paths work from the final location
- no retired tool starts or owns a conflicting protocol
- fallback profile restores Waybar/Rofi/Dunst/Hyprlock and dashboard tools
- diagnostics identify missing dependencies and current ownership

Validation:

- fresh-login tests
- controlled crash/restart tests excluding secure lock crash on primary session
- selected-location and clean-state tests
- complete rollback drill

Rollback/recovery:

- maintain a documented Hyprland fallback configuration and installed tools
  until QE has passed an agreed daily-use period

Out of scope:

- adding new major features during hardening

## 9. Parallelization Rules

Safe after Phase 1 contracts are frozen:

- visual components and fixture-driven service adapters
- independent native adapters for UPower, MPRIS, Bluetooth, and NetworkManager
- pure theme conversion and validation fixtures
- launcher filtering and help schema work
- dashboard visual shells using fake services

Not safe to parallelize without explicit coordination:

- changes to common service health/error semantics
- changes to config, state, or theme schema
- changes to module routing or IPC action naming
- simultaneous edits to external theme-switcher orchestration
- notification ownership and Dunst service changes
- lock state machine, PAM policy, and Hypridle cutover
- production supervision and Hyprland autostart changes

Feature UI must not precede its domain contract. A fake adapter may enable UI
work, but the fake and live adapter must satisfy the same reviewed interface.

## 10. Migration and Coexistence Matrix

| Existing tool | Can coexist? | Conflict | Disable condition | Development method | Rollback |
| --- | --- | --- | --- | --- | --- |
| Waybar | Yes only if QE does not reserve/conflict on same edge | duplicate bars/exclusive zones/tray hosts | essential bar parity and full-session test | non-exclusive/alternate-edge QE bar | restore Waybar autostart/window assumptions |
| Hyprlock | Yes when only one lock command runs | one session lock at a time | secure lock acceptance, idle/suspend coverage | isolated/manual lock invocation in disposable session | restore keybind and Hypridle commands |
| Rofi | Yes | only keybinding/user-flow duplication | launcher acceptance | invoke QE separately | restore Super+R |
| Dunst | No while QE owns notification DBus name | exclusive `org.freedesktop.Notifications` | popup/history/action matrix and ownership test | explicitly stop Dunst for isolated test | stop QE notification owner and restore Dunst |
| Blueman Manager | Yes | none for manager UI; concurrent operations may confuse state | required common Bluetooth flows pass | open either dashboard manually | keep Blueman launcher |
| `nm-connection-editor` | Yes | concurrent edits can race | only retire for supported profile scope | preserve fallback button | keep editor installed |
| `pavucontrol` | Yes | concurrent changes reconcile through PipeWire | common audio flows pass | preserve fallback button | keep pavucontrol installed |
| external wallpaper picker | Yes until state ownership migrates | concurrent writes to legacy data/cache | QE selector and helper contract pass | separate entry points; avoid simultaneous operations | retain old desktop entry/scripts |
| external theme selector | Yes by design | independent scopes may drift intentionally | never required to retire CLI | structured machine mode for QE | retain human CLI mode |

## 11. Poller Registry

This registry is authoritative for planned polling. An implementation must
update it before adding or changing a poller. Intervals are proposed defaults
until measured in the named phase.

| Poller | Missing event source | Proposed interval | Active consumer lifecycle | Cost control | Stale behavior | Validation phase |
| --- | --- | --- | --- | --- | --- | --- |
| Clock display | Wall-clock labels need periodic recomputation | align to minute boundary by default; 1 second only when configured to display seconds | enabled while a visible clock consumer exists | one shared timer for all clock views | system clock itself is not cached; missed tick recomputes on next tick | Phase 2 |
| CPU usage | procfs counters do not emit change events | 2 seconds | enabled while bar/control-center CPU metric is configured and process is active | one shared read; suspend when no consumer | stale after two failed reads; retain last value with stale marker | Phase 3 |
| Memory usage | procfs does not emit change events | 2 seconds | enabled while a memory metric consumer is configured | share cadence with CPU where implementation remains clear | stale after two failed reads; retain last value | Phase 3 |
| Thermal sensor | hwmon values do not provide a reliable portable event stream | 5 seconds | enabled while a temperature consumer is configured | discover stable sensor once; read only selected sensor files | stale after three failed reads; remove invalid sensor and rediscover | Phase 3 |
| Disk capacity | filesystem capacity has no suitable change signal | 30 seconds | enabled while a disk metric consumer is configured | query configured mount points only | stale after three failed reads; retain last value | Phase 3 |
| MPRIS position | Quickshell MPRIS position does not advance continuously | 1 second | only while a position consumer is visible and selected player is playing | stop immediately when paused, player vanishes, or view hides | reset from next player event; hide progress if player state is unavailable | media/OSD milestone using it |
| Brightness fallback | no native Quickshell API; sysfs watcher reliability is unverified | 2 seconds with dashboard/OSD visible; 10 seconds for a configured persistent bar value | only if watcher/operation events cannot satisfy active consumers | one device read; no poll when brightness is not displayed | stale after three failed reads; requested operations still force immediate confirmation read | Phase 3 and Phase 6 |

Polling budget for the bar milestone:

- Pollers add less than 0.5 percentage points of average CPU use over a
  five-minute idle comparison on the development machine.
- No consumer-scoped poller runs when it has zero enabled consumers.
- No undocumented poller is accepted.
- Native event-driven integrations do not receive fallback pollers merely to
  mask a reconnection defect.

## 12. Risk Register

| ID | Risk | Likelihood | Impact | Mitigation | Trigger/review |
| --- | --- | --- | --- | --- | --- |
| R1 | Lock process crashes after secure lock and cannot be reclaimed | Low/medium | Critical availability | minimal process, no reload, disposable tests, TTY recovery | any lock dependency or lifecycle change |
| R2 | Dunst and QE contend for notification DBus ownership | High during migration | High | staged exclusive tests and owner diagnostics | Phase 5 start and Phase 6 cutover |
| R3 | Quickshell 0.3.0 API differs from local 0.3.1 source | Medium | Medium/high | verify installed qmltypes and v0.3.0 docs before use | every new native integration |
| R4 | Theme partial application creates visible drift | High | Medium | independent scopes, per-target status, retry, no false global success | external switcher refactor |
| R5 | Matugen overwrites good artifacts with invalid output | Medium | High | staging, schema/target validation, atomic promotion, LKG set | every template/schema change |
| R6 | Legacy `theme_data` races with QE state | Medium | Medium | compatibility adapter only, distinct QE state, migrate ownership explicitly | wallpaper/theme migration |
| R7 | Direct command parsing leaks into QML UI | Medium | Medium | adapter rule, structured contracts, code review search | every process integration |
| R8 | Hidden polling causes battery/CPU cost | Medium | Medium | poller registry, consumer-aware polling, measured intervals | bar/system metric milestones |
| R9 | Network secrets leak through arguments/logs/state | Low/medium | High | native APIs, redaction, no persistence, security tests | network operation implementation |
| R10 | Bluetooth API cannot handle required pairing prompts | Medium | Medium | capability investigation and Blueman fallback | Phase 9 prerequisite |
| R11 | Multiple QE instances duplicate ownership/subscriptions | Medium | High | shell identity/single-instance guard and diagnostics | Phase 3 cutover |
| R12 | Soft reload duplicates notifications or subscriptions | Medium | Medium | reload tests, `lastGeneration`, centralized ownership | every singleton service |
| R13 | Hard-coded hardware/path assumptions return | Medium | Medium | PathsService, sensor discovery, path lint | every filesystem integration |
| R14 | Broad dashboard scope delays reliable foundations | High | Medium | explicit v1 non-goals and phased fallbacks | phase planning changes |
| R15 | External switcher target mutation partially corrupts config | Medium | High | target prevalidation, backups/staging where possible, per-target result | switcher refactor |
| R16 | Wallpaper helper reports success before compositor display | Low | Low/medium | Hyprpaper IPC acceptance handshake implemented; confirmation labeled as IPC acceptance, not pixel display | Phase 4 |
| R17 | Production restart loop destabilizes session | Low/medium | High | defer supervision, bounded restart policy based on evidence | Phase 12 decision |
| R18 | Notification content loads unsafe resources/markup | Medium | High | sanitize/limit rendering and resources | Phase 5 security review |
| R19 | External theme apply restarts a tool after QE has replaced it | Medium | High | target-retirement controls must precede each cutover and are included in rollback tests | Phases 3, 4, and 6 |

## 13. Architecture Decision Log

### ADR-001: Layered QE platform

Status: Accepted

Decision: use presentation/modules -> domain services -> integration adapters ->
external systems as the dependency direction.

Context: QE spans many shared stateful integrations and must not become a
collection of QML views that each spawn commands.

Rationale: centralizes state ownership and lifecycle while retaining declarative
presentation and replaceable external boundaries.

Alternatives considered: monolithic QML; independent feature applications;
framework-heavy abstraction layers.

Consequences: more explicit interfaces and fixtures are required; trivial local
view state remains local to avoid unnecessary services.

Affected areas: all modules and integrations.

Revisit if: Quickshell imposes a verified lifecycle limitation that prevents a
domain service from safely owning a required object.

### ADR-002: Separate lock process

Status: Accepted by user

Decision: persistent shell and secure lock use separate Quickshell processes.

Context: lock security and availability should not share the persistent shell's
large failure domain.

Rationale: minimizes lock dependencies and prevents bar/dashboard failures from
affecting the lock UI.

Alternatives considered: one process; additional process isolation for all
transient tools.

Consequences: theme/config sharing occurs through validated disk state; a crash
after secure lock remains fail-closed and requires session recovery.

Affected areas: entry points, theme/config readers, lock lifecycle, Hypridle.

Revisit if: the compositor/session-lock protocol gains a verified secure
handover/recovery mechanism or process separation causes a security regression.

### ADR-003: JSON configuration and themes

Status: Accepted by user

Decision: use strict, versioned JSON for user configuration and themes.

Context: QE and external generators need a portable, schema-validatable format.

Rationale: Quickshell supports JSON adapters and external tools can reliably
produce/validate JSON.

Alternatives considered: executable QML config, JSONC, TOML.

Consequences: comments are unavailable; schemas and diagnostics must make files
understandable. Generated and authored JSON remain in separate roots.

Affected areas: config, themes, Matugen, persistent state.

Revisit if: native tooling cannot provide safe transactional JSON reload or user
maintenance proves materially worse than alternatives.

### ADR-004: Independent QE and external theme scopes

Status: Accepted by user

Decision: QE and external applications each own their active theme. QE selection
automatically requests the same external ID after QE commits.

Context: the user intentionally permits independent themes and wants QE to
remain successful when external targets fail.

Rationale: reflects actual non-transactional application behavior and permits
external CLI use without QE dependence.

Alternatives considered: external switcher globally authoritative; QE globally
authoritative; neutral shared global state.

Consequences: visual drift is valid and must be visible in status. Values are
not synchronized bidirectionally.

Affected areas: ThemeService, external switcher, selector UI, diagnostics.

Revisit if: the user later requires globally locked theme consistency.

### ADR-005: QE-first, external-best-effort theme apply

Status: Accepted by user

Decision: validate/persist/publish QE first; abort on QE failure; otherwise run
the external apply and report its independent result without QE rollback.

Context: external targets cannot provide a reliable global transaction or
rollback.

Rationale: preserves responsive, truthful QE behavior and avoids making a local
theme dependent on every installed application.

Alternatives considered: rollback all possible; external apply despite QE
failure; declare success only if every target succeeds.

Consequences: partial external drift persists and requires target-level retry.

Affected areas: ThemeService, switcher contract, UI status.

Revisit if: external targets acquire transactional staging and rollback.

### ADR-006: Matugen generates QE and external `Wallpaper` outputs

Status: Accepted by user

Decision: one wallpaper input generates a QE theme conforming to the normal
schema and supported external application artifacts.

Context: `Wallpaper` must be selectable like a manual QE theme and participate
in wider desktop theming.

Rationale: one derivation pipeline avoids manually maintaining unrelated
generated palettes.

Alternatives considered: QE-only generation; limited core-app generation.

Consequences: template validation and staged promotion become critical; target
coverage can vary but must be reported.

Affected areas: Matugen config, theme schema, external switcher, wallpaper flow.

Revisit if: maintaining broad external templates becomes disproportionate; a
documented supported-target subset may then replace universal generation.

### ADR-007: Process-session notification history

Status: Accepted by user

Decision: do not persist notification history to disk initially.

Context: disk persistence adds privacy, retention, serialization, and migration
requirements.

Rationale: current-process history meets the initial notification-center goal
with lower risk.

Alternatives considered: persistence from first release; popups without history.

Consequences: history is lost on QE restart and diagnostics must not imply
otherwise.

Affected areas: NotificationService and center.

Revisit if: daily use demonstrates restart-persistent history is valuable enough
to justify a privacy and migration design.

### ADR-008: Staged Dunst cutover

Status: Accepted by user

Decision: keep Dunst during development; test QE ownership only in isolated
windows/sessions; disable Dunst only after notification acceptance passes.

Context: the DBus notification service has exclusive ownership.

Rationale: preserves reliable daily notifications and a simple rollback.

Alternatives considered: replace Dunst early; defer notification work entirely.

Consequences: notification development needs explicit owner transitions and
cannot be casually tested alongside Dunst.

Affected areas: Phase 5-6, Dunst user service, hardware scripts.

Revisit if: DBus activation prevents reliable isolated testing; use a separate
test user/session instead.

### ADR-009: Bar as first vertical slice

Status: Accepted by user

Decision: validate foundations through a safely coexisting bar.

Context: the bar exercises multiple native event-driven integrations and daily
presentation without exclusive protocol ownership.

Rationale: high architectural coverage with lower migration risk than lock or
notifications.

Alternatives considered: theme selector, launcher, lock.

Consequences: first slice intentionally omits feature breadth and cutover.

Affected areas: Phases 1-3.

Revisit if: Waybar coexistence proves technically unsafe; use a test floating
surface with the same service contracts.

### ADR-010: Defer production supervision

Status: Accepted by user

Decision: do not choose systemd user service or Hyprland autostart until runtime
behavior is known.

Context: restart policy, environment import, and failure handling depend on the
mature process topology.

Rationale: avoids encoding lifecycle assumptions before the shell is stable.

Alternatives considered: systemd user service immediately; Hyprland autostart
immediately.

Consequences: development uses explicit launch commands; Phase 12 must make and
record the production decision.

Affected areas: entry points, diagnostics, deployment.

Revisit if: an earlier cutover requires automatic session startup.

### ADR-011: Native integration before commands

Status: Accepted architectural rule

Decision: use installed Quickshell native APIs for Hyprland, PipeWire,
NetworkManager, BlueZ, UPower, MPRIS, tray, notifications, PAM, session lock,
desktop entries, and idle inhibition. Use commands only for uncovered behavior.

Context: current scripts parse human output and scatter lifecycle behavior.

Rationale: native APIs provide event-driven state, object lifetime, and safer
operations.

Alternatives considered: retain command wrappers for all integrations.

Consequences: adapters must handle native object invalidation and version
differences. Brightness remains a command boundary in 0.3.0.

Affected areas: all system services.

Revisit if: a native API is demonstrably incomplete or unstable for a required
operation; document the exact fallback contract.

### ADR-012: Add charging semantic token before release

Status: Accepted by user

Decision: revise the pre-release theme-v1 contract to require a `charging`
semantic color token.

Context: charging is a distinct visible power state and should not implicitly
reuse warning or accent semantics. QE has no shipped external theme consumers,
so a coordinated v1 revision is smaller and safer than adding schema migration
code now.

Rationale: every authored theme can choose an intentional charging color while
bar presentation remains palette-independent.

Alternatives considered: reuse `warning`; reuse `accentSecondary`; introduce
theme schema v2 immediately.

Consequences: all authored themes, fixtures, emergency fallback data, runtime
validation, JSON Schema, and token documentation require `charging`. Poimandres
maps it to `palette.yellow`; Gruvbox maps it to `palette.yellowLight`.

Affected areas: theme-v1 contract, Phase 2 power presentation, future generated
themes.

Revisit if: external theme consumers ship before another token change; further
contract changes then require a versioned migration.

### ADR-013: Idle inhibition exposes requested state only

Status: Accepted by user on 2026-08-24

Decision: implement the Phase 3 native Wayland idle-inhibitor toggle as
process-session requested state bound to a persistent QE bar window. Do not
claim or synthesize compositor-confirmed active state.

Context: installed Quickshell 0.3.0 exposes `IdleInhibitor.enabled` and `window`
but no active property, protocol-object status, rejection signal, or compositor
acknowledgement. Treating `enabled` as confirmed would violate QE's
requested-versus-confirmed state rule.

Rationale: requested-only state preserves the native no-command boundary and
honestly represents what QE can know. The Wayland object lifetime still gives
safe automatic release when the window or process disappears.

Alternatives considered: defer the module entirely; add a C++ native extension
in Phase 3; present `enabled` as confirmed active.

Consequences: the bar indicates that inhibition is requested, not guaranteed;
confirmed-active reporting remains deferred. The request is not persisted and
does not replace Hypridle, manual locking, or suspend policy.

Affected areas: `IdleService`, bar idle-inhibitor presentation, Phase 3
acceptance language, later control-center idle state.

Revisit if: Quickshell exposes reliable inhibitor status or QE adopts a reviewed
native extension that can distinguish protocol creation/revocation.

### ADR-014: Add tooltip semantic token before release

Status: Accepted by user on 2026-08-24

Decision: revise the pre-release theme-v1 contract to require a `tooltip`
semantic color token. Poimandres maps it to the new `palette.black` value
`#171922`; Gruvbox maps it to `palette.blackLight`; the emergency theme provides
an internal dark fallback.

Context: bar hover popups need a deliberate background distinct from general
raised surfaces. Reusing `surfaceRaised` coupled tooltip styling to unrelated
module-hover and elevated-surface decisions.

Rationale: one semantic token lets each authored theme choose tooltip contrast
without presentation code knowing palette names.

Alternatives considered: continue using `surfaceRaised`; hard-code popup colors;
add a bar-specific tooltip color outside the theme contract.

Consequences: runtime validation, JSON Schema, emergency fallback, authored
themes, fixtures, and token documentation require `tooltip`. This remains a
pre-release schema-v1 revision with no shipped migration obligation.

Affected areas: theme schema and validation, `ThemeService`, authored themes,
bar tooltip presentation, fixtures, and future generated-theme mappings.

Revisit if: tooltip surfaces later require separate normal, border, and rich
content tokens.

### ADR-015: Adopt Matugen-style paired semantic roles before release

Status: Accepted by user on 2026-08-25

Decision: replace the provisional 15-token camelCase theme-v1 vocabulary with
the approved 32-role `snake_case` contract documented in the Phase 4 audit. Use
paired `on_*` foregrounds for authored surfaces and accents; distinct hover,
pressed, focus, disabled, placeholder, link, and highlight roles; existing QE
success, charging, warning, and error states; and shadow/scrim utilities.

Context: current presentation forced unrelated roles to share colors, including
selected text with a background token, disabled content with secondary active
text, inline hover with tooltip surfaces, and tooltip foreground with generic
text. Planned selectors, notifications, launcher, dashboards, and lock surfaces
would multiply those ambiguities. The user requested broader surface,
interaction, accessibility, link, and highlight coverage and Matugen's naming
style before the contract becomes a generator input.

Rationale: Matugen exposes `snake_case` Material roles and paired foregrounds,
so retaining that convention reduces template translation and makes contrast
relationships explicit. QE-specific roles remain only where the generated
scheme has no direct shell semantic. The contract is still pre-release and has
no shipped external consumers, making one coordinated revision safer than
compatibility aliases or an immediate schema v2.

Alternatives considered: retain the 15-token contract; the rejected 19-token
camelCase proposal; import every Matugen role without QE curation; add
component-specific notification, slider, dashboard, or lock tokens; add pending
and urgency status colors in this revision.

Consequences: runtime validation, JSON Schema, emergency fallback, authored
themes, fixtures, all existing consumers, tests, architecture documentation, and
future Matugen templates use the 32 names atomically. Authored and generated
surface/foreground pairs target 4.5:1 normal-text contrast and 3:1 for large
text, meaningful icons, focus, and boundaries. Theme identity is preserved, but
derived palette values are allowed where required for contrast. Pending intent
uses primary emphasis plus motion or text rather than warning or success.

Affected areas: theme-v1 contract, all QE presentation, manual theme conversion,
Matugen templates, selectors, notifications/OSDs, launcher/help, dashboards,
and the isolated lock theme reader.

Revisit if: implemented surfaces expose a semantic role that cannot be composed
from this vocabulary, or Matugen changes its stable generated-role contract.

### ADR-016: Use separate namespaced IPC targets for transient surfaces

Status: Accepted by user on 2026-08-25

Decision: use one module-owned `IpcHandler` target per transient surface, named
`qe-<surface>`, rather than one central `qe` handler. Expose consistent typed
`open`, `close`, `toggle`, and `isOpen` methods where applicable. Route requests
through `SurfaceService`, which owns requested visibility; let `shell.qml` lazily
instantiate presentation surfaces.

Context: Phase 4's theme selector required the previously missing stable
surface-opening convention. A single `qe` target would simplify the first CLI
command but would grow a shared integration boundary, couple unrelated optional
modules, and create parallel-development contention. Module-scoped targets keep
registration, tests, lifecycle, and degradation local.

Alternatives considered: one `qe` target with descriptive methods such as
`openThemeSelector`; presentation-owned handlers; a generic string-based
`open(surface)` router; direct domain mutation from IPC.

Consequences: the theme selector target is `qe-theme`, invoked for example with
`qs ipc call qe-theme toggle`. Future surfaces follow the same namespace and
method convention but register only when implemented. `SurfaceService` may
coordinate exclusivity later without absorbing IPC adapters. Existing external
desktop entries and Hyprland keybindings remain unchanged until their documented
cutover criteria pass. No QE IPC endpoint may unlock or carry authentication
responses.

Affected areas: shell assembly, transient surface lifecycle, IPC adapters,
Hyprland bindings at later cutovers, module tests, and future launcher/help and
control-center surfaces.

Revisit if: Quickshell adds a typed hierarchical IPC namespace or operational
evidence shows separate target registration harms reliable reload behavior.

### ADR-017: Keep external operation identity at the QE adapter boundary

Status: Accepted as part of the approved Phase 4 machine contract on 2026-08-25

Decision: use the switcher's schema-v1 document as durable external desktop
state without a QE operation ID. `ThemeService` assigns a local operation ID
before invoking machine mode, `CommandRunner` carries it through the bounded
process lifecycle, and stale process results are rejected by that local ID.

Context: the switcher remains independently usable, and its persisted document
describes external state that may be produced by QE, its human CLI, or another
machine caller. Persisting a QE-generated ID would imply QE ownership and would
not identify independent invocations meaningfully. QE still needs operation
identity to prevent stale process completion from overwriting current UI state.

Alternatives considered: require every switcher caller to provide and persist an
operation ID; let QE infer result identity only from requested theme; omit
operation association in QE.

Consequences: the machine syntax remains
`run.sh --machine --theme <id> [--skip-gtk]`; its state/result schema contains
theme, status, timestamp, persistence, error, and per-target outcomes but no
caller identity. QE serializes theme requests through an active external phase
and associates only direct process results with its local operation ID. File
watch updates are external state observations and never complete a QE operation
or mutate the active QE theme.

Affected areas: external switcher schema v1, `ExternalThemeAdapter`,
`ThemeService`, selector status, command fixtures, and external state watching.

Revisit if: the switcher adds concurrent remote callers that require shared
cross-process request correlation rather than independent durable state.

### ADR-018: Stage QE wallpaper themes before promotion

Status: Accepted as part of the Phase 4 wallpaper implementation on 2026-08-25

Decision: Matugen output mapped to the QE `Wallpaper` schema is written to a
per-operation staging path under the QE data directory. A dedicated promotion
adapter atomically renames the staged artifact into the catalog-visible
`Wallpaper.json` path only after the staged write succeeds.

Context: direct writes to the catalog-visible generated file made the current
foundation safe at the single-file level but did not expose a distinct
generation/promotion boundary. The Phase 4 contract requires generated output
to remain out of authored themes and to retain the complete last-known-good set
when generation or promotion fails.

Rationale: keeping staging and the target on the same filesystem gives the QE
artifact a replace operation with clear failure semantics. The adapter remains
replaceable when approved external Matugen targets add more artifacts.

Alternatives considered: write directly with `FileView.atomicWrites`; invoke
Matugen templates from the shell; implement multi-artifact promotion in QML.

Consequences: an interrupted generation can leave an unpromoted staging
directory, which is harmless derived data and can be cleaned in a later startup
maintenance step. External artifact promotion and compositor application remain
separate contracts; this ADR does not authorize edits to the legacy picker.

Affected areas: `WallpaperService`, `MatugenAdapter`,
`WallpaperPromotionAdapter`, generated QE theme state, and Phase 4 fixtures.

Revisit if: external generated artifacts require cross-filesystem promotion or
an atomic directory-set replacement rather than per-artifact replacement.

## ADR-019: QE-generated external wallpaper theme slots

Context: the architecture promised Matugen output that includes "configured
external application artifacts", but the external target contracts were not
approved. The accepted model is that QE owns generation and the external
theme-switcher owns external application, so QE must produce theme files the
switcher's existing apply scripts consume without writing any live config.

Decision: while the active QE theme is `wallpaper`, QE maps the captured
Matugen palette into a `wallpaper` theme slot per supported app and promotes
each file atomically into the app-specific slot (kitty, bat, btop, eza, dunst,
fzf, hyprland, hyprlock, imv, mpv, rofi, starship, tmux, opencode, and Yazi)
plus an nvim palette JSON under XDG cache for the local `colors/wallpaper.vim`
colorscheme. `WallpaperExternalThemeAdapter` materializes a validated spec via
`scripts/promote-external-theme.sh`, skips targets whose executables are
absent, and reports per-target results. QE never writes active application
configuration; after promotion it delegates `--machine --theme wallpaper
--skip-gtk` to the switcher, which performs the documented copy-to-active.
imv and mpv consume generated background slots, while Yazi consumes its
generated semantic palette and syntax file.
GTK is excluded because Matugen has no GTK generator.

Rationale: this preserves standalone switcher function, avoids two owners of
the same live config, and keeps "wallpaper" a normal theme ID from the
switcher's perspective. Applying a wallpaper always regenerates the QE
Wallpaper theme and slot files so the generated theme stays selectable;
external application is delegated only while the wallpaper theme is active,
which prevents a wallpaper change from overwriting fixed external themes.

Alternatives considered: QE writing external live configs directly (creates
file contention with the switcher); Matugen native template output (rejected
in favor of QE-owned generation); installing `matugen.nvim` for nvim
(extra plugin dependency and palette-format coupling; the local colorscheme
avoids both while remaining swappable for the plugin later).

Consequences: external slot files are derived data written into app config
trees by approved contract; failed or skipped targets are reported without
rolling back already-promoted files. Promotion is content-idempotent and
follows restore-managed slot symlinks, so generation never rewrites a tracked
default. The QE repository keeps authored defaults under `defaults/wallpaper`.
The preflighted `qe-defaults restore` command restores the stable XDG QE theme,
wallpaper/lockscreen images, Neovim palette, and external runtime files before
creating or repairing ignored live slot links; `capture` is the intentional
default-change operation. This makes
the generated QE `wallpaper` theme selectable before the first wallpaper
selection on a fresh installation. The self-contained nvim colorscheme means
neovim follows the wallpaper only while the wallpaper theme is active. The
generated catalog is refreshed after atomic replacement, and wallpaper
external application has one generation-completion dispatch point to avoid
concurrent switcher requests. Generated QE tokens use `#AARRGGBB` alpha to
match authored themes, and the generated `wallpaper` rofi colorscheme defines
the full variable set the main rofi theme references. opencode loads and caches
its theme colors at launch, so a regenerated wallpaper theme requires an
opencode restart even when the switcher live-re-selects the theme name in
tmux-hosted instances. imv, mpv, and Yazi similarly require new instances to
load regenerated configuration.

Affected areas: `ExternalWallpaperTheme.mjs`, `WallpaperExternalThemeAdapter`,
`promote-external-theme.sh`, `WallpaperService`, `ThemeService`,
`ExternalThemeAdapter`, nvim `colors/wallpaper.vim`, and Phase 4 fixtures.

Revisit if: an external app changes its theme slot layout, a target needs
cross-filesystem promotion, or the user selects `matugen.nvim` as the nvim
consumer.

## ADR-020: Apply-time focused Kitty bar compositing

Context: generated wallpaper themes used a fixed QE panel alpha and Matugen's
surface color, while Kitty separately applied its background opacity and
Hyprland applied window opacity. This made the generated bar visibly differ
from a focused Kitty window, especially for automatically generated palettes.

Decision: when generating the wallpaper theme, QE captures Kitty's effective
`background_opacity` and queries Hyprland's live
`decoration:active_opacity`. The generated `surface_panel` uses the Matugen
wallpaper background with the product of those values as its alpha. Kitty and
Hyprland remain the owners of their settings; QE does not introduce a shared
opacity setting or runtime watchers. Missing configuration files, missing
settings, unavailable IPC, malformed values, and out-of-range values use full
opacity (`1.0`). A later upstream change is reflected when the wallpaper theme
is next generated or applied.

Rationale: this matches the requested focused-window appearance without
polling or duplicating Kitty configuration. Applying the alpha to the bar is
necessary because Hyprland window opacity does not automatically apply to the
QE layer surface.

Alternatives considered: watching both configuration sources (unnecessary
runtime work and more lifecycle complexity); adding a QE-owned Kitty opacity
setting (creates competing ownership); using the Matugen surface token (does
not match Kitty's terminal background).

Consequences: an already-generated theme can remain stale after an upstream
opacity edit until the next wallpaper-theme application. Kitty include files
are resolved by the bounded helper, while Hyprland is queried from the live
compositor rather than assuming a config filename or syntax.

Affected areas: `MatugenAdapter`, `Matugen.mjs`, `Opacity.mjs`,
`qe-window-opacity.sh`, generated wallpaper themes, and validation fixtures.

Revisit if: Kitty or Hyprland expose a stable native event/API that makes
live synchronization valuable, or if the bar must match inactive windows too.

## ADR-022: Project-owned authored defaults bundle

Status: Accepted by user

Context: the default theme was a behavior-config field in `config/qe.json`,
while wallpaper images and generated wallpaper-theme artifacts were captured by
a dotfiles-owned `qe-wallpaper-default` helper. Changing or restoring the
desktop default therefore required two owners and two workflows.

Decision: QE owns one authored bundle under `defaults/`. The validated
`defaults/manifest.json` owns `defaultTheme`; `DefaultsService` exposes it to
`ThemeService`, while persisted active theme state remains separate. Wallpaper
images live under `defaults/wallpaper/images`, and generated QE/application
theme artifacts live under `defaults/wallpaper/generated-theme`. The
project-owned `scripts/qe-defaults capture|restore` command is the sole bundle
writer. Capture reads confirmed active state through typed IPC and promotes a
fully staged snapshot. Restore preflights all files, repairs runtime links, and
applies the manifest theme through running QE or the external switcher fallback.

Rationale: theme, wallpaper, and generated wallpaper-theme defaults form one
desktop-state snapshot rather than general shell behavior configuration. One
project owner makes capture reviewable, avoids cross-repository synchronization,
and keeps runtime XDG state distinct from authored defaults.

Alternatives considered: retain `defaultTheme` in `config/qe.json` (mixes
captured state with manually authored behavior settings); keep wallpaper
defaults in dotfiles (split ownership); automatically clear Quickshell state
while QE is stopped (couples the helper to hashed internal state and can destroy
an unrelated active selection).

Consequences: `config/qe.json` no longer contains `defaultTheme`; a malformed
manifest degrades to the safe Poimandres default. Capture requires a running QE
instance and refuses pending operations. Restore can materialize files before QE
starts, but only a running QE instance can confirm live QE theme and wallpaper
application. External application remains best effort and does not roll back
restored files.

Affected areas: `DefaultsService`, `ThemeService`, defaults schemas and files,
typed theme/wallpaper IPC, `scripts/qe-defaults`, dotfiles runtime-slot ignores,
and default-management documentation and fixtures.

Revisit if: QE gains a stable process-independent control endpoint or the
authored defaults need versioned migration beyond the manifest schema.

## ADR-021: Vim-style selector navigation convention

Status: Accepted by user

Decision: focused QE windows with selectable elements support lowercase `h`, `j`,
`k`, and `l` as aliases for left, down, up, and right arrow navigation. A
lowercase `q` is an alias for Escape when Escape dismisses the focused window.
Native arrow keys, Escape, and existing activation keys remain supported.

Context: the theme and wallpaper selectors use focused grid views and already
support keyboard navigation and Escape dismissal. The user requested a
consistent vim-style alternative for these selectors and future QE surfaces.

Rationale: the convention provides efficient keyboard navigation without
removing standard keyboard behavior or changing compositor-owned global
keybindings. Handling remains local to the focused selectable view, preserving
view-local interaction ownership.

Consequences: future selectable QE windows should expose the same aliases when
they provide arrow-key navigation or Escape dismissal. Uppercase or modified
vim keys are not aliases, so they remain available to controls that need them.

Affected areas: `modules/theme/ThemeSelector.qml`,
`modules/wallpaper/WallpaperSelector.qml`, and future selectable QE surfaces.

Revisit if: a future input method requires modified vim keys, or a shared
keyboard-navigation component becomes justified by additional surfaces.

## ADR-022: QE-generated Yazi wallpaper flavor

Status: Accepted by user

Decision: generate Yazi's `wallpaper` flavor from the Matugen semantic palette as
one shell palette plus one TextMate syntax file. Promote both files into the
`wallpaper.yazi` slot, then let the external switcher generate `flavor.toml` from
Yazi's shared template and select the flavor through `theme.toml`.

Context: the external switcher's Yazi integration was redesigned to use a single
semantic palette source and a shared flavor template. Yazi also requires a
`tmtheme.xml` syntax artifact, so a palette-only integration would not satisfy
the existing apply contract.

Rationale: QE and the switcher share one wallpaper-derived color source while
Yazi retains ownership of template expansion and active-flavor selection. The
switcher replaces only generated `flavor.toml`, preserving restore-managed slot
links and unrelated Yazi configuration.

Consequences: QE reports two Yazi promotion results, and missing Yazi skips both
artifacts. Capture migrates a directly-generated Yazi slot into QE runtime state
and repairs its link when the slot has not yet been restored. Existing Yazi
instances do not reload a changed flavor and require a restart. The generated
Yazi syntax colors are intentionally derived from the same palette rather than
copied from an authored flavor.

Affected areas: `ExternalWallpaperTheme.mjs`, `apply_yazi_theme.sh`,
`scripts/qe-defaults`, generated wallpaper artifacts, and Yazi integration
fixtures.

Revisit if: Yazi gains reliable live theme reload or changes its flavor slot
contract.

## ADR-023: QE-generated imv and mpv wallpaper slots

Status: Accepted by user

Decision: generate dedicated `wallpaper` background slots for imv and mpv from
the current Matugen palette. The external switcher's imv and mpv scripts consume
those slots when applying `wallpaper`; authored themes continue using their
existing static mappings.

Context: adding a fixed `wallpaper` value to each switcher script would make the
theme stale after the next wallpaper change. imv and mpv use different config
syntax, but both expose a single background color relevant to this integration.

Rationale: generated slots preserve the established QE generation and external
switcher ownership boundary while allowing every wallpaper change to update the
actual color. The scripts validate the generated slot before editing the active
config.

Consequences: QE adds imv and mpv to wallpaper promotion and defaults capture/
restore. Missing applications are skipped by the existing executable checks;
missing or malformed wallpaper slots are reported as target failures. Existing
imv and mpv processes are not restarted and require a new process to load the
updated configuration.

Affected areas: `ExternalWallpaperTheme.mjs`, `apply_imv_theme.sh`,
`apply_mpv_theme.sh`, `scripts/qe-defaults`, generated wallpaper artifacts, and
external-theme fixtures.

Revisit if: either application changes its configuration syntax or gains a
reliable runtime background update path.

## ADR-024: Isolated QE notification ownership prototype

Status: Accepted by user on 2026-08-29

Decision: implement notification ownership through the native Quickshell
`NotificationServer`, with a separate structured DBus owner watcher for readiness
and diagnostics. DND suppresses Low and Normal popups but retains their
current-process history; Critical notifications remain visible. The Phase 5
acceptance test may stop Dunst in the current graphical session only within a
trapped stop/test/restart procedure. Production Dunst disablement, keybinding
migration, legacy producer changes, and hardware OSDs remain deferred to Phase 6.

Context: the notification DBus name is exclusive, while Quickshell 0.3.1 exposes
notification capabilities and objects but no QML property reporting successful
service acquisition. Dunst currently owns the name through a static DBus-activated
user service, and existing hardware producers still target Dunst.

Rationale: native notification delivery preserves Quickshell object lifetime and
event handling. A structured owner boundary prevents QE from claiming readiness
when Dunst or another service owns the name. The trapped test preserves the daily
fallback without pretending that two notification servers can coexist.

Alternatives considered: one-shot owner probes, early production Dunst disablement,
and keeping notification work entirely behind Dunst. One-shot probes do not report
owner loss promptly; early disablement violates staged migration; deferral provides
no validation of the notification contract.

Consequences: Phase 5 requires an independently tested owner-watcher contract,
bounded untrusted-content rendering, and explicit owner checks before and after the
exclusive test. Notification history is intentionally lost when QE exits, and
existing Dunst-based keybindings and producers remain the rollback path.

Affected areas: `NotificationService`, `NotificationsIntegration`, notification
modules, owner-watcher helper, notification configuration, diagnostics, and Phase 5
validation scripts.

Revisit if: Quickshell exposes reliable notification ownership state, or a separate
DBus test session becomes necessary to protect the primary session.

## ADR-025: QE-owned OSD and reversible action cutover

Status: Accepted for Phase 6 implementation

Decision: hardware feedback is owned by an independent QE OSD service rather than
being sent through desktop notifications. Hardware keybindings call typed QE
IPC actions. Dunst is blocked with a reversible user-service mask only after
the switcher's Dunst target is retired, and rollback restores the original
bindings, target list, service activation, and legacy producers.

Context: Dunst and QE cannot own `org.freedesktop.Notifications` concurrently.
The existing hardware scripts also combine subsystem mutation with Dunst
feedback, while native PipeWire and MPRIS APIs are available for the required
operations.

Rationale: separating OSD feedback from notification delivery prevents a
notification-owner failure from breaking hardware controls, preserves truthful
pending/confirmed state, and makes the ownership transition independently
reversible. The user selected persistent masking in the symlinked dotfiles
systemd directory and approved preservation of the legacy volume semantics.
The presentation policy uses one active slot so newly triggered feedback is
visible immediately and superseded state is not replayed after its relevance
has passed.

Consequences: Phase 6 adds OSD/action fixtures, native microphone and media
coverage, and a keyboard LED adapter. The external theme switcher continues to
support Dunst as a source target but skips it through the validated retirement
list after cutover. Persistent notification history remains deferred.

Revisit if: QE gains a native action transport that is more stable than the
current namespaced IPC contract, or keyboard LED discovery cannot be made
portable without a user-authored device override.

## ADR-026: Notification center as a layer-shell sidebar

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

## ADR-027: Dedicated sidebar surface token

Status: Accepted by user on 2026-08-30

Decision: add `surface_sidebar` as a required semantic theme token and make the
reusable `components/Sidebar.qml` consume it by default. Poimandres uses its
`palette.black` color with alpha `f5` (`#f5171922`). Gruvbox adds
`palette.sidebar` as `#1d2021` and uses the corresponding alpha color
`#f51d2021`. The generated wallpaper theme derives its sidebar source color by
reducing the Matugen background's HSL lightness by 9/255 while preserving hue
and saturation, then applies the existing captured opacity.

Context: `surface_panel` is shared by bars, selectors, and panels, while the
sidebar needs a distinct darker surface. Matugen's optional `surface_container*`
colors do not guarantee the required relationship across variants.

Rationale: a schema-wide semantic role keeps normal components independent of
raw palette names. The measured HSL delta matches the requested Gruvbox
separation without imposing Gruvbox's cool tint on generated wallpaper themes.

Consequences: the theme-v1 contract expands from 32 to 33 roles. Runtime
validation, JSON Schema, emergency fallback, authored themes, fixtures, the
generated wallpaper artifact, and theme tests must be updated together.

Affected areas: `components/Sidebar.qml`, `utils/Matugen.mjs`, theme schema and
validation, authored and generated themes, and theme/QML validation.

Revisit if: generated wallpaper palettes need a user-configurable sidebar
darkening amount or a distinct sidebar foreground role.

## 14. Planning Change Procedure

When implementation reveals a reason to change an accepted decision:

1. Describe the concrete evidence and affected behavior.
2. Identify affected plan phases, contracts, risks, and migration steps.
3. Propose a replacement and alternatives.
4. Document consequences and compatibility impact.
5. Update `docs/ARCHITECTURE.md` if boundaries or ownership change.
6. Add or update an ADR in this document.
7. Obtain user clarification before changing scope, security, state ownership,
   external behavior, or a previously accepted decision.

Agents must not silently implement around the plan.
