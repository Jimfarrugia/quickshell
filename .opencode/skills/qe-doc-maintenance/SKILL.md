---
name: qe-doc-maintenance
description: Maintain QE's documentation hierarchy after phase completion or when live working docs accumulate stale historical material. Use when asked to carry out documentation maintenance, archive completed phase records, prune stale PLAN handoff/status context, maintain decision and validation references, or reduce default agent context without losing evidence.
compatibility: OpenCode project-local skill for the QE repository
metadata:
  project: qe
  scope: documentation-maintenance
---

# QE Documentation Maintenance

Use this procedure for **information lifecycle maintenance**, not for redesigning
QE or changing accepted technical decisions.

The goal is to keep default agent context small while preserving the complete
project record. The governing principle is:

> Authority does not imply mandatory reading, and token optimization must not
> destroy evidence.

## Authority model

Maintain these ownership boundaries:

| Document | Owns |
| --- | --- |
| `AGENTS.md` | Small always-read operating rules and context-routing rules |
| `docs/PLAN.md` | Live roadmap/status, current handoff, active/future phase scope, prerequisites, acceptance criteria, unresolved/deferred work, risks, migration/polling registries |
| `docs/ARCHITECTURE.md` | Durable current architecture, ownership, boundaries, contracts, lifecycle, failure, security |
| `docs/DECISIONS.md` | Accepted ADRs and their rationale |
| `docs/VALIDATION.md` | Developer validation commands, expected markers, special test conditions |
| `docs/history/` | Non-authoritative historical inventory, completed execution records, rollback evidence, superseded working context |
| `docs/USER_GUIDE.md` | Concise user-facing workflows; non-authoritative for project status |

If two authoritative documents conflict, do not choose one during maintenance.
Report the conflict and leave the disputed technical claim unresolved unless the
user has explicitly authorized the decision needed to resolve it.

## Preconditions

1. Read `AGENTS.md`.
2. Read the current `docs/PLAN.md` status/handoff and the phase or area involved.
3. Inspect `git status --short` and preserve unrelated user/dirty-worktree changes.
4. Inspect the implementation only as needed to determine whether a status claim,
   phase completion, or cross-reference is still true.
5. Read only relevant architecture sections and ADRs; do not load all reference
   documents merely because this is documentation work.
6. If maintenance was invoked with a focus argument, treat it as the priority but
   still check adjacent stale handoff/cross-reference material.

Do not treat the existence of `/docs-maintain` as permission to change
architecture, user-visible behavior, security policy, external configuration, or
accepted decisions.

## Classify before moving

Classify candidate material before editing:

| Classification | Action |
| --- | --- |
| Active requirement or current phase prerequisite | Keep in live `PLAN.md` |
| Future-phase dependency | Keep in live `PLAN.md` |
| Unresolved question or deferred decision | Keep in live `PLAN.md` |
| Active/current risk or poller contract | Keep in live `PLAN.md` |
| Durable current architecture or service contract | Keep/update `ARCHITECTURE.md` only when the architecture actually changed |
| Accepted ADR | Keep in `DECISIONS.md`; never archive merely because it is old |
| Completed phase implementation detail | Move losslessly to `docs/history/` |
| Completed acceptance/rollback evidence | Move with its completed phase record |
| Historical environment inventory | Keep under `docs/history/`, not live `PLAN.md` |
| Resolved assumption/open question | Remove from live context only after evidence of resolution; preserve useful provenance in history |
| Superseded handoff detail | Remove from live handoff after unique evidence is preserved elsewhere |
| Duplicate non-authoritative explanation | Keep one authoritative owner and replace other live copies with a concise reference when useful |
| User-facing workflow | Update `USER_GUIDE.md` only with explicit user approval |

When uncertain whether something is still active, keep it live and report the
uncertainty rather than archiving it.

## Phase-completion maintenance

When a phase has completed, use this order.

### 1. Verify completion state

Confirm that the live plan marks the phase complete and that its required
acceptance/rollback evidence is present in the repository documentation or
implementation record.

Do not independently declare a phase complete merely because maintenance was
requested. If status and evidence disagree, report the discrepancy.

### 2. Relocate historical detail losslessly

Before shortening the live plan, copy the complete detailed phase section into
the appropriate historical phase file.

Current archive grouping:

- Phases 0-6: `docs/history/PHASES_00-06.md`
- Phases 7-11: `docs/history/PHASES_07-11.md` when the first of those phases is
  archived
- Phase 12: `docs/history/PHASE_12.md` if a final detailed history file is useful

