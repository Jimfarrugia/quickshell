# QE Agent Instructions

These instructions apply to all work in this repository.

## Required Reading and Context Selection

Do not load every project document by default. Read the smallest authoritative
set that covers the requested work.

Before changing code or planning documents:

1. Read this file.
2. Read `docs/PLAN.md` sections **Project Status**, **Current handoff**, and the
   active phase. Read additional plan registries, risks, prerequisites, or
   deferred items only when the task touches them.
3. Read the relevant sections of `docs/ARCHITECTURE.md` using the routing table
   below.
4. Read only the ADRs in `docs/DECISIONS.md` that the active phase/task references
   or whose affected areas overlap a proposed architectural change.
5. Inspect the current implementation and every external integration affected by
   the task.
6. Before validation, read the relevant portion of `docs/VALIDATION.md`.
7. Verify uncertain Quickshell APIs against the installed version metadata and
   matching official documentation or source before use.

`CONTEXT.md` is glossary-only. Read it for QE domain terminology or when an
invoked skill requires it; do not treat it as status, a spec, or architecture.

`docs/USER_GUIDE.md` is not normal implementation context. Read it only when the
task changes a documented user-facing workflow or explicitly concerns the guide.

`docs/history/` is not normal implementation context and is never authoritative
for current behavior. Read historical files only when reconstructing prior
evidence, rollback history, superseded constraints, or decision provenance.

### Architecture reading routes

| Work touches | Read at minimum |
| --- | --- |
| Presentation/components/module composition | Architecture §§2.2-2.3 and 4 |
| Configuration, paths, keybindings, persistent/shared state | Architecture §§5-7 plus the relevant service subsection |
| Themes, wallpaper, Matugen, external theme application | Architecture §§7.2-7.3, 8, and 9 |
| A system integration or domain service | Relevant Architecture §7.x service contract plus §§9 and 11 |
| Shell lifecycle, reload, transient surfaces, or IPC | Architecture §§3, 10, and 11 |
| Notifications or OSDs | Architecture §§7.11-7.12, 10.2, 11, and 12 |
| Launcher/help | Architecture §7.14, §10.4, and §11 |
| Lock/authentication/security | Architecture §§3.2, 5, 6, 10-12 |
| Architectural or ownership change | All directly affected architecture sections plus relevant ADRs |

Read more when dependencies cross these boundaries, but do not expand context
merely because a document is authoritative.

### Document authority

- `CONTEXT.md` — durable QE domain vocabulary only.
- `docs/PLAN.md` — roadmap, project status, active/future phases, prerequisites,
  acceptance criteria, risks, deferred work, polling policy.
- `docs/ARCHITECTURE.md` — current system design, ownership, boundaries, service
  contracts, lifecycle, failure, and security policy.
- `docs/DECISIONS.md` — accepted architectural decisions and rationale.
- `docs/VALIDATION.md` — developer validation catalogue and expected markers.
- `docs/history/` — non-authoritative historical evidence.
- `docs/USER_GUIDE.md` — concise user-facing guidance; non-authoritative for
  project status.

Resolve conflicts between authoritative documents explicitly; do not silently
choose one.

## Scope Control

- Work only within the active phase and requested task.
- Satisfy phase prerequisites before implementing dependent feature work.
- Do not bundle unrelated refactors, visual redesigns, package changes, or
  production configuration changes.
- Do not disable or replace an existing desktop tool before its documented
  cutover criteria and rollback test pass.
- Do not implement deferred features as implicit defaults.
- Preserve user changes and unrelated dirty-worktree changes.

## Architecture Rules

- Dependency direction is modules/presentation -> domain services -> integration
  adapters -> external systems.
- Presentation QML must not construct system commands, parse command output,
  write shared state, or own external subscriptions.
- Shared long-lived state and operations belong to a domain service. View-local
  state remains local.
- Each integration adapter owns one external boundary and exposes normalized
  availability, freshness, errors, and pending/confirmed operation state.
- Use QML for reactive state and Qt object lifetime. Use JavaScript only for pure
  transformations. Use scripts only for reviewed stable external contracts.
- Prefer native Quickshell/Qt/Wayland/DBus/IPC facilities over commands.
- Never add polling without documenting the missing event source, interval,
  cost, consumer lifecycle, and stale-state behavior in the `docs/PLAN.md`
  poller registry.
