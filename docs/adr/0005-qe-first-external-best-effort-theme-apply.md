# ADR-005: QE-first, external-best-effort theme apply

Status: Accepted by user

Decision: validate/persist/publish QE first; abort on QE failure; otherwise run
the external apply and report its independent result without QE rollback.

Context: external targets cannot provide a reliable global transaction or
rollback.

Rationale: preserves responsive, truthful QE behavior and avoids making a local
theme dependent on every installed application.

Alternatives considered: rollback all possible; external apply despite QE
failure; declare success only if every target succeeds.

Consequences: partial external drift persists and requires target-level retry.

Affected areas: ThemeService, switcher contract, UI status.

Revisit if: external targets acquire transactional staging and rollback.
