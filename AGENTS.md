# QE Agent Instructions

These instructions apply to all work in this repository. QE is in maintenance
and refinement mode; completed implementation phases are historical context, not
the default workflow.

## Context routing

Read the smallest authoritative set that covers the requested change.

1. Read this file.
2. Inspect the affected implementation and current `git status --short`.
3. Read `docs/STATUS.md` only when the task depends on the current production
   baseline, a known limitation/escape hatch, backlog/deferred scope, or a live
   risk trigger. Do not load it for a purely local styling change.
4. Read `docs/ARCHITECTURE.md` for cross-cutting invariants when the change is
   more than presentation-local, then follow only the relevant domain route.
5. Read only ADRs in `docs/DECISIONS.md` that are explicitly referenced by the
   affected code/docs or whose affected area overlaps a proposed architectural
   change.
6. Before testing, read the relevant routing row/subsection in
   `docs/VALIDATION.md`.
7. Verify uncertain/version-sensitive Quickshell APIs against the installed
   version metadata and matching official documentation/source before use.

`CONTEXT.md` is glossary-only. Read it when QE domain terminology is unclear or
an invoked skill requires it. `docs/USER_GUIDE.md` is user-facing and is not
normal implementation context. `docs/history/` is non-authoritative and should
be read only for provenance, rollback history, superseded constraints, or old
acceptance evidence.

### Change routes

| Change type | Normal context |
| --- | --- |
| Styling, spacing, typography, local presentation state | `AGENTS.md` + affected QML/component + targeted validation |
| Existing bar/module/dashboard UI refinement | Above + relevant service contract only if service-owned state/operations are touched |
| New bar module or small surface | `docs/ARCHITECTURE.md` + relevant service contract + project model as needed |
| Theme/token/wallpaper/Matugen work | `docs/ARCHITECTURE.md` + `docs/architecture/THEMING.md` + relevant integration section |
| Service/domain-state change | `docs/ARCHITECTURE.md` + relevant `docs/architecture/SERVICES.md` subsection |
| Native/DBus/IPC/file/command adapter or poller | Relevant service + `docs/architecture/INTEGRATIONS.md` |
| Config/path/persistent-state ownership | `docs/architecture/PROJECT_MODEL.md` + relevant service |
| Reload/restart/supervision/transient-surface routing | `docs/architecture/RUNTIME.md` + relevant service/integration |
| Lock/PAM/credentials/security-sensitive work | `docs/architecture/SECURITY.md` + `docs/architecture/RUNTIME.md` + affected contract |
| Architectural ownership/boundary change | All directly affected domain docs + relevant ADRs + `docs/STATUS.md` if the live baseline/risk changes |

Expand context when dependencies cross these boundaries; do not expand it merely
because a document is authoritative.

## Authority

- `docs/STATUS.md` — current production baseline, limitations/escape hatches,
  maintenance direction, deferred capabilities, and live risk triggers.
- `docs/ARCHITECTURE.md` — compact cross-cutting architecture and routing map.
- `docs/architecture/*.md` — detailed current architecture by domain.
- `docs/DECISIONS.md` — accepted architectural decisions and rationale.
- `docs/VALIDATION.md` — validation routing, commands, and expected markers.
- `CONTEXT.md` — durable QE vocabulary only.
- `docs/USER_GUIDE.md` — stable user-facing guidance.
- `docs/history/` — non-authoritative historical evidence.

Resolve conflicts between authoritative documents explicitly; never silently
choose one.

## Core implementation rules

- Make the smallest change that satisfies the requested behavior. Do not bundle
  unrelated refactors, redesigns, package changes, or production-config changes.
- Preserve unrelated user/dirty-worktree changes.
- Dependency direction is presentation/modules -> domain services -> integration
  adapters -> external systems.
- Presentation QML must not construct system commands, parse command output,
  write shared external state, or own long-lived external subscriptions.
- Shared long-lived state/operations belong to a domain service; view-local
  state remains local.
- Each integration adapter owns one external boundary and normalizes
  availability, freshness/errors, and requested-versus-confirmed state.
- Prefer native Quickshell/Qt/Wayland/DBus/IPC facilities over commands. Use
  QML for reactive ownership, JavaScript for pure transforms, and scripts only
  for reviewed stable external contracts.
- Never add or change polling without updating the registry in
  `docs/architecture/INTEGRATIONS.md` with event-source rationale, interval,
  consumer lifecycle, cost control, and stale behavior.
- Keep authored inputs separate from generated data/caches and never present a
  request/cache as confirmed external state.
- Use project-relative/XDG-resolved paths; never hard-code `/home/jim` or the
  current checkout path.
- Pass command arguments structurally, validate inputs/outputs, enforce timeouts,
  bound logs, and define exit-code semantics.
- Never log or persist PAM responses, network secrets, provider credentials, or
  equivalent sensitive data.
- The lock process remains isolated/minimal; never expose unlock through QE IPC
  or substitute a fullscreen window for `WlSessionLock`.

## Documentation impact

Do not update documentation merely because code changed. Classify the impact:

| Change | Documentation expectation |
| --- | --- |
| Pure styling/local implementation/refactor with unchanged contracts | Usually none |
| Production baseline, known limitation, fallback, accepted backlog/deferred item, or live risk changed | Update `docs/STATUS.md` |
| Ownership, boundary, service contract, lifecycle, failure, security, or durable structure changed | Update the affected architecture domain |
| Significant architectural choice with meaningful alternatives/consequences | Add/revise an ADR in `docs/DECISIONS.md` |
| Test command/routing/expected marker changed | Update `docs/VALIDATION.md` |
| Durable domain vocabulary changed | Update `CONTEXT.md` |
| Stable user-facing workflow changed | Update `docs/USER_GUIDE.md` when the task includes/approves guide maintenance |

When the user explicitly invokes `/docs-maintain`, load the project-local
`qe-doc-maintenance` skill. Documentation maintenance may relocate or compact
history but must not silently change current architecture, accepted decisions,
security policy, or behavior.

## Validation

- Use `docs/VALIDATION.md` to select subsystem-specific tests rather than running
  historical phase checklists by default.
- Run `qmllint` over affected QML and the repository-wide lint set after QML
  changes when practical.
- Run JSON/theme/schema validation after configuration/theme changes.
- Run `shellcheck` for new or modified shell helpers.
- Run relevant unit/contract tests before broader smoke/integration checks.
- Smoke-test the persistent shell after changes that can affect shell startup or
  shared runtime behavior.
- For external integrations, test unavailable dependencies, malformed output,
  timeout/retry/stale behavior, and daemon loss when those paths are affected.
- Never test destructive notification-owner, service-supervision, credential, or
  lock changes on the primary session without the recovery/safety procedure in
  the relevant architecture/validation documentation.

## Uncertainty and architectural changes

Label unverified behavior as an assumption. If code, docs, and runtime behavior
disagree, stop relying on the disputed claim and collect evidence.

Do not silently deviate from an accepted ADR. For a substantive architecture,
security, ownership, external-behavior, or user-visible contract change: explain
the evidence and alternatives, update the affected authority, and obtain user
clarification when the choice is not already established by the task.
