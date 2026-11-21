# ADR-016: Use separate namespaced IPC targets for transient surfaces

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
