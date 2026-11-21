# ADR-001: Layered QE platform

Status: Accepted

Decision: use presentation/modules -> domain services -> integration adapters ->
external systems as the dependency direction.

Context: QE spans many shared stateful integrations and must not become a
collection of QML views that each spawn commands.

Rationale: centralizes state ownership and lifecycle while retaining declarative
presentation and replaceable external boundaries.

Alternatives considered: monolithic QML; independent feature applications;
framework-heavy abstraction layers.

Consequences: more explicit interfaces and fixtures are required; trivial local
view state remains local to avoid unnecessary services.

Affected areas: all modules and integrations.

Revisit if: Quickshell imposes a verified lifecycle limitation that prevents a
domain service from safely owning a required object.