For a new historical file, add a short header explaining that it is
non-authoritative, then preserve the moved phase body without summarizing away
implementation, validation, rollback, prerequisite, or decision evidence.

**Relocate first; compact second.**

### 3. Compact the live phase record

Replace the detailed completed phase section in `docs/PLAN.md` with a concise
completion record containing only what future work routinely needs:

- phase number/name;
- completion status/date when recorded;
- short outcome;
- durable resulting constraint only if it is not already owned by architecture
  or an ADR;
- link to the historical record.

Do not copy detailed test logs or implementation chronology back into the live
plan.

### 4. Prune the current handoff

The handoff should describe what the **next session** needs, not narrate every
completed phase.

Remove completed-phase implementation detail when it is already owned by:

- the historical phase record;
- current architecture;
- an ADR;
- validation documentation; or
- the implementation itself.

Keep only current runtime facts, unusual limitations, active approvals/gates,
and information that materially changes the next phase.

### 5. Retire stale planning context

Review:

- assumptions;
- open questions;
- deferred decisions;
- migration/coexistence rows;
- risk entries;
- old inventory references;
- phase-specific approvals/gates.

Only retire an item when the current source material supports that it is
resolved, completed, or no longer applicable.

Historical facts that explain an earlier phase may move to its history record.
Durable current constraints belong in architecture or decisions rather than
being duplicated as historical prose in the live plan.

### 6. Maintain ADR references

`docs/DECISIONS.md` is durable and on-demand. Do not move accepted ADRs into
history when their implementation phase completes.

- New significant architectural decisions go into `docs/DECISIONS.md`.
- Supersession or revision must be explicit and follow the planning-change
  procedure.
- Never renumber an accepted ADR as cleanup.
- The source plan contained two records numbered `ADR-022`. The approved
  resolution retains `ADR-022` for **Project-owned authored defaults bundle** and
  assigns `ADR-028` to **QE-generated Yazi wallpaper flavor**. Preserve that
  mapping when consulting historical source material.

### 7. Maintain architecture narrowly

Do not rewrite `docs/ARCHITECTURE.md` merely to mirror phase history.

Update it only when current ownership, boundaries, contracts, lifecycle,
security, failure behavior, or durable structure changed.

Prefer concise cross-references to ADRs over duplicating full rationale.

### 8. Maintain validation routing

Keep `docs/VALIDATION.md` as the command/expected-marker catalogue.

When a phase adds tests:

- add the relevant commands and expected markers;
- group or label them so agents can find the subsystem without reading unrelated
  validation prose;
- keep phase acceptance criteria in `PLAN.md`, not duplicated as a full test
  transcript.

### 9. Protect the user guide

Do not edit `docs/USER_GUIDE.md` unless the user's current instruction explicitly
approves user-guide changes.

Without approval:

- identify stale user-facing content;
- report the suggested change;
- leave the file unchanged.

Even with approval, do not use the guide as a live project-status tracker.
Prefer stable user workflows and refer readers to `docs/PLAN.md` for current
implementation status.

## General maintenance pass

When invoked without a phase-completion focus:

1. Review `PLAN.md` for completed implementation detail that belongs in history.
2. Review the current handoff for stale chronology.
3. Check assumptions/open questions for items demonstrably resolved by completed
   work.
4. Check whether live plan content duplicates architecture or ADR rationale.
5. Check `ARCHITECTURE.md`, `DECISIONS.md`, and `VALIDATION.md` for broken
   references caused by prior moves.
6. Check `AGENTS.md` routing rules against the actual document structure.
7. Do not restructure merely to meet a target line count.

The objective is a high signal-to-context ratio, not minimum document size.

## Cross-reference and integrity checks

Before finishing:

1. Search repository references to moved documents/headings/ADRs, for example:
   - `rg -n 'docs/PLAN\.md|docs/ARCHITECTURE\.md|docs/DECISIONS\.md|docs/VALIDATION\.md|docs/history' .`
   - `rg -n 'ADR-[0-9]+' .`
2. Verify links and referenced filenames exist.
3. Verify removed historical phase text is present in its history destination
   before accepting the compaction.
4. Review `git diff --check`.
5. Review the documentation diff for accidental technical changes, not just
   Markdown correctness.
6. Do not modify unrelated files just to make references stylistically uniform.

## Completion report

Report:

- what was archived and where;
- what remained live and why;
- any resolved items removed from working context;
- any authoritative conflicts or ambiguous ADR references found;
- any user-guide updates that were suggested but not applied;
- repository references that still need a repo-aware decision.

If maintenance would require a substantive architectural, security, ownership,
or user-visible decision, stop that part of the maintenance and surface the
decision instead of guessing.
