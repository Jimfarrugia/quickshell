# QE Architecture

Status: Production baseline complete; maintenance and refinement mode

This document is the small, always-relevant architecture map for the Quickshell
Environment (QE). It owns cross-cutting invariants and routes agents to the
minimum domain architecture needed for a change. Detailed current contracts live
under `docs/architecture/`; they are authoritative without being default reading.

`docs/STATUS.md` owns the current production baseline, known limitations, active
maintenance direction, deferred capabilities, and live risk triggers.
`docs/DECISIONS.md` owns accepted architectural decisions and rationale.
`docs/VALIDATION.md` owns concrete developer validation commands and expected
markers. Historical phase-era architecture and planning snapshots are preserved
under `docs/history/` and are non-authoritative.

## Scope

QE is a cohesive desktop-shell platform for Hyprland on Arch Linux. Shared
configuration, state, themes, lifecycle, diagnostics, IPC, and failure behavior
are platform responsibilities; presentation modules are consumers of those
platform contracts rather than independent system integrations.

The completed replacement project is now a production baseline. Normal work is
maintenance: styling, UI refinement, small modules, bug fixes, and bounded
capability additions. A maintenance task does not need phase history unless it is
reconstructing provenance or rollback evidence.

## Documentation authority and routing

Authority does not imply mandatory reading. `AGENTS.md` defines the context
routing rules and agents should expand context only when the requested change
crosses a documented boundary.

| Change touches | Authoritative detail |
| --- | --- |
| Installation, packages, deployment ownership, defaults seed, Dunst cutover, activation receipts | `docs/architecture/INSTALLATION.md` |
| Repository layers, configuration, paths, persistent/shared state | `docs/architecture/PROJECT_MODEL.md` |
| Domain service ownership or operation semantics | Relevant subsection of `docs/architecture/SERVICES.md` |
| Themes, wallpaper, Matugen, semantic roles, external theme apply | `docs/architecture/THEMING.md` |
| Native/DBus/IPC/file/command adapters, polling, retries, degraded state | `docs/architecture/INTEGRATIONS.md` |
| Shell/lock processes, reload/restart, transient surfaces, supervision, logging | `docs/architecture/RUNTIME.md` |
| Credentials, PAM/lock safety, sensitive rendering or operations | `docs/architecture/SECURITY.md` |
| Test layering or acceptance strategy | `docs/architecture/TESTING.md` |

If authoritative documents conflict, do not silently infer precedence. Treat the
claim as disputed, inspect implementation/runtime evidence, and resolve the
conflict explicitly.

## Architectural Principles

### One owner per independently editable value

A single source of truth is the one component or external subsystem authorized
to define a value. Other representations are projections, caches, pending
requests, or generated artifacts and must be labeled as such.

Two similar values may have separate owners only when they represent
intentionally separate scopes. QE's active theme and the external desktop's
active theme are intentionally independent. They are not duplicated copies of
one value.

### Dependencies point toward external systems

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

### Declarative QML first

- QML owns presentation, bindings, animations, interaction handling, Qt object
  lifetime, and long-lived reactive services.
- JavaScript modules contain pure formatting, validation, filtering, sorting,
  and transformation functions only.
- External scripts are allowed only for functionality that lacks a suitable
  native API, must run independently of QE, or performs substantial process or
  filesystem orchestration.
- Imperative QML remains small and coordinates objects rather than becoming an
  unstructured business-logic layer.

### Confirmed state is distinct from requested state

Every mutating service operation follows this model where applicable:

```text
confirmed state -> requested operation -> pending desired state
    -> external acknowledgement/update -> new confirmed state
    -> or timeout/error -> retain/reload confirmed state
```

UI may display pending intent, but it must not present intent as confirmed live
state. Native subsystem events remain authoritative after an operation.

### Degradation is local

The core process may start when optional dependencies are missing. Each adapter
reports availability and staleness. A failed Bluetooth adapter must not block
the bar, audio, launcher, or lock process. Security-critical lock failures are
handled separately and never fail open.

## Cross-cutting implementation invariants

- Dependency direction is presentation/modules -> domain services -> integration
  adapters -> external systems.
- Presentation QML must not construct system commands, parse command output,
  write shared external state, or own long-lived external subscriptions.
- Shared long-lived state and operations belong to a domain service. View-local
  presentation state remains local.
- Each external boundary is normalized by an integration adapter that exposes
  availability, freshness/error state, and requested-versus-confirmed operation
  semantics as appropriate.
- Use QML for reactive state and Qt object lifetime, JavaScript for pure
  transformations, and scripts only for reviewed stable external contracts.
- Prefer native Quickshell/Qt/Wayland/DBus/IPC facilities over commands.
- Polling is exceptional and must be registered in
  `docs/architecture/INTEGRATIONS.md` before a new poller is accepted.
- Authored inputs, generated artifacts, caches, requested state, confirmed live
  state, and last-known-good data are distinct categories and must not be
  presented as interchangeable.
- Use project-relative and XDG-resolved paths; never hard-code a user home or
  checkout location.
- The persistent shell and secure lock remain separate processes. The lock stays
  minimal, compositor-enforced, and isolated from persistent-shell services.
- Never expose unlock through QE IPC and never replace `WlSessionLock` with a
  fullscreen imitation.
- Never log or persist PAM responses, network secrets, provider credentials, or
  equivalent sensitive material.

## Current platform topology

```text
Hyprland session
  |
  +-- supervised persistent QE shell (`shell.qml`)
  |     +-- bars and transient surfaces
  |     +-- domain services
  |     `-- integration adapters
  |
  `-- isolated secure QE lock (`lock.qml`)
        +-- WlSessionLock surfaces
        `-- lock-safe PAM/theme/wallpaper/power readers
```

The persistent shell owns long-lived desktop integrations and user-facing
surfaces. The lock process is intentionally separate because authentication and
session-lock failure semantics are security-sensitive. Detailed lifecycle and
routing contracts are in `docs/architecture/RUNTIME.md`.

## Architectural change rule

A tactical implementation change does not require an ADR merely because it edits
architecture-owned code. Update architecture only when current ownership,
boundaries, contracts, lifecycle, security, failure behavior, or durable
structure changes. Add or revise an ADR only for a significant architectural
choice with meaningful alternatives and consequences. Never silently deviate
from an accepted ADR.

When such a change is required:

1. describe the concrete problem and evidence;
2. identify affected contracts, risks, and users;
3. compare the proposed replacement with meaningful alternatives;
4. update the affected architecture domain;
5. add or revise the ADR when the decision is significant;
6. update `docs/STATUS.md` only if the current baseline, limitation, backlog, or
   live risk trigger changes.
