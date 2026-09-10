---
name: qe-doc-maintenance
description: Maintain QE maintenance-mode documentation, route current authority, and preserve historical evidence.
compatibility: OpenCode project-local skill for the QE repository
metadata:
  project: qe
  scope: documentation-maintenance
---

# QE Documentation Maintenance

Use this procedure for information-lifecycle maintenance after completion of the
replacement roadmap. It is not permission to redesign QE or reinterpret accepted
technical decisions.

The governing principle is:

> Keep routine maintenance context small, keep current contracts precise, and
> preserve provenance outside the default reading path.

## Authority model

| Document | Owns |
| --- | --- |
| `AGENTS.md` | Small always-read operating rules and context routing |
| `docs/STATUS.md` | Current production baseline, limitations/escape hatches, maintenance direction, deferred capabilities, live risk triggers |
| `docs/ARCHITECTURE.md` | Cross-cutting architecture invariants and domain routing |
| `docs/architecture/*.md` | Detailed current architecture by domain |
| `docs/DECISIONS.md` | Accepted ADRs and rationale |
| `docs/VALIDATION.md` | Test routing, commands, expected markers, special conditions |
| `CONTEXT.md` | Durable QE terminology only |
| `docs/USER_GUIDE.md` | Stable user-facing workflows |
| `docs/history/` | Non-authoritative inventories, completed execution/acceptance records, rollback evidence, superseded working context |

If authoritative documents conflict, do not choose one during maintenance.
Report the conflict and leave the disputed technical claim unresolved unless the
current task already establishes the decision needed to resolve it.

## Preconditions

1. Read `AGENTS.md`.
2. Inspect `git status --short` and preserve unrelated changes.
3. Read `docs/STATUS.md` only when the maintenance pass concerns live status,
   limitations, backlog/deferred scope, or risks.
4. Follow `docs/ARCHITECTURE.md` routing and read only architecture domains
   implicated by the documentation change.
5. Read only relevant ADRs.
6. Inspect implementation/runtime evidence only as needed to verify a current
   claim or broken reference.
7. If invoked with a focus argument, prioritize that area rather than broadening
   the pass into an unsolicited repository-wide rewrite.

## Classify documentation impact first

| Classification | Action |
| --- | --- |
| Pure styling, local refactor, or internal implementation detail with unchanged contract | Usually no documentation change |
| Production baseline changed | Update `docs/STATUS.md` baseline concisely |
| Current limitation/escape hatch added, removed, or materially changed | Update `docs/STATUS.md` |
| Accepted backlog/deferred capability or live risk trigger changed | Update `docs/STATUS.md` |
| Ownership, boundary, service contract, lifecycle, failure, security, or durable structure changed | Update only the affected architecture domain |
| Cross-cutting invariant/routing changed | Update root `docs/ARCHITECTURE.md` and `AGENTS.md` only as needed |
| Significant architectural choice with alternatives/consequences | Add/revise an ADR; never treat housekeeping as permission to alter an accepted ADR |
| Test routing/command/expected marker changed | Update `docs/VALIDATION.md` |
| Durable domain term changed | Update `CONTEXT.md` |
| Stable user-facing workflow changed | Update `docs/USER_GUIDE.md` only when the current task includes/approves guide maintenance |
| Completed implementation chronology, acceptance transcript, rollback evidence, superseded plan | Preserve under `docs/history/`, not live status/architecture |

When uncertain whether a claim is still current, keep it or report the
uncertainty; do not archive it based on assumption.

## Maintenance procedure

### 1. Keep STATUS.md operational, not chronological

`docs/STATUS.md` should answer only:

- what is the current production baseline?
- which limitations/fallbacks materially affect new work?
- what broad maintenance/deferred direction is intentionally live?
- which risk triggers should route an agent into heavier context?

Do not add completed-task narration, implementation logs, test transcripts, or a
"recent changes" diary. If a status item is no longer current, remove it after
its unique provenance is preserved in history/ADR/architecture/implementation as
appropriate.

### 2. Keep architecture modular

Do not grow root `docs/ARCHITECTURE.md` into another monolith. Put detailed
contracts in the owning file under `docs/architecture/` and keep the root as the
cross-cutting invariant/routing map.

Before creating a new architecture file, prefer the existing domains:

- `PROJECT_MODEL.md` — repository/config/path/shared-state model;
- `SERVICES.md` — domain-service contracts;
- `THEMING.md` — theme/wallpaper/Matugen/external-theme semantics;
- `INTEGRATIONS.md` — adapter boundaries, polling, failure/degraded behavior;
- `RUNTIME.md` — processes, lifecycle, IPC/surfaces, supervision/logging;
- `SECURITY.md` — credentials, PAM/lock, sensitive operations;
- `TESTING.md` — architectural testing strategy.

Split further only when an existing domain becomes independently cumbersome and
the new boundary has a clear routing benefit.

### 3. Preserve ADR integrity

`docs/DECISIONS.md` is durable and on-demand. Never renumber, merge, delete, or
reinterpret an accepted ADR as housekeeping. Supersession/revision must be
explicit and follow `AGENTS.md`.

The historical duplicate-ID resolution remains fixed: `ADR-022` is **Project-owned
authored defaults bundle** and `ADR-028` is **QE-generated Yazi wallpaper
flavor**.

### 4. Keep validation task-oriented

Maintain `docs/VALIDATION.md` as a subsystem/change-to-test router plus command
and marker catalogue. Historical `phaseN` test filenames may remain if renaming
would be code/test churn; do not rebuild phase-oriented documentation around
them.

### 5. Keep the glossary narrow

`CONTEXT.md` contains durable QE language and conceptual distinctions only. Move
or remove status, implementation shape, transient version facts, tests, risks,
and architectural rationale from the glossary when they appear.

### 6. Preserve history before compaction

When removing unique implementation chronology, acceptance evidence, rollback
evidence, or superseded planning text from live docs, preserve it under
`docs/history/` first. Historical files are intentionally not default agent
context.

Do not duplicate material into history when Git history and an existing archived
snapshot already preserve it unless the repository's documentation needs the
evidence to remain self-contained.

## Cross-reference and integrity checks

Before finishing:

1. Search current (non-history) references to authority filenames and moved
   headings.
2. Verify every referenced file exists.
3. Check that removed unique historical evidence has an archive owner.
4. Review `git diff --check`.
5. Review the diff specifically for accidental technical/behavioral changes.
6. Confirm default routing still lets a styling-only change avoid loading status,
   ADRs, or unrelated architecture.
7. Do not edit unrelated code merely to make documentation terminology uniform.

## Completion report

Report:

- current authority/routing changes;
- historical material archived or retired;
- status/limitation/backlog items added or removed;
- architecture/ADR/validation/user-guide updates made;
- conflicts or uncertain current claims left unresolved;
- any references that still require a repository-aware decision.

If maintenance would require a substantive architectural, security, ownership,
or user-visible decision that the task does not establish, stop that part and
surface the decision instead of guessing.
