# QE Implementation Plan

Status: Phases 1-13 complete; AI quota milestone complete

Last inventory: 2026-09-08

This document is the authoritative live roadmap, implementation sequence,
project-status reference, active/future phase scope, risk register, and polling
registry for the Quickshell Environment (QE).

`docs/ARCHITECTURE.md` is authoritative for current system architecture,
boundaries, ownership, lifecycle, failure, and security contracts.
`docs/DECISIONS.md` is the authoritative architectural decision log and rationale.
Historical implementation evidence and superseded working context live under
`docs/history/` and are not authoritative for current behavior.

If authoritative documents conflict, do not silently choose one. Stop relying on
the disputed claim, collect evidence, and resolve the conflict explicitly.

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
| Architecture | Complete | Current authoritative boundaries are in `docs/ARCHITECTURE.md` |
| Project code | Foundation implemented | Executable shell bootstrap, services, integration convention, schemas, themes, and tests exist |
| Foundation | Complete | Phase 1 acceptance passed on 2026-08-24 |
| Bar vertical slice | Complete | Phase 2; top reserved edge selected, tray host disabled during Waybar coexistence |
| Bar parity and Waybar cutover | Complete | Phase 3 acceptance passed 2026-08-25 |
| Theme/Matugen integration | Complete | Manual selector and external machine integration complete; Matugen mapping, staged promotion, QE-localized wallpaper selector, and Hyprpaper XDG-path application complete; external generated Matugen artifacts now delivered as QE-generated `wallpaper` theme slots applied by the external switcher, including imv, mpv, and Yazi; runtime/default artifact separation and idempotent promotion added; `QE_THEME_SWITCHER` wired for production through the installed `qe-theme-switcher` wrapper. Phase 4 acceptance passed on 2026-08-26 |
| Notifications/OSDs | Complete | QE owns notifications and OSDs; Dunst cutover, rollback, and post-cutover legacy cleanup passed 2026-08-31 |
| Launcher/help | Complete | Launcher, curated help surface, `Super+R` cutover, `Super+/` help binding, rollback, and focused-output multi-monitor acceptance passed 2026-09-01 |
| Audio/dashboard foundation | Complete | Shared dashboard foundation, audio dashboard, launcher access, resilience, and rollback acceptance passed 2026-09-02 |
| Bluetooth dashboard | Complete | Phase 9 dashboard, native lifecycle, disposable-device acceptance, fallback, and BlueZ restart validation passed 2026-09-02 |
| Network dashboard | Complete with upstream limitation | Phase 10 v1 implementation and approved-network validation passed; Quickshell 0.3.1 does not repopulate native devices after a NetworkManager restart, so the dashboard provides a temporary guarded `Restart QE` recovery action |
| Control center composition | Complete | Phase 11 implementation, automated validation, shortcut/dismissal checks, destination replacement, and focused-output multi-monitor acceptance passed 2026-09-05 |
| Control-center monitor layouts | Complete | Mirror/four-direction layouts and validated per-monitor stepped scaling passed automated and live acceptance 2026-09-05 |
| Workspace bar monitor scoping | Complete | Native monitor matching and active/occupied workspace filtering are service-owned and plugin-independent; physical multi-monitor acceptance confirmed by the user on 2026-09-08 |
| AI quota bar/dashboard | Complete | Shared bar chip and dashboard for OpenAI and OpenCode Go weekly and five-hour windows; provider endpoints remain external/unstable |
| Lock replacement | Complete | Phase 12 secure lock, production cutover, manual/idle/before-sleep acceptance, failure recovery, and multi-output validation passed 2026-09-07; Hyprlock rollback was exercised before retirement |
| Production hardening | Complete | Phase 13 supervision, deployment, diagnostics, recovery, clean-state, and fresh-login acceptance passed 2026-09-08 |

### 2.1 Current handoff

- Phase 12 is complete. QE owns the compositor-enforced lock, manual/idle/
  before-sleep paths, and native PAM authentication through `qe-lock`; Hyprlock
  is installed but retired. Current lock ownership, failure, and recovery
  constraints are in `docs/ARCHITECTURE.md` and `docs/DECISIONS.md`; detailed
  implementation and acceptance evidence is in
  `docs/history/PHASES_12-13.md`.
