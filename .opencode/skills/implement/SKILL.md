---
name: implement
description: "Implement settled QE work from a user request, spec, or tickets."
disable-model-invocation: true
---

# Implement

Implement the settled work described by the user, spec, or tickets. Do not require
a separate written spec when the user's request already defines the task well
enough.

1. Read `AGENTS.md` and load only the project context it routes for this task.
2. Record the current `HEAD` as the review fixed point before editing.
3. Inspect the affected implementation and external integrations before changing
   them.
4. Call the Skill tool with `tdd` where appropriate, especially for behavioural
   changes with an established test seam. Do not force TDD where the repository's
   validation strategy or the task makes it a poor fit.
5. Make the smallest change that satisfies the settled task. Keep documentation
   updates consequence-driven according to `AGENTS.md`; do not manufacture a
   separate plan merely because implementation is underway.
6. Run focused relevant tests/lint/validation regularly while working, then run
   the complete task-relevant validation required by `AGENTS.md` before review.
7. Commit the completed implementation to the current branch. Do not include
   unrelated dirty-worktree changes.
8. Call the Skill tool with `code-review`, supplying the recorded starting `HEAD`
   as its fixed point and the user's request/spec/tickets as the review's intended
   behaviour source.
9. Address valid review findings, rerun affected validation, and commit any review
   fixes. Report findings that require a new user decision rather than guessing.

Do not silently expand scope, revise accepted architecture, or change
user-visible/security/ownership decisions outside the task's approvals.
