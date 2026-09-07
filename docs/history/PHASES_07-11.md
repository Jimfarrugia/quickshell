# QE Completed Phase History: Phases 7-11

Status: Historical reference; non-authoritative for current QE behavior

This file preserves completed implementation, acceptance, rollback, and handoff
records that previously lived in `docs/PLAN.md`. Phase 7 is archived below;
future completed phases and related milestone records in this range should be
appended losslessly as they finish.

For current work, read `AGENTS.md` and the relevant live sections of
`docs/PLAN.md`, `docs/ARCHITECTURE.md`, and `docs/DECISIONS.md`. Consult this
file only when earlier implementation evidence or rollback history is relevant.

## Archived Phase 7: Launcher and help

Status: Complete (2026-09-01; acceptance, rollback, and focused-output
multi-monitor validation passed)

Objective: replace primary Rofi application launch and provide a curated help
surface while leaving specialized Rofi flows available.

Design baseline (2026-08-31): launcher decisions are settled for valid desktop
entries, including terminal applications launched through `$TERMINAL`,
active-monitor placement, a centered 35%-wide content-sized overlay panel with
up to six visible result rows, persistent successful launch counts, deterministic
search ranking, modified vim-style
navigation, and explicit launch-failure handling. See ADR-029, ADR-030, and
ADR-031 in `docs/DECISIONS.md`.

Prerequisites:

- Phase 1 platform and theme stable
- stable surface-opening IPC convention

Relevant decisions: ADR-011 (native integration before commands), ADR-016
(namespaced transient-surface IPC), and ADR-021 (vim-style selectable-surface
navigation) in `docs/DECISIONS.md`.

Scope:

- DesktopEntries-based app model
- search/ranking pure utilities
- keyboard and pointer navigation
- structured launch and launch errors
- help JSON schema and curated reference catalog
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

## Archived Phase 8: Audio dashboard and shared surface foundation

Status: Complete; acceptance passed 2026-09-02. The implementation, validation,
and rollback evidence is preserved in this historical record.

Objective: establish the shared dashboard/window pattern and replace common
`pavucontrol` use cases first because PipeWire has a strong native API. The
foundation must support later dashboards without fixing the eventual control
center composition prematurely.

Prerequisites:

- bar module launch points and surface routing stable
- AudioService proven in bar/OSD usage

Relevant decisions: ADR-011 (native integration before commands), ADR-013
(requested-only idle inhibition), ADR-016 (namespaced transient-surface IPC),
ADR-026/027 (sidebar surface and styling), and ADR-033 (dashboard surface
foundation) in `docs/DECISIONS.md`.

Scope:

- shared dashboard/window and quick-setting tile contracts
- shared dashboard shell: overlay placement, single-surface exclusivity,
  source-module routing, responsive width/height, and keyboard dismissal
- audio output/input lists, defaults, levels, mute, and common stream controls
- explicit `pavucontrol` escape hatch for unsupported operations

Likely affected files/subsystems:

- shared dashboard surface and routing components
- `modules/audio/`
- audio/power/idle services

Deliverables:

- reusable dashboard surface pattern
- audio dashboard v1
- first-class searchable launcher toggle action for the audio dashboard

Acceptance criteria:

- tiles reflect confirmed and pending state distinctly
- unavailable integrations do not block the panel
- default device, volume, and mute changes reconcile from PipeWire events
- hot-plug and WirePlumber restart behavior is safe
- unsupported routing opens or points to pavucontrol rather than faking support
- dashboard opens from the audio source module on the source module's monitor
- the shell preserves 20px bar/opposite-edge gaps and 20px content insets
- dashboard overflow scrolls within the bounded surface

Validation:

- fake model tests and live device operations
- daemon restart/hot-plug manual test

Rollback/recovery:

- pavucontrol remains installed and launchable

Out of scope:

- full PipeWire graph patchbay

## Archived Phase 9: Bluetooth dashboard

Status: Complete on 2026-09-02. Native pairing-agent capability was verified
unavailable in Quickshell 0.3.1; dashboard v1 and fallback implementation passed
focused live acceptance. Disposable-device validation with JBL Go Essential 2
passed discovery, pair, disconnect, reconnect, and removal, with controller state
restored afterward. Focused dashboard acceptance covered adapter power,
discovery listing and shutdown, device grouping/actions, and the Blueman fallback.
The approved BlueZ restart check passed: the service recovered, known devices
repopulated, the shell remained alive, and no stale connected state was shown.