- Phases 9 and 10 are complete. Bluetooth uses native adapter/device lifecycle
  handling with Blueman fallback for interactive pairing because Quickshell 0.3.1
  has no pairing-agent API. Network management is bounded to native open/PSK
  operations, one deterministic active-device view, and explicit
  `nm-connection-editor` fallback; wired state is read-only. Detailed acceptance
  and rollback evidence is in `docs/history/PHASES_07-11.md`, and the network
  boundary is recorded in `docs/DECISIONS.md` as ADR-034.
- Quickshell 0.3.1 does not repopulate all native devices after a NetworkManager
  restart. The dashboard therefore exposes a temporary `Restart QE` recovery
  action for `NETWORKMANAGER_UNAVAILABLE`, using the guarded
  `scripts/run-qe.sh --restart` entry point. Remove it after an upstream fix is
  deployed and live restart recovery passes.
- Normal runtime is one guarded QE shell from `shell.qml`, reserving 26 pixels
  at the bottom with `trayHostEnabled` true. Waybar is absent from autostart and
  retired in the theme-switcher; QE owns `org.kde.StatusNotifierWatcher`.
- Idle inhibition persists its requested state in versioned QE state across
  persistent-shell restarts; compositor-active state remains unconfirmed and
  surface loss still releases the native inhibitor safely.
- QE owns desktop notifications and hardware-feedback OSDs. The Phase 6 Dunst
  cutover, rollback exercise, closed rollback window, and legacy cleanup are
  complete.
- Full developer validation commands and expected markers live in
  `docs/VALIDATION.md`.
- Physical external-monitor attach, independent-output startup, reorder, detach,
  and mirror restoration passed in Phase 3. A connected mirror changed to
  extended does not create a new Qt `QScreen`; reconnect the output or restart
  QE after that specific transition.
- Phase 13 is complete. The managed project checkout remains the production
  location. Hyprland triggers a systemd user service that owns the persistent
  shell, journal output, and bounded crash restart. Controlled current-session
  cutover, explicit restart routing, Quickshell child-crash recovery, and
  systemd main-process recovery passed on 2026-09-08. An isolated-XDG clean-state
  startup and controlled service stop/production-entry-point recovery also
  passed. Fresh login started exactly one supervised shell with the current
  Hyprland environment and correct notification/tray ownership; the user
  confirmed the bar and normal interactions.
- The read-only production doctor and operations guide are implemented. Current
  QE service, single-instance, notification-owner, tray-owner, dependency, and
  stable-entry-point checks pass. The user confirmed sustained daily use and
  closed the complete legacy fallback-profile requirement on 2026-09-08;
  scoped dashboard escape hatches remain supported.
- Workspace bar monitor scoping is complete. Each per-screen bar shows only
  positive-ID, active or occupied workspaces whose confirmed Hyprland monitor
  matches that screen. Empty workspaces remain intentionally hidden. Automated
  coverage and user-confirmed multi-monitor behavior both pass.

## 3. Current Working Context

The original discovery inventory has been moved to
`docs/history/INITIAL_SYSTEM_INVENTORY.md`. It remains useful evidence about the
starting environment but is not current-system authority.

### 3.1 Remaining replacement boundaries

| Area | Current fallback / coexistence boundary | Planned phase |
| --- | --- | --- |
| Primary application launcher | Rofi remains available for specialized flows; the accepted QE launcher owns the primary launcher binding | Complete |
| Audio dashboard | `pavucontrol` remains installed and is the escape hatch for unsupported routing | Complete |
| Bluetooth dashboard | Blueman Manager remains available, especially for unsupported pairing interactions | Complete |
| Network dashboard | `nm-connection-editor` remains available for unsupported profiles and advanced configuration | Complete |
| Session lock | QE owns the secure lock, idle, and suspend paths; Hyprlock is installed but retired | Complete |
| Production lifecycle | Managed checkout and Hyprland-triggered systemd user service are in production; diagnostics and recovery acceptance passed | Complete |