- The lock process remains isolated and minimal. Never expose unlock through QE
  IPC or replace `WlSessionLock` with a fullscreen window.

## State and Integration Rules

- Assign one authoritative owner to every independently editable value.
- Distinguish confirmed live state, requested state, generated artifacts,
  caches, last-known-good values, and local UI state.
- Never present a request or cache as confirmed external state.
- Do not use `~/.local/share/theme_data` as QE's state store; it is a transitional
  external compatibility source.
- QE and external desktop themes are intentionally independent scopes. Follow
  the apply semantics in `docs/ARCHITECTURE.md`.
- Keep authored inputs separate from generated data and caches.
- Use project-relative and XDG-resolved paths. Do not hard-code `/home/jim` or
  the current repository location.
- Pass command arguments as arrays. Validate inputs and structured outputs,
  enforce timeouts, bound logs, and define exit-code semantics.
- Never log or persist PAM responses, network secrets, or other credentials.

## Implementation Workflow

- Inspect existing code and relevant live/external configuration before editing.
- Make the smallest change that satisfies the active milestone and architecture.
- If a required interface is not established, implement or obtain approval for
  that foundation before feature UI.
- Keep adapters replaceable and test them with fixtures independent of UI.
- Update `docs/PLAN.md` status when a milestone begins or completes and record
  newly discovered dependencies, risks, open questions, or deferred work.
- Update `docs/ARCHITECTURE.md` when ownership, boundaries, contracts, lifecycle,
  security, or failure policy changes.
- Add or revise an ADR in `docs/DECISIONS.md` for every significant
  architectural change.
- Update `CONTEXT.md` only for durable domain terminology; keep other facts in
  their authoritative documents.
- Keep `docs/USER_GUIDE.md` concise and user-facing. Do not add or update
  user-guide content without explicit user approval; suggestions are allowed and
  must be presented for approval first.

## Documentation Maintenance

A normal phase-status update and a full documentation-maintenance pass are
separate operations.

- When a phase begins or completes, update the live status and handoff in
  `docs/PLAN.md` as part of normal implementation work.
- When the user explicitly requests documentation maintenance, or invokes
  `/docs-maintain`, load and follow the project-local `qe-doc-maintenance` skill.
- Use that maintenance procedure to archive completed implementation detail,
  remove stale working context from the live plan, maintain cross-references,
  and keep default agent context small without destroying evidence.
- Documentation maintenance may relocate or compact historical working material;
  it must not silently change architecture, accepted decisions, security policy,
  current behavior, or unresolved requirements.
- Never renumber, merge, delete, or reinterpret an accepted ADR as housekeeping.
- Relocate historical material losslessly before compacting its live reference.

## Validation

- Run `qmllint` over all QML files after QML changes.
- Run JSON/theme/schema validation after configuration or theme changes.
- Run `shellcheck` for new or modified shell helpers.
- Run relevant unit and contract tests, then the phase-specific validation from
  `docs/PLAN.md` using commands and expected markers in `docs/VALIDATION.md`.
- Smoke-test the persistent shell with `quickshell -p shell.qml` under a timeout.
- Test missing dependencies, malformed output, timeouts, stale state, and daemon
  loss for every external integration.
- Exercise the documented rollback before declaring a replacement cutover done.
- Never test destructive service, notification-owner, or lock changes on the
  primary session without the approvals and recovery steps required by the plan.

## Uncertainty and Conflicts

- Label unverified behavior as an assumption; do not turn remembered APIs into
  implementation facts.
- Verify the currently installed Quickshell version and use its matching
  metadata/documentation/source when version-sensitive behavior matters.
- Ask for clarification when a choice changes user-visible behavior, security,
  ownership, external configuration, package state, or phase scope.
- If code, documentation, and runtime behavior disagree, stop relying on the
  disputed claim, collect evidence, and update the authoritative documents.

## Architectural Changes

Do not silently deviate from an accepted decision. To propose a change:

1. Explain the concrete problem and evidence.
2. Identify affected contracts, phases, risks, and users.
3. Present the replacement and alternatives.
4. Document consequences and migration impact.
5. Update the appropriate authoritative documents and ADR.
6. Obtain user approval when scope, behavior, security, or ownership materially
   changes.
