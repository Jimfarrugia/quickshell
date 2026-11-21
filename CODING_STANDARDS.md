# QE Coding Standards

Rules changes are reviewed against. Rationale lives in `docs/ARCHITECTURE.md`,
the domain docs under `docs/architecture/`, and `docs/adr/`.

## Architecture

- Dependencies point one way: entry points/modules -> reusable components ->
  domain services -> integration adapters -> Quickshell/Qt APIs, files, IPC,
  commands, external systems.
- Presentation QML never constructs system commands, parses command output,
  writes shared external state, or owns long-lived external subscriptions.
- Shared long-lived state and operations belong to a domain service; view-local
  presentation state stays local. Services contain no layout or window
  behavior; adapters decide no presentation policy.
- Each external boundary has exactly one integration adapter, which exposes
  availability, freshness/error state, and requested-versus-confirmed semantics.
- One owner per independently editable value. Every other representation is a
  labeled projection, cache, pending request, or generated artifact.
- Authored inputs, generated artifacts, caches, requested state, confirmed live
  state, and last-known-good data stay distinct. UI may show pending intent but
  never presents a request or cache as confirmed state.
- Degradation is local: a missing optional dependency must not block unrelated
  surfaces. Lock failures never fail open.
- Prefer native Quickshell/Qt/Wayland/DBus/IPC facilities over commands
  (ADR-011).
- QML owns reactive state and object lifetime; JavaScript modules hold pure
  transforms only; scripts only for reviewed, stable external contracts.
  Imperative QML stays small and coordinates objects.
- Polling is exceptional. A new or changed poller is registered in the polling
  registry in `docs/architecture/INTEGRATIONS.md` with event-source rationale,
  interval, consumer lifecycle, cost control, and stale behavior.

## Commands, files, and paths

- Pass command arguments structurally; validate inputs and outputs; enforce
  timeouts; bound logs; define exit-code semantics.
- Use project-relative and XDG-resolved paths. Never hard-code a user home or
  checkout location.
- New or modified shell helpers pass `shellcheck`.

## Security

- Never log or persist PAM responses, network secrets, provider credentials, or
  equivalent sensitive material.
- The persistent shell and secure lock stay separate processes. The lock stays
  minimal, compositor-enforced, and isolated from persistent-shell services.
- Never expose unlock through QE IPC and never replace `WlSessionLock` with a
  fullscreen imitation.

## Tests

- Test durable observable behavior through stable seams: state transitions,
  external contracts, persistence/reload, failure recovery, security, and
  regressions that are subtle or have happened before.
- Do not test colors, theme-token identities, borders, spacing, radii,
  typography, decorative icons, or exact geometry, unless the geometry protects
  functional placement or the property is a documented contract. Do not invent
  seams or abstractions to make low-risk presentation code testable.
- When a test fails because an intentional presentation detail changed,
  reconsider the assertion instead of re-baselining it.
- One test owner per durable contract: extend the existing contract test rather
  than adding a parallel one. Removing behavioral coverage names the test that
  still owns the contract. Coverage percentage and test count are not goals.
- Adapter/helper tests cover the malformed/timeout/retry/stale cases that
  boundary actually owns, not every generic failure.

## Scope and documentation

- Make the smallest change that satisfies the request. Do not bundle unrelated
  refactors, redesigns, package changes, or production-config changes.
- A change to ownership, boundaries, service contracts, lifecycle, failure, or
  security behavior updates the affected `docs/architecture/*.md`. A change to
  the production baseline, a known limitation/escape hatch, deferred work, or a
  live risk trigger updates `docs/STATUS.md`. A changed test command or expected
  marker updates `docs/VALIDATION.md`. Styling and behavior-preserving refactors
  need no documentation change.
- A change that contradicts an accepted ADR says so explicitly and revises or
  supersedes that ADR.
