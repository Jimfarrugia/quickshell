# QE Agent Instructions

These instructions apply to all work in this repository.

## Required Reading Order

Before changing code or planning documents:

1. Read this file.
2. Read `docs/ARCHITECTURE.md` for authoritative boundaries, ownership, state,
   integration, lifecycle, failure, and security rules.
3. Read `docs/PLAN.md` for authoritative project status, phase scope, prerequisites,
   acceptance criteria, risks, and accepted decisions.
4. Inspect the current implementation and every external integration affected by
   the task.
5. Verify uncertain Quickshell APIs against installed version metadata, the
   matching official documentation, or source before use.

`docs/PLAN.md` is authoritative for roadmap and status. `docs/ARCHITECTURE.md` is
authoritative for system design. Resolve conflicts explicitly; do not silently
choose one document.

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
  cost, consumer lifecycle, and stale-state behavior in `docs/PLAN.md`.
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
- Update `docs/PLAN.md` status when a milestone begins or completes and record newly
  discovered dependencies, risks, or deferred work.
- Update `docs/ARCHITECTURE.md` when ownership, boundaries, contracts, lifecycle,
  security, or failure policy changes.
- Add or revise an ADR in `docs/PLAN.md` for every significant architectural change.
- Keep `docs/USER_GUIDE.md` concise and user-facing. Do not add or update user-guide
  content without explicit user approval; suggestions for additions or updates are
  allowed and must be presented for approval first.

## Validation

- Run `qmllint` over all QML files after QML changes.
- Run JSON/theme/schema validation after configuration or theme changes.
- Run `shellcheck` for new or modified shell helpers.
- Run relevant unit and contract tests, then the phase-specific validation from
  `docs/PLAN.md`.
- Smoke-test the persistent shell with `quickshell -p shell.qml` under a timeout.
- Test missing dependencies, malformed output, timeouts, stale state, and daemon
  loss for every external integration.
- Exercise the documented rollback before declaring a replacement cutover done.
- Never test destructive service, notification-owner, or lock changes on the
  primary session without the approvals and recovery steps required by the plan.

## Uncertainty and Conflicts

- Label unverified behavior as an assumption; do not turn remembered APIs into
  implementation facts.
- Prefer installed Quickshell 0.3.0 metadata and matching official docs over the
  local 0.3.1 reference when they differ.
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
