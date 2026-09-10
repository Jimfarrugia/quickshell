# QE Status

Status: Production baseline complete; maintenance and refinement mode

Last baseline update: 2026-09-10

This document is the authoritative live status surface for QE. It intentionally
does not contain implementation chronology, phase sequencing, detailed service
contracts, or test transcripts. Completed planning/acceptance history lives under
`docs/history/`; current design contracts live in `docs/ARCHITECTURE.md` and
`docs/architecture/`.

## Production baseline

| Area | Current baseline |
| --- | --- |
| Runtime | One guarded persistent QE shell from `shell.qml`, supervised by a Hyprland-triggered systemd user service with bounded restart and journal logging |
| Bar | QE owns the bottom 26 px reserved edge, tray host, monitor-scoped workspaces, clock, system indicators, and dashboard/module launch points |
| Themes and wallpaper | Authored themes, Wallpaper/Matugen generation, external generated theme slots, selector flows, semantic action states, neutral indicator roles, and Material surface-container hierarchy are complete |
| Notifications and OSDs | QE owns desktop notifications, current-process notification history/center, DND, and hardware-feedback OSDs; Dunst is retired |
| Launcher and help | QE owns the primary launcher binding and curated help surface; specialized Rofi flows may coexist |
| Dashboards | Audio, Bluetooth, network, AI quota, and shared dashboard/control-center composition are implemented |
| Monitor behavior | Per-screen workspace scoping, monitor-layout controls, stepped per-monitor scale, attach/detach/reorder, and mirror restoration are implemented |
| Lock | QE owns compositor-enforced locking, manual/idle/before-sleep paths, native PAM authentication, and lock-safe presentation; Hyprlock is installed but retired |
| Operations | `qe-doctor`, stable launch/restart entry points, single-instance checks, and production recovery paths are implemented |

Completed implementation and acceptance evidence through the final replacement
phase is preserved in `docs/history/FINAL_IMPLEMENTATION_PLAN.md` and the
phase-specific history files. The pre-maintenance monolithic architecture is
preserved in `docs/history/ARCHITECTURE_PRE_MAINTENANCE.md`.

## Known limitations and supported escape hatches

These are current boundaries that can materially affect maintenance work. They
are not a requirement to load old phase records.

| Area | Current limitation / boundary | Supported handling |
| --- | --- | --- |
| NetworkManager restart | Quickshell 0.3.1 may fail to repopulate all native devices after NetworkManager restarts | Dashboard exposes guarded `Restart QE` recovery; remove only after an upstream fix and live restart validation |
| Network profile scope | Native QE management is bounded to ordinary open/personal PSK flows; wired state is inspection-only and enterprise/hidden/VPN/proxy/arbitrary profile editing remain out of scope | Keep `nm-connection-editor` available |
| Bluetooth pairing | Installed Quickshell 0.3.1 lacks the pairing-agent API needed for interactive PIN/passkey/authorization flows | Keep Blueman available for interactive pairing and advanced flows |
| Audio routing | Common levels/defaults/mute/stream controls are supported, not a full PipeWire graph editor | Keep `pavucontrol` available for advanced routing |
| Idle inhibition | QE persists and exposes requested state; compositor-active inhibition is not presented as independently confirmed state | Preserve requested-versus-confirmed semantics |
| Mirror -> extended transition | Changing an already-connected mirror to extended may not create a new Qt `QScreen` | Reconnect the output or restart QE for that transition |
| AI quota | Provider usage endpoints and OpenCode credential storage are external contracts that may change without notice | Preserve strict normalized validation, read-only credential ownership, provider-local degradation, and stale state |
| External desktop themes | QE and external desktop theme selections are intentionally independent scopes and best-effort propagation can partially fail | Preserve per-target status and never roll back a successful QE theme selection solely because external apply failed |
| Generated wallpaper artifacts | Runtime `Wallpaper` artifacts can predate a theme-schema/template refinement even when authored sources are current | Regenerate or restore generated runtime artifacts before deploying a theme-contract change; keep authored defaults and generated runtime data separate |

