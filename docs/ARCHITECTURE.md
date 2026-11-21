# QE Architecture

Status: Production baseline complete; maintenance and refinement mode

This document is the cross-cutting architecture map for the Quickshell
Environment (QE). Detailed current contracts live under `docs/architecture/`;
accepted decisions and their rationale live in `docs/adr/`.

## Scope

QE is a cohesive desktop-shell platform for Hyprland on Arch Linux. Shared
configuration, state, themes, lifecycle, diagnostics, IPC, and failure behavior
are platform responsibilities; presentation modules are consumers of those
platform contracts rather than independent system integrations.

The completed replacement project is now a production baseline. Normal work is
maintenance: styling, UI refinement, small modules, bug fixes, and bounded
capability additions. A maintenance task does not need phase history unless it is
reconstructing provenance or rollback evidence.

## Domain documents

| Change touches | Detail |
| --- | --- |
| Installation, packages, deployment ownership, defaults seed, Dunst cutover, activation receipts | `docs/architecture/INSTALLATION.md` |
| Repository layers, configuration, paths, persistent/shared state | `docs/architecture/PROJECT_MODEL.md` |
| Domain service ownership or operation semantics | Relevant subsection of `docs/architecture/SERVICES.md` |
| Themes, wallpaper, Matugen, semantic roles, external theme apply | `docs/architecture/THEMING.md` |
| Native/DBus/IPC/file/command adapters, polling, retries, degraded state | `docs/architecture/INTEGRATIONS.md` |
| Shell/lock processes, reload/restart, transient surfaces, supervision, logging | `docs/architecture/RUNTIME.md` |
| Credentials, PAM/lock safety, sensitive rendering or operations | `docs/architecture/SECURITY.md` |

## Architectural Principles

The enforceable rules derived from these principles are in
`CODING_STANDARDS.md`.

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