### 3.2 Historical records

- Completed Phase 0-6 implementation, acceptance, rollback, and archived handoff
  details: `docs/history/PHASES_00-06.md`
- Completed Phase 7-11 implementation, acceptance, rollback, and handoff details:
  `docs/history/PHASES_07-11.md`
- Completed Phase 12 implementation, acceptance, rollback, and handoff details:
  `docs/history/PHASES_12-13.md`
- Original discovery/current-system inventory captured before the completed
  migrations: `docs/history/INITIAL_SYSTEM_INVENTORY.md`

Do not read historical files by default. Consult them only when reconstructing
earlier evidence, rollback rationale, superseded constraints, or the origin of a
decision.

## 4. Accepted Requirements and Active Constraints

The full accepted-decision rationale is in `docs/DECISIONS.md`. The following
items remain useful live constraints:

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
- Keep notification history only for the current QE process initially.
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

There are no active assumptions blocking a named phase. The selected existing
`login` PAM stack and the native Quickshell PAM contract were exercised during
Phase 12 disposable and controlled live validation.

Completed-phase assumptions that are no longer active working context are
preserved in `docs/history/PHASES_00-06.md`.

### Open questions that block named phases

None currently recorded.

The resolved Phase 4 Hyprpaper-confirmation question is retained in
`docs/history/PHASES_00-06.md`, not in live working context.

### Deferred decisions

- final visual design and animation language
- fingerprint authentication
- enterprise Wi-Fi, hidden networks, VPN, proxy, and full profile editing
- Bluetooth OBEX and advanced profile management
- advanced PipeWire graph/routing editor
- automatic external-to-QE theme synchronization
- cross-compositor portability
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
        +--> Phase 8 Audio dashboard + shared dashboard foundation
        |      `--> Phase 9 Bluetooth dashboard
        |             `--> Phase 10 Network dashboard
        |                    `--> Phase 11 Control center composition
        |
        `--> Phase 12 Secure lock replacement