## Maintenance direction

The replacement roadmap is closed. Normal near-term work is expected to be
small and independently reviewable: styling, theme/token refinements, UI
polish, new or adjusted bar modules, dashboard/control refinements, and bug
fixes. Record a specific item here only when it represents an accepted ongoing
constraint, a meaningful backlog item, or a dependency that future sessions
need to know before editing. Do not turn this file into a chronological changelog.

### Deferred capabilities

These remain intentionally deferred and must not be introduced as implicit
defaults:

- final visual/animation language beyond incremental refinements;
- fingerprint authentication;
- enterprise Wi-Fi, hidden-network creation, VPN, proxy, and full profile editing;
- Bluetooth OBEX and advanced profile management;
- advanced PipeWire graph/routing editing;
- automatic external-to-QE theme synchronization;
- cross-compositor portability;
- startup self-heal for a generated `wallpaper` theme when its source image has
  changed while preserving source identity semantics;
- recovery of a wallpaper selected outside QE while QE was stopped, which still
  requires either an external source-path contract or an explicitly accepted
  derived-raster approximation.

## Live risk triggers

Use these as routing signals. They are not a requirement to read unrelated
architecture for ordinary styling work.

| Trigger | Why it matters | Required response |
| --- | --- | --- |
| Lock/PAM/session-lock lifecycle changes | Failure can affect session availability or authentication safety | Read runtime + security architecture and use disposable/recovery-aware validation |
| New or changed Quickshell native API use | Installed-version behavior can differ across upgrades | Verify installed metadata and matching official docs/source before relying on the API |
| Theme generation/promotion changes | Invalid or partial artifacts can create cross-application drift | Preserve staging/validation/atomic promotion and per-target failure reporting |
| New external command or parser | UI/system boundaries can leak and malformed output can become trusted state | Keep command/parsing logic in a reviewed adapter/helper with structured validation and timeouts |
| New or changed poller | Hidden polling can create battery/CPU cost and stale-state bugs | Update the polling registry in `docs/architecture/INTEGRATIONS.md` and define consumer lifecycle/staleness |
| Credential-bearing operation | Secrets can leak through args, logs, caches, or persistence | Read security architecture; preserve ephemeral/redacted handling |
| Singleton/subscription/reload change | Duplicate QE instances or reloads can duplicate ownership/events | Read runtime + relevant service contract and exercise reload/restart behavior |
| Filesystem/path integration | Hard-coded machine assumptions can re-enter the project | Resolve through project/XDG path contracts and validate missing/malformed paths |
| AI quota provider contract change | Upstream endpoints/auth formats are not controlled by QE | Preserve provider-local failure/backoff and reject malformed data rather than clamping/guessing |
| Monitor/workspace identity change | Native object replacement can leave per-screen presentation stale | Keep monitor mapping service-owned and verify attach/detach/reorder/mirror behavior |

## Historical records

Historical files are evidence, not current authority. Read them only to
reconstruct prior implementation/acceptance detail, rollback history, superseded
constraints, or decision provenance.

- `docs/history/FINAL_IMPLEMENTATION_PLAN.md` — final phase-era live plan snapshot.
- `docs/history/ARCHITECTURE_PRE_MAINTENANCE.md` — pre-split architecture snapshot.
- `docs/history/PHASES_00-06.md` — completed early implementation/cutover evidence.
- `docs/history/PHASES_07-11.md` — completed dashboard/control-center evidence.
- `docs/history/PHASES_12-13.md` — completed secure-lock and production-hardening evidence.
- `docs/history/INITIAL_SYSTEM_INVENTORY.md` — original environment inventory.

## Status update rule

Update this file when a change alters the production baseline, a known limitation
or escape hatch, an accepted deferred/backlog item, or a live risk trigger. Pure
implementation refactors and styling changes normally require no status update.
Architecture, ADR, validation, and user-guide updates are governed by their own
authority boundaries.
