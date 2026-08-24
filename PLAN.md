# QE Implementation Plan

Status: Phases 1-2 complete; Phase 3 has not started

Last inventory: 2026-08-24

This is the authoritative roadmap, implementation sequence, dependency map,
project-status reference, risk register, and architectural decision log for the
Quickshell Environment (QE). `ARCHITECTURE.md` is authoritative for system
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
| Architecture | Complete for implementation start | Authoritative boundaries are in `ARCHITECTURE.md` |
| Project code | Foundation implemented | Executable shell bootstrap, services, integration convention, schemas, themes, and tests exist |
| Foundation | Complete | Phase 1 acceptance passed on 2026-08-24 |
| Bar vertical slice | Complete | Phase 2; top reserved edge selected, tray host disabled during Waybar coexistence |
| Bar parity and Waybar cutover | Not started | Phase 3 |
| Theme/Matugen integration | Not started | Phase 4 |
| Notifications/OSDs | Not started | Phases 5-6 |
| Launcher/help | Not started | Phase 7 |
| Dashboards/control center | Not started | Phases 8-10 |
| Lock replacement | Not started | Phase 11 |
| Production migration | Not started | Phase 12 |

### 2.1 Next-session handoff

- Read `AGENTS.md`, `ARCHITECTURE.md`, and this plan in that order before making
  changes. Phase 2 is complete; Phase 3 is the next roadmap phase but must not
  begin until its prerequisites at the Phase 3 section are confirmed.
- The reviewed Waybar module classification is recorded in the Phase 2
  implementation record. Metrics adapter design approval and explicit permission
  to edit `~/Projects/theme-switcher` remain Phase 3 gates. Do not infer either
  approval from Phase 2 completion.
- Normal development runtime is one QE shell from `shell.qml` plus the existing
  Waybar: QE reserves 26 pixels at the top, Waybar reserves 28 pixels at the
  bottom, and `config/qe.json` keeps `trayHostEnabled` false. Waybar must remain
  the sole `org.kde.StatusNotifierWatcher` owner until its documented cutover.
- The active authored/default QE theme is Poimandres. Theme-v1 includes the
  pre-release `charging` token documented by ADR-012.
- Full developer commands and expected markers are in `tests/VALIDATION.md`.
  The live NetworkManager loopback test is opt-in. Relocation was revalidated
  from `/tmp` at the Phase 2 exit.
- Physical external-monitor attach/detach could not be exercised because only
  `eDP-1` was connected. Carry that test into Phase 3 before Waybar cutover.
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
- The repository begins at `~/Projects/quickshell` and will eventually move to
  `~/.config/quickshell` under dotfiles management.

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
| Quickshell | 0.3.0-2 |
| Qt Declarative | 6.11.1-3 |
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

The local Quickshell source reference is 0.3.1, but implementation must verify
all used APIs against installed 0.3.0 metadata and documentation.

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
        `--> Phase 12 production supervision, relocation, and cleanup
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

- `PLAN.md`
- `ARCHITECTURE.md`
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
- directory/module structure from `ARCHITECTURE.md`
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
- The frozen theme v1 semantic tokens are `surfaceBase`, `surfaceRaised`,
  `surfaceOverlay`, `textPrimary`, `textSecondary`, `accentPrimary`,
  `accentSecondary`, `border`, `success`, `charging`, `warning`, `error`,
  `shadow`, and `scrim`. `charging` was added by an explicit Phase 2 pre-release
  contract revision. Palette keys remain theme-authored color names.
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

Objective: make the QE bar sufficient for daily use and replace Waybar through a
reversible configuration change.

Prerequisites:

- Phase 2 stable during regular use
- system metrics adapter design contract approved; implementation and validation
  occur in this phase
- Phase 2's current-module classification and essential cutover set are approved
- explicit approval to edit the separate `~/Projects/theme-switcher` project for
  the target-retirement prerequisite

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

Rollback/recovery:

- restore Waybar autostart and original window/reserved-area assumptions; stop QE
- re-enable the switcher's Waybar target when rolling back to Waybar

Out of scope:

- notification, launcher, dashboard, and lock replacements

### Phase 4: Theme, Matugen, and wallpaper platform

Objective: deliver complete QE theming and a stable cross-project best-effort
desktop theme workflow, including generated `Wallpaper` themes.

Prerequisites:

- Phase 1 theme contract stable
- approval before installing Matugen or editing the external projects
- external switcher repository backed up/version controlled

Scope:

- convert all current manual palettes to QE theme schema
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

Out of scope:

- production Dunst disablement, persistent history, hardware OSD migration

### Phase 6: Notification cutover and OSD migration

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

### Phase 12: Production hardening and relocation

Objective: make QE suitable for daily startup, dotfiles ownership, diagnostics,
and clean retirement of replaced tools.

Prerequisites:

- selected features stable in daily use
- cutover rollback procedures exercised

Scope:

- decide systemd user service versus Hyprland autostart
- single-instance and restart policy
- startup ordering and environment
- journal/Quickshell log integration
- move to `~/.config/quickshell` under dotfiles
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
- dotfiles-managed QE
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
- relocation and clean-state tests
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
| R16 | Wallpaper helper reports success before compositor display | Medium | Low/medium | label confirmation level, investigate Hyprpaper IPC, refresh/diagnostic | Phase 4 |
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

## 14. Planning Change Procedure

When implementation reveals a reason to change an accepted decision:

1. Describe the concrete evidence and affected behavior.
2. Identify affected plan phases, contracts, risks, and migration steps.
3. Propose a replacement and alternatives.
4. Document consequences and compatibility impact.
5. Update `ARCHITECTURE.md` if boundaries or ownership change.
6. Add or update an ADR in this document.
7. Obtain user clarification before changing scope, security, state ownership,
   external behavior, or a previously accepted decision.

Agents must not silently implement around the plan.
