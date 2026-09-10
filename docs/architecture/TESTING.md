# Testing Strategy

Authoritative for QE's testing philosophy and architectural testing expectations.
Concrete commands and expected markers live in `docs/VALIDATION.md`.

## Governing principle

QE uses **risk-driven testing, not change-driven testing**. A code change does not
automatically require a new or modified automated test. Testing effort should be
proportional to the cost and plausibility of the regression being protected.

Prefer automated tests for durable observable behaviour, state transitions,
external contracts, persistence/reload behaviour, failure recovery,
security-sensitive behaviour, and regressions that are subtle or have occurred
in practice. Prefer lint plus targeted manual/visual inspection for cosmetic
presentation details unless they encode an accessibility requirement or another
documented durable contract.

Coverage percentage, test count, and one-test-per-change are not project goals.
Do not add replacement tests merely to preserve counts after low-value coverage
is removed.

## Risk levels

| Risk | Typical QE examples | Expected testing |
| --- | --- | --- |
| High | PAM/session lock, credentials, service state machines, persistent state, external adapters, retry/stale logic, restart/lifecycle, audio/brightness actions, ownership of live desktop boundaries | Strong focused automated contract/regression/failure coverage; add integration or recovery checks when the boundary warrants them |
| Medium | keyboard interaction, monitor/surface routing, complex UI state, reusable behavioural components, non-trivial module logic | Focused tests for stable observable behaviour and meaningful edge cases |
| Low | colors, token choices, borders, spacing, typography, icon tint, exact pixel geometry, visual polish, straightforward layout | `qmllint`/static validation plus targeted manual or visual inspection by default; automated tests only when the property is a documented durable contract |

Risk is determined by the behaviour being changed, not by the directory alone.
A bar module can be high-risk if it owns a subtle service interaction, while a
large QML file can still contain a low-risk cosmetic change.

## Deciding whether to add a test

Before adding automated coverage, establish all of the following:

1. The test protects a plausible regression or a durable contract rather than
   merely mirroring the current implementation.
2. The behaviour is observable through a stable public/project-established seam.
3. Equivalent coverage does not already exist at another layer.
4. The test is likely to survive an intentional internal refactor or styling
   refinement that preserves behaviour.
5. The expected maintenance cost is justified by the failure it would catch.

If these conditions are not met, do not invent a seam or abstraction solely to
make low-risk code testable.

When an existing test fails because an intentional presentation detail changed,
reassess whether that assertion still belongs in the suite. Do not mechanically
re-baseline exact colors, tokens, spacing, or geometry unless that value is itself
a durable contract.

## Presentation testing

Presentation tests should normally protect interaction and semantics, such as:

- an activation emits the intended request once;
- keyboard focus/navigation works;
- a surface opens on the correct monitor and dismisses under the intended rules;
- unavailable or pending state disables/blocks an action correctly;
- a reusable component exposes the state/interaction contract relied on by its
  consumers.

Do not normally assert exact theme-token identities, literal colors, borders,
spacing, radii, typography, or decorative icon choices. Exact geometry is
appropriate only when it protects functional placement/bounds (for example,
avoiding overlap with a reserved bar edge), not merely today's preferred size.

## Testing layers

### Static validation

- Run `qmllint` on changed/affected QML during routine work. Use the repository-
  wide lint command for cross-cutting changes or checkpoints where broader
  confidence is warranted.
- Parse changed JSON/configuration/schema/theme inputs with their owning
  validators.
- Validate authored/generated themes against the runtime schema and semantic
  invariants when theme contracts change.
- Run `shellcheck` on new or modified shell helpers.
- Search for forbidden absolute home paths or presentation-owned system command
  execution when those boundaries are affected.

### Unit and contract tests

- Pure transforms and validators use deterministic fixtures where their logic is
  non-trivial or contract-sensitive.
- Domain services are tested with fake adapters for important state transitions,
  requested-versus-confirmed state, degradation/recovery, and known regressions.
- External helpers/adapters are tested for the malformed/timeout/retry/partial
  failure cases they actually own; do not generate every generic failure case
  for every module.
- State-schema migration tests preserve originals and verify idempotence when a
  migration contract exists.

### Smoke and integration tests

- Smoke-test the persistent shell after changes that can affect startup, shared
  runtime state, or cross-surface behaviour.
- Exercise native integrations against the current session only when useful and
  safe; prefer isolated/fake contract tests during iteration.
- Notification ownership and lock/security changes require their documented
  isolation/recovery procedures rather than routine live experimentation on the
  primary session.

## TDD

TDD is a technique, not a mandatory implementation stage. Use it when the user
requests test-first development or when a high/medium-risk behavioural change or
known regression has an established stable seam and a failing test will
materially improve confidence.

Do not invoke TDD by default for styling, layout, token changes, simple
presentation refinements, mechanical refactors, or low-risk wiring. Prefer
extending an existing contract test over creating another test file when the
same seam already owns the behaviour.

## Existing-suite maintenance

Treat test maintenance as gardening rather than a coverage-preservation exercise.
When working in an area, simplify or remove assertions that merely duplicate
visual design or implementation detail, and consolidate demonstrably duplicate
coverage. Before removing behavioural coverage, identify the remaining test that
owns the same durable contract or explain why the contract no longer warrants an
automated test.

Legacy `phaseN` test filenames may remain while they still own useful contracts.
Do not retain assertions solely because they were part of historical phase
acceptance, and do not delete a legacy aggregate wholesale when it is the only
owner of meaningful service or failure behaviour.

## Acceptance

Validation is proportional to the change. A low-risk presentation refinement may
need only affected-file lint and a visual/manual check. A service, integration,
security, persistence, or lifecycle change requires the focused automated and
failure/recovery coverage appropriate to that contract. Changes that transfer
ownership of a live desktop boundary additionally require a recovery or rollback
exercise appropriate to that boundary.
