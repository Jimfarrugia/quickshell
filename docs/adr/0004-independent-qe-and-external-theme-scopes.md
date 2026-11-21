# ADR-004: Independent QE and external theme scopes

Status: Accepted by user

Decision: QE and external applications each own their active theme. QE selection
automatically requests the same external ID after QE commits.

Context: the user intentionally permits independent themes and wants QE to
remain successful when external targets fail.

Rationale: reflects actual non-transactional application behavior and permits
external CLI use without QE dependence.

Alternatives considered: external switcher globally authoritative; QE globally
authoritative; neutral shared global state.

Consequences: visual drift is valid and must be visible in status. Values are
not synchronized bidirectionally.

Affected areas: ThemeService, external switcher, selector UI, diagnostics.

Revisit if: the user later requires globally locked theme consistency.
