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
4. Decide whether new automated coverage is warranted using QE's risk-based
   testing strategy before invoking `tdd`. Use `tdd` when the user requests
   test-first work or when a non-trivial behavioural regression/high-risk
   contract has an established stable seam and a failing test materially improves
   confidence. Do not invoke it by default for styling, layout, token changes,
   simple presentation refinements, mechanical refactors, or low-risk wiring.
   Prefer extending an existing contract test over creating a new test file when
   the same seam already owns the behavior.
5. Make the smallest change that satisfies the settled task. Keep documentation
   updates consequence-driven according to `AGENTS.md`; do not manufacture a
   separate plan merely because implementation is underway.
6. Run proportionate focused lint/tests/validation while working, then complete
   the task-relevant validation required by `AGENTS.md`. Do not create or run a
   broad regression suite merely because implementation occurred.
7. Commit the completed implementation to the current branch. Do not include
   unrelated dirty-worktree changes.
8. Call the Skill tool with `code-review`, supplying the recorded starting `HEAD`
   as its fixed point and the user's request/spec/tickets as the review's intended
   behaviour source.
9. Address valid review findings, rerun affected validation, and commit any review
   fixes. Report findings that require a new user decision rather than guessing.

Do not silently expand scope, revise accepted architecture, or change
user-visible/security/ownership decisions outside the task's approvals.