Phases 3-11 complete enough for daily use
        `--> Phase 13 production supervision, deployment decision, and cleanup
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
| Lock | Secure surfaces, PAM conversation, time/battery/background | Fingerprint, rich dashboards, notification handling | lock-safe config/theme, PAM, session lock, UPower optional | Fail closed; optional visuals omitted | No, completed in Phase 12 |
| Launcher | Discover, filter, rank, launch desktop entries | File search, arbitrary shell evaluation, plugins | DesktopEntries, theme, config | Explain launch failure; omit invalid entries | Yes |
| Notification popups | Own DBus server, lifecycle, actions, urgency, DND policy | Disk history initially | NotificationService, theme, config | Ownership conflict prevents readiness; no silent loss claim | No before notification center |
| Notification center | Current-process history, dismiss/actions, DND controls | Cross-restart history | NotificationService | Empty/unavailable state if server not owner | Yes until popups stable |
| Control center | Compose quick settings and dashboard access | Reimplement every dashboard inline | Domain services, module router | Individual tile unavailable | Yes |
| OSDs | Coalesced feedback for confirmed/pending operations | Use desktop notifications as OSD transport | OSD plus domain services | Show failure or suppress if source unknown | No before keybind migration |
| Bluetooth dashboard | Adapter/device discovery and common lifecycle actions | OBEX, guaranteed every pairing-agent mode | BluetoothService | Existing Blueman remains fallback | Yes |
| Network dashboard | Connectivity, Wi-Fi, known/PSK connections | Enterprise/VPN/full editor initially | NetworkService | Existing NM editor remains fallback | Yes |
| Audio dashboard | Input/output defaults, levels, mute, common streams | Full patchbay initially | AudioService | Existing pavucontrol remains fallback | Yes |
| Help | Curated keybindings/commands/reference | Claim live keybind authority from duplicated data | HelpService, config | Show source age/error | Yes |
| AI quota | Weekly and five-hour provider quota summaries in bar and dashboard | Credential management, token refresh, arbitrary providers before an adapter contract exists | AiQuotaService, read-only OpenCode auth adapter, provider APIs | Provider/window-local unavailable or stale state; shell remains usable | Yes |
| Wallpaper selector | Discovery, previews, apply, generated cache | Own image editing suite | WallpaperService, theme, helper | Prior wallpaper remains; cache regenerates | Yes |
| Theme selector | QE theme discovery/apply and external result status | Force external scope to match QE permanently | ThemeService, external switcher | QE can succeed with external warning | No for theme phase |
| Clipboard history | Open/search/decode clipboard history without duplicating clipboard storage ownership | Replace `cliphist` storage daemon initially | Clipboard adapter, launcher-style surface | Existing Rofi flow remains available | Yes |
| Pomodoro | Surface timer state/actions if a stable external contract is established | Reimplement or parse undocumented process state during bar cutover | Future timer service/adapter | Existing external tool remains separate | Yes |

## 8. Implementation Phases

### Completed phases 0-11

Detailed implementation, validation, cutover, and rollback records for phases
0-11 have been moved losslessly to `docs/history/PHASES_00-06.md` and
`docs/history/PHASES_07-11.md`.

| Phase | Status | Result |
| --- | --- | --- |
| 0 — Planning baseline | Complete | Inventory, architecture, ownership, risks, and implementation sequence established |
| 1 — Platform foundation | Complete (2026-08-24) | Executable foundation, configuration/state/theme contracts, diagnostics, adapters, and test harness established |
| 2 — Bar vertical slice | Complete | Coexisting bar slice validated |
| 3 — Bar parity / Waybar cutover | Complete (2026-08-25) | Essential bar parity, cutover, rollback, fresh-login, and multi-monitor acceptance passed |
| 4 — Theme, Matugen, wallpaper platform | Complete (2026-08-26) | Theme/catalog/selectors, Matugen generation, external wallpaper slots, defaults, and wallpaper application accepted |
| 5 — Notification prototype | Complete | Isolated QE notification ownership and service behavior validated |
| 6 — Notification cutover / OSD migration | Complete (2026-08-31) | QE notification and OSD ownership, reversible cutover, rollback exercise, and post-cutover cleanup completed |
| 7 — Launcher and help | Complete (2026-09-01) | Launcher acceptance, curated help surface, focused-output multi-monitor placement, `Super+R` cutover, `Super+/` binding, and Rofi rollback passed |
| 8 — Audio dashboard and shared surface foundation | Complete (2026-09-02) | Shared dashboard shell, audio dashboard v1, launcher action, resilience, and `pavucontrol` rollback passed |
| 9 — Bluetooth dashboard | Complete (2026-09-02) | Native lifecycle, bounded discovery, fallback, disposable-device, and BlueZ restart acceptance passed |
| 10 — Network dashboard | Complete with upstream limitation (2026-09-03) | Native personal Wi-Fi v1 and approved-network acceptance passed; temporary `Restart QE` recovery remains |
| 11 — Control center composition | Complete (2026-09-05) | Established dashboard composition, scoped command adapters, shortcut/dismissal behavior, destination replacement, and focused-output acceptance passed |

Read the historical phase record only when a current task depends on its detailed
evidence, rollback history, or implementation rationale.

### Completed AI quota milestone

Status: Complete. The read-only provider boundary, bar/dashboard behavior, stale
handling, consumer-scoped polling, and suspend/resume recovery are implemented.
Detailed acceptance and provider evidence is preserved in
`docs/history/PHASES_07-11.md`; the durable boundary is recorded in ADR-036.

### Workspace bar monitor scoping

Status: Complete (2026-09-08). Automated coverage and user-confirmed physical
multi-monitor behavior passed.

`CompositorService` owns native monitor matching and the policy that each bar
shows only positive-ID active or occupied workspaces for its confirmed monitor;
empty workspaces remain hidden. The implementation is independent of any
workspace-range or monitor-splitting plugin. Detailed implementation and
validation evidence is preserved in `docs/history/PHASES_07-11.md`.

### Phase 11: Control center composition

Status: Complete (2026-09-05). Dashboard composition, scoped command adapters,
shortcut/dismissal behavior, destination replacement, and focused-output
multi-monitor acceptance passed. The full implementation and acceptance record is
preserved in `docs/history/PHASES_07-11.md`; durable boundaries remain in ADR-037
through ADR-039.

### Phase 12: Secure lock replacement

Status: Complete (2026-09-07). QE owns the compositor-enforced lock and its
manual, idle, and before-sleep entry points through `qe-lock`; native PAM
authentication, multi-output coverage, failure recovery, and secure rollback
acceptance passed. Hyprlock is installed but retired.

Detailed implementation, validation, and recovery evidence is preserved in
`docs/history/PHASES_12-13.md`. Current lock contracts and security constraints
remain authoritative in `docs/ARCHITECTURE.md` and ADR-041 through ADR-044.

### Phase 13: Production hardening and deployment

Status: Complete (started and completed 2026-09-08). The user selected
Hyprland-triggered systemd user supervision, bounded automatic restart for
persistent-shell crashes, and the existing managed project checkout as the
production location.
Production launch configuration and controlled current-session cutover passed
on 2026-09-08. The production doctor and user-facing operations guide are now
implemented. The user confirmed sustained daily use and retired the complete
legacy fallback profile. Isolated-XDG clean-state startup passed; fresh-login
acceptance passed with exactly one supervised shell, the current compositor
environment, no retired conflicting process, and user-confirmed normal bar and
interaction behavior. Controlled stop and `qe-shell --service-start` recovery
also passed with ownership returning to the single supervised process.

Objective: make QE suitable for daily startup, managed deployment, diagnostics,
and clean retirement of replaced tools.

Prerequisites:

- selected features stable in daily use
- cutover rollback procedures exercised

Relevant decisions: ADR-010 (defer production supervision until runtime
evidence exists), ADR-045 (production supervision and deployment), and ADR-046
(retire the complete legacy fallback) in `docs/DECISIONS.md`.

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
- documented and verified supervised recovery path

Acceptance criteria:

- fresh login starts exactly one persistent QE instance
- optional daemon delay does not block startup
- crash/restart behavior matches documented policy
- all paths work from the final location
- no retired tool starts or owns a conflicting protocol
- recovery commands restore supervised QE without starting conflicting owners
- diagnostics identify missing dependencies and current ownership

Validation:

- fresh-login tests
- controlled crash/restart tests excluding secure lock crash on primary session
- selected-location and clean-state tests
- controlled QE stop/start recovery drill

Rollback/recovery:

- the agreed daily-use period has passed; retain direct QE and TTY lock recovery
  procedures, but no complete legacy desktop-shell fallback profile

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

## 10. Remaining Migration and Coexistence

Detailed completed-cutover evidence is preserved in
`docs/history/PHASES_00-06.md`, `docs/history/PHASES_07-11.md`, and
`docs/history/PHASES_12-13.md`. The live matrix contains only coexistence or
fallback boundaries that still matter to Phase 13.

| Existing tool | Can coexist? | Conflict / boundary | Disable condition | Development method | Rollback |
| --- | --- | --- | --- | --- | --- |
| Hyprlock | Installed but retired | one session lock at a time | QE owns secure lock, idle, and suspend paths | no QE integration | no supported rollback |
| Rofi | Yes | keybinding/user-flow duplication | primary launcher acceptance; specialized Rofi flows remain separately available | invoke QE launcher separately until cutover | restore `Super+R` |
| Blueman Manager | Yes | concurrent operations may confuse state | required common Bluetooth flows pass | open either dashboard manually | keep Blueman launcher |
| `nm-connection-editor` | Yes | concurrent edits can race | retire only for the explicitly supported profile scope | preserve fallback action | keep editor installed |
| `pavucontrol` | Yes | concurrent changes reconcile through PipeWire | common audio flows pass | preserve fallback action | keep `pavucontrol` installed |
| external theme selector/CLI | Yes by design | independent QE/external theme scopes may drift intentionally | never required to retire CLI | structured machine mode for QE | retain human CLI mode |

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
| AI provider quota | usage endpoints do not provide a local event source; system resume is a separate logind event | 5 minutes while a bar or dashboard consumer exists, plus an immediate resume-triggered cycle | one singleton adapter/poller and resume watcher shared by all monitors; stop at zero consumers | sequential provider requests remain one logical pending cycle, bounded response/auth reads, coalesced manual/resume requests, manual retry of QE-generated timeout/network backoff, provider backoff with `Retry-After` respected; pre-sleep cancellation prevents false failures | retain last-known values and mark stale after 15 minutes; one-minute local age refresh does not contact providers | AI quota milestone |

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
| R3 | Quickshell API compatibility can change across installed upgrades | Medium | Medium/high | verify installed qmltypes and matching version documentation before use | every new native integration |
| R4 | Theme partial application creates visible drift | High | Medium | independent scopes, per-target status, retry, no false global success | external switcher refactor |
| R5 | Matugen overwrites good artifacts with invalid output | Medium | High | staging, schema/target validation, atomic promotion, LKG set | every template/schema change |
| R6 | Legacy `theme_data` races with QE state | Medium | Medium | compatibility adapter only, distinct QE state, migrate ownership explicitly | wallpaper/theme migration |
| R7 | Direct command parsing leaks into QML UI | Medium | Medium | adapter rule, structured contracts, code review search | every process integration |
| R8 | Hidden polling causes battery/CPU cost | Medium | Medium | poller registry, consumer-aware polling, measured intervals | bar/system metric milestones |
| R9 | Network secrets leak through arguments/logs/state | Low/medium | High | native APIs, redaction, no persistence, security tests | network operation implementation |
| R11 | Multiple QE instances duplicate ownership/subscriptions | Medium | High | shell identity/single-instance guard and diagnostics | Phase 3 cutover |
| R12 | Soft reload duplicates notifications or subscriptions | Medium | Medium | reload tests, `lastGeneration`, centralized ownership | every singleton service |
| R13 | Hard-coded hardware/path assumptions return | Medium | Medium | PathsService, sensor discovery, path lint | every filesystem integration |
| R14 | Broad dashboard scope delays reliable foundations | High | Medium | explicit v1 non-goals and phased fallbacks | phase planning changes |
| R15 | External switcher target mutation partially corrupts config | Medium | High | target prevalidation, backups/staging where possible, per-target result | switcher refactor |
| R17 | Production restart loop destabilizes session | Low/medium | High | defer supervision, bounded restart policy based on evidence | Phase 13 decision |
| R18 | Notification content loads unsafe resources/markup | Medium | High | sanitize/limit rendering and resources | Phase 5 security review |
| R19 | External theme apply restarts a tool after QE has replaced it | Medium | High | target-retirement controls must precede each cutover and are included in rollback tests | Phases 3, 4, and 6 |
| R20 | Provider quota endpoints or OpenCode auth storage change without notice | Medium | Medium/high | strict normalized validation, provider-local degradation, read-only credential ownership, and no guessed windows | AI quota milestone |
| R21 | Workspace monitor identity or native object replacement leaves bar scoping stale | Low/medium | Medium | resolve monitor names through the native API, retain the reactive native model, omit entries when mapping is unavailable, and test monitor changes | workspace bar monitor scoping |

## 13. Planning Change Procedure

When implementation reveals a reason to change an accepted decision:

1. Describe the concrete evidence and affected behavior.
2. Identify affected plan phases, contracts, risks, and migration steps.
3. Propose a replacement and alternatives.
4. Document consequences and compatibility impact.
5. Update `docs/ARCHITECTURE.md` if current boundaries, ownership, lifecycle,
   security, or failure policy change.
6. Add or update the relevant ADR in `docs/DECISIONS.md`.
7. Obtain user clarification before changing scope, security, state ownership,
   external behavior, or a previously accepted decision.

Agents must not silently implement around the plan or accepted decisions.
