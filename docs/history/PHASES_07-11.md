# QE Completed Phase History: Phases 7-11

Status: Historical reference; non-authoritative for current QE behavior

This file preserves completed implementation, acceptance, rollback, and handoff
records that previously lived in `docs/PLAN.md`. Phase 7 is archived below;
future completed phases in this range should be appended losslessly as they
finish.

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
