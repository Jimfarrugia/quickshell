# ADR-011: Native integration before commands

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