Objective: replace common Blueman Manager use cases after native pairing
behavior is verified.

Prerequisites:

- shared dashboard/surface foundation
- native Bluetooth pairing-agent capability investigation

Relevant decision: ADR-011 (native integration before commands) in
`docs/DECISIONS.md`.

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

## Archived Phase 10: Network dashboard

Status: Complete with an upstream limitation on 2026-09-03. The dashboard v1,
native personal Wi-Fi operations, wired inspection, duplicate-profile handling,
security gating, unsupported-profile fallback, and approved-network
connect/disconnect validation passed. The live NetworkManager restart test
correctly observed the unavailable state, but Quickshell 0.3.1 failed to
re-enumerate the Wi-Fi device after NetworkManager returned. A temporary
`Restart QE` action uses the guarded `scripts/run-qe.sh --restart` entry point
until an upstream fix is available.

Objective: replace common network inspection and personal Wi-Fi management
without overclaiming full NetworkManager editor parity.

Prerequisites:

- shared dashboard/surface foundation
- agreed v1 boundary for connection types and secrets

Relevant decisions: ADR-011 (native integration before commands) and ADR-034
(network dashboard v1 boundary) in `docs/DECISIONS.md`.

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
- NetworkManager restart produces unavailable then fresh state; the fresh-state
  portion is blocked by the Quickshell 0.3.1 native backend limitation described
  above
- failed authentication is not shown as connected
- unsupported enterprise/VPN/profile cases retain `nm-connection-editor`
  fallback

Validation:

- fixture matrix passed through `NETWORK_DASHBOARD_TEST_PASSED`
- approved-network connect/disconnect passed against the current saved Wi-Fi
  profile; no credential was handled or logged
- missing NetworkManager behavior is exercised through fixtures
- `network-address-test.qml` passed with `NETWORK_ADDRESS_TEST_PASSED`
- `dashboard-shell-test.qml` and `phase2-service-test.qml` passed
- live restart evidence captured the sequence
  `available/current/wifi` -> `unavailable/unknown/disconnected`; NetworkManager
  itself returned to `active` and `connected/full`, but QE did not recover its
  native device model

Rollback/recovery:

- NetworkManager editor remains installed and accessible
- QE provides a temporary dashboard restart action through the guarded launcher

Out of scope:

- enterprise EAP, VPN, proxy, hidden-network creation, full profile editor unless
  separately approved after the v1 investigation

## Archived AI quota milestone: bar and dashboard

Status: Complete.

This standalone milestone is intentionally separate from Phase 11 because it adds
new external provider integrations. It provides a weekly quota bar chip and a
shared dashboard with weekly and five-hour windows for OpenAI Codex/ChatGPT and
weekly, five-hour, and monthly windows for OpenCode Go.

The helper reads OpenCode's auth store read-only. QE never refreshes, writes,
removes, or persists provider credentials. Expired OpenAI access tokens retain the
last-known value as stale until OpenCode refreshes its own auth file.

Acceptance criteria:

- the bar chip uses the existing `BarChip` styling, `robot_2`, and weekly remaining percentage;
- left click toggles the `ai-quota` dashboard and right click cycles the globally selected provider;
- the AI quota dashboard header provides a `refresh` control that starts one manual refresh cycle;
- the tooltip lists both providers' weekly remaining percentages;
- the dashboard displays weekly and five-hour windows independently for both providers and the OpenCode Go monthly window;
- missing credentials, endpoint failures, malformed data, and stale values remain local to this feature;
- no credentials enter QML state, command arguments, logs, diagnostics, fixtures, or QE state;
- dashboard and bar consumers share one poller and one helper operation;
- active consumers request an immediate refresh after system resume when the
  logind sleep signal is available;
- the selected provider persists as versioned state and defaults to OpenAI.

Out of scope: credential provisioning or refresh ownership, billing/API spend
budgets, arbitrary provider configuration, and guaranteed stability of the
undocumented upstream usage endpoints.

Completion handoff notes recorded on 2026-09-05:

- The AI quota milestone adds a read-only helper for OpenAI Codex/ChatGPT and
  OpenCode Go weekly and five-hour windows. Its bar chip is after metrics on the
  left: left click toggles the shared dashboard and right click cycles the
  persisted weekly provider selection. Credentials remain owned by OpenCode;
  expired OpenAI access stays stale until OpenCode refreshes its auth file.

