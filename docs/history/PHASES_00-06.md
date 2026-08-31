# QE Completed Phase History: Phases 0-6

Status: Historical reference; non-authoritative for current QE behavior

This file preserves completed implementation, acceptance, rollback, and handoff
records that previously lived in `docs/PLAN.md`. The material is retained so
token optimization does not destroy the project's audit trail.

For current work, read `AGENTS.md` and the relevant live sections of
`docs/PLAN.md`, `docs/ARCHITECTURE.md`, and `docs/DECISIONS.md`. Consult this
file only when earlier implementation evidence or rollback history is relevant.

## Archived Phase 6 completion handoff

The following handoff was the live `docs/PLAN.md` handoff at the time this
history file was created:

### Original next-session handoff

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
- Phase 6 is complete, including the closed rollback window and post-cutover
  archival of deprecated Dunst, Walker, battery, and legacy hardware-control
  files under `~/dotfiles/_legacy`. QE owns notifications and hardware feedback;
  begin new work at Phase 7.
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

## Archived live planning-context snapshot

The following live working sections are preserved verbatim from the 2026-08-31
plan before compaction. Some items continue in the current plan; this snapshot
exists only for provenance.

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

## Retired planning context

### Retired completed-phase assumptions

The following assumptions were removed from the live plan after their dependent
phases completed. They are preserved verbatim from the 2026-08-31 plan:

- Quickshell 0.3.0's installed native services are stable enough for the first
  bar slice.
- A non-exclusive or alternate-edge development bar can coexist with Waybar
  without disrupting daily use.
- Current manually authored theme palettes can be mapped to one complete QE
  semantic-token schema without changing their visual identity.
- Matugen templates can generate valid artifacts for the selected external
  target set before any apply step runs.

### Resolved open question removed from live context

| Question | Blocking phase | Resolution point |
| --- | --- | --- |
| Which Hyprpaper IPC path gives reliable apply confirmation? | Phase 4 | Compare current helper with current Hyprpaper documentation/runtime |

## Completed implementation phase records

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

Status: Complete (implementation, reversible production cutover, rollback, and
post-cutover cleanup validated 2026-08-31)

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

Post-cutover dotfiles cleanup (completed 2026-08-31):

- The Phase 6 rollback window is closed. Deprecated battery, audio, brightness,
  microphone, keyboard-brightness, battery-unit, Dunst, Walker, and inactive
  Hyprlang files were moved with `git mv` into `~/dotfiles/_legacy`, preserving
  their history and original relative layouts.
- The corresponding stale deployed files and Dunst link were removed after
  verifying they matched the archived sources. Native QE alerts, hardware
  controls, notification ownership, and the active Lua Hyprland bindings remain
  independent of the archive.
- Recovery requires moving the relevant archived tree back to its original
  package path, restoring the deployed files/links, unmasking and starting
  Dunst, and restoring the pre-cutover Hyprland bindings as described in the
  Phase 6 rollback procedure.

Native hardware-control ownership:

- Active audio, microphone, and screen-brightness bindings are QE-owned through
  `scripts/qe-action.sh`, `integrations/ActionsIpc.qml`, `services/AudioService.qml`,
  `integrations/PipewireIntegration.qml`, `services/BrightnessService.qml`, and
  `scripts/qe-brightness.sh`.
- The dotfiles `volume`, `brightness`, and `mic-mute-toggle` scripts are no
  longer used by active Hyprland bindings. The inactive Hyprlang configuration,
  including its old keybindings, is archived under `~/dotfiles/_legacy/hypr`.

Native media ownership:

- Active media keybindings are QE-owned through `services/MediaService.qml`,
  `integrations/MprisIntegration.qml`, and `qe-actions`; they do not invoke
  `playerctl`.
- The unstowed Walker configuration is not active because Walker is not
  installed or deployed. Its `playerctl` lock-screen entry is retained only as
  a legacy reference under `~/dotfiles/_legacy/walker`. The
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


## Archived migration and coexistence matrix at Phase 6 closure

The following matrix is preserved verbatim from the pre-compaction live plan.
Completed cutover rows are historical evidence; do not treat them as current
migration instructions.

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
