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