## Archived workspace bar monitor-scoping milestone

Status: Implemented; physical multi-monitor acceptance remained pending when this
record was archived.

The bar remains instantiated once per Qt screen. Its workspace module scopes the
native Hyprland workspace model to the corresponding compositor monitor through
`CompositorService`; the service owns monitor identity matching and the policy of
showing only positive-ID active or occupied workspaces. Empty workspaces remain
available through Hyprland keybindings but are intentionally omitted from the bar.

This milestone is independent of any Hyprland workspace-range or monitor-splitting
plugin. Removing such a plugin leaves the native monitor mapping and bar behavior
valid, but removes any plugin-specific workspace placement or persistence rules.

Acceptance criteria:

- each bar resolves its Qt screen to the corresponding Hyprland monitor;
- active and occupied positive-ID workspaces appear only on their associated bar;
- empty, special, and other-monitor workspaces are hidden;
- a monitor lookup loss clears the affected workspace projection and a later
  topology update restores it;
- workspace activation forwards the native workspace operation through
  `CompositorService`;
- missing screen-to-monitor mapping produces no workspace entries;
- the injected compositor fixture covers the service contract;
- the policy is validated without requiring a live workspace plugin.

Validation:

- `timeout 5 quickshell -p tests/qml/workspaces-test.qml` prints
  `WORKSPACES_TEST_PASSED`;
- full QML lint and the existing phase 2/3 service tests pass;
- the persistent shell remains alive under the standard smoke test;
- live multi-monitor validation remains required to confirm independent bar
  contents and no change to bar reservations when a second output is available.

Rollback/recovery:

- remove the external workspace plugin and its Hyprland config imports/bindings;
- retain the QE changes, which continue to use native Hyprland monitor and
  workspace state without plugin-specific assumptions.

Out of scope: replacing the native reactive workspace model with a separate
normalized snapshot model, changing empty-workspace visibility, or defining
workspace numbering and placement rules for Hyprland.

Later completion evidence recorded in the 2026-09-05 handoff:

- The post-v1 control-center monitor-layout extension is implemented for
  `jim-x1c`. Automated helper, adapter, service, control-center, lint, schema,
  and shell smoke validation passes. Mirrored mode, all four extended
  directions, automatic QE restart from mirror to extended, and post-disconnect
  built-in-only behavior passed live acceptance on 2026-09-05. Hyprland 0.56
  reports a mirror target through numeric `mirrorOf` monitor ID; the helper
  accepts that confirmed representation and retains output-name compatibility.
- Per-monitor scaling exposes the six cleanly dividing 1920x1080 presets from
  `1.00` through `2.00`, previews values while dragging, applies on release, and
  preserves top-aligned logical geometry. Every step passed live validation on
  both outputs. Mirrored mode now hides HDMI's visually ineffective slider while
  retaining its saved value for Extended mode; initial-open behavior was also
  verified from a fresh surface.
- The service re-queries on `monitoradded`/`monitorremoved` Hyprland events so the
  Monitors section updates on secondary-output connect/disconnect without
  reopening the panel; when the secondary is absent only the primary scale is
  changeable.

## Archived Phase 11: Control center composition

Status: Complete. Implementation, automated validation, shortcut/dismissal checks,
destination replacement, and focused-output multi-monitor acceptance passed on
2026-09-05.

Completion handoff notes recorded on 2026-09-05:

- Phase 11 is complete. The control center composes the established network,
  Bluetooth, audio, notification, theme, and wallpaper surfaces. Its approved
  Rofi power-menu and `qe-defaults` actions are narrow typed adapters with
  confirmation for defaults capture and restore. `Super+Tab` is the new shortcut;
  `Super+Escape` remains the existing power-menu binding. Automated Phase 11
  validation now passes, and live shortcut, dismissal, and destination-surface
  replacement checks are verified. Focused-output placement was verified with an
  external monitor on 2026-09-05.

Objective: compose the completed dashboard capabilities into a control center after
the audio, Bluetooth, and network dashboards establish their stable v1 contracts.

Prerequisites:

- Phase 8 shared dashboard/surface foundation
- Phase 9 Bluetooth dashboard v1 and capability findings
- Phase 10 Network dashboard v1 and agreed unsupported-profile boundary
- concrete control-center requirements agreed from the completed dashboards

Agreed v1 specification:

- A centered focused-output overlay with 40px inner spacing, 40px header/content
  spacing, and `appearance.radius + 2` corner rounding.
- A left-aligned time and long localized date header, with notification and Rofi
  power-menu actions on the right.
- A two-column body with Wi-Fi, Bluetooth, DND, idle-inhibitor, output-volume,
  and microphone-volume quick-setting tiles. Volume and microphone tiles toggle
  mute on click and change their level by 5% per wheel step, unmuting on scroll.
- Right-clicking Wi-Fi or Bluetooth opens its existing dashboard. Existing
  dashboards and selector surfaces remain the detailed views.
- A Theme section with semantic palette previews, the established themed dropdown,
  palette viewer, wallpaper selector, capture-defaults, and restore-defaults
  actions. Capture and restore require confirmation.
- A post-v1 Monitors section selects mirrored or extended output layout. Extended
  mode offers left, up, right, and down placement for the one configured secondary
  output. Profiles remain authored in `monitors.lua`; QE persists only their
  selector and does not alter single-monitor or other-host rules.
- Independent stepped scale sliders for `eDP-1` and `HDMI-A-1` expose only
  `1.00`, `1.20`, `1.25`, `1.50`, `1.60`, and `2.00`. These are the values on the
  agreed `1.00-2.00`/`0.05` candidate grid that produce whole logical pixels for
  both dimensions of the configured 1920x1080 modes.
- The control center is opened through `qe-control-center` and `Super+Tab`.
  `Super+Escape` remains the existing Rofi power-menu shortcut.
- Opening another major interactive surface replaces the control center. Service
  failures, stale state, and pending operations remain local to their tile or
  section.

Phase 11 explicitly approves narrow adapters for the existing `rofi_power_menu`,
`scripts/qe-defaults capture|restore`, and closed-vocabulary monitor-layout helper
commands. This exception does not authorize arbitrary command execution, direct
power actions, or general monitor command construction in presentation QML.

Likely affected files/subsystems:

- `modules/controlcenter/`
- module router and surface service
- existing dashboard/domain service contracts only where composition exposes a
  concrete gap

Deliverables:

- agreed control-center v1 specification
- control-center composition surface
- quick-setting state summaries with explicit degraded states

Acceptance criteria:

- the agreed v1 layout and interactions are available on the focused output;
  `Super+Tab` opens it and `Super+Escape` remains Rofi
- all six tiles render confirmed, pending, unavailable, and stale states locally
- theme selection, existing surface navigation, and both confirmed defaults
  actions work without duplicating their service or script logic
- control center composes existing dashboard capabilities rather than duplicating
  system integration logic
- one unavailable dashboard or service does not block unrelated tiles
- monitor controls are unavailable without the configured secondary output;
  accepted changes are persisted and match confirmed live Hyprland topology
- per-monitor scale controls cannot request an invalid logical resolution, and
  directional placement remains adjacent after scaling
- mirrored mode exposes only the source `eDP-1` scale; the saved HDMI scale
  returns unchanged when Extended is selected

Validation:

- control-center fixture tests based on the finalized tile and state matrix
- keyboard, pointer, dismissal, and multi-monitor surface tests
- degraded and daemon-loss behavior for each represented service

Rollback/recovery:

- individual dashboard surfaces and their fallback tools remain launchable

Out of scope:

- additional unbounded domain integrations introduced solely for control-center
  composition
- changing the v1 scope of the audio, Bluetooth, or network dashboards

## Retired live-plan risks

The following risk-register rows were removed from the live plan during the
2026-09-07 maintenance pass after their associated migrations and acceptance
evidence completed. The rows are preserved here as historical planning evidence.

| ID | Risk | Likelihood | Impact | Mitigation | Trigger/review |
| --- | --- | --- | --- | --- | --- |
| R2 | Dunst and QE contend for notification DBus ownership | High during migration | High | staged exclusive tests and owner diagnostics | Phase 5 start and Phase 6 cutover |
| R16 | Wallpaper helper reports success before compositor display | Low | Low/medium | Hyprpaper IPC acceptance handshake implemented; confirmation labeled as IPC acceptance, not pixel display | Phase 4 |
