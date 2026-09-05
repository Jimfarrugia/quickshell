---
name: code-review
description: "Review QE changes along two independent axes: Standards (does the change follow repository rules and architecture?) and Intent (does it correctly satisfy the user's requested work?). Supports both uncommitted working-tree reviews and committed changes since a fixed point. No issue, ticket, or written spec is required."
---

# Code Review

Review the current change along two independent axes:

- **Standards**: does the implementation conform to the repository's documented
  rules, architecture, validation expectations, and relevant code-quality
  heuristics?
- **Intent**: does the implementation faithfully satisfy the user's requested
  work without missing behaviour, implementing it incorrectly, or expanding
  scope unnecessarily?

A written spec, ticket, or issue is optional review evidence, not a prerequisite.
Do not require or search for project-management artifacts merely to perform a
review.

Run the two axes in parallel sub-agents when the available agent/tooling supports
it so their reasoning does not contaminate each other, then aggregate the
findings without collapsing the axes into one score.

## Process

### 1. Read the repository rules and establish the review target

Read `AGENTS.md` first and follow its selective-reading routes for the affected
area. Do not load unrelated architecture, decisions, validation material, or
history merely because this skill was invoked.

Determine the review target in this order:

1. **Explicit fixed point supplied by the user or caller.** Resolve it with
   `git rev-parse`. Review committed changes with
   `git diff <fixed-point>...HEAD` and record
   `git log <fixed-point>..HEAD --oneline`.
2. **No fixed point, but staged, unstaged, or relevant untracked changes exist.**
   Review the current working tree using `git status --short`, `git diff --`, and
   `git diff --cached`. Read the contents of relevant untracked files directly;
   they are part of the review even though `git diff` does not show them.
3. **No working-tree changes and no fixed point.** Prefer the merge-base with the
   branch's configured upstream when one exists. Otherwise use the merge-base
   with an obvious repository base branch such as `main` or `master` when it can
   be resolved unambiguously. If no reliable base can be established, ask the
   user for the fixed point rather than inventing one.

When a fixed point is supplied and the working tree also contains changes,
include those working-tree changes in the review unless the user explicitly
asked to review committed history only. Keep unrelated pre-existing dirty
changes out of scope when the task boundary makes that distinction possible.

Fail early if an explicit fixed point does not resolve or if the selected scope
contains no changes.

### 2. Identify the intended behaviour

Build the Intent axis from the strongest available evidence, in this order:

1. the user's explicit request or the arguments supplied to this review;
2. the settled task description available in the current session/caller;
3. an explicitly supplied design note, spec, checklist, or other task document;
4. applicable authoritative QE documentation routed by `AGENTS.md`;
5. commit messages and the changed implementation as secondary context only.

Do not search for an issue, ticket, or spec unless the user explicitly supplied
or referenced one. Do not create one for the purpose of review.

If there is no reliable statement of intended behaviour, still run the
Standards review. For the Intent axis, report that exact acceptance/completeness
cannot be established and restrict findings to requirements supported by the
available evidence. Do not invent requirements from the diff.

### 3. Identify the standards sources

Use the repository's actual standards and authority model rather than a generic
framework. Sources may include:

- `AGENTS.md`;
- the task-relevant sections of `docs/ARCHITECTURE.md`;
- relevant accepted decisions in `docs/DECISIONS.md`;
- task-relevant validation contracts in `docs/VALIDATION.md`;
- any language- or directory-specific standards that actually apply to the
  changed files.

The repository overrides generic heuristics. Do not treat a heuristic as a hard
violation when QE's documented architecture intentionally chooses that design.
Skip style issues already enforced mechanically unless the diff shows the
mechanism was bypassed or the tool is not part of the applicable validation.

On top of repository-specific rules, use this compact smell baseline as
judgement-call prompts:

- **Mysterious Name**: a name does not reveal the concept or responsibility.
- **Duplicated Code**: substantially the same logic is introduced in multiple
  places without a justified reason.
- **Feature Envy**: behaviour primarily manipulates state owned by another
  module/object and likely belongs closer to that owner.
- **Data Clumps**: the same group of values repeatedly travels together and may
  represent one concept.
- **Primitive Obsession**: raw primitives stand in for a domain concept whose
  invariants deserve an explicit representation.
- **Repeated Switches**: the same type/status branching is duplicated across
  multiple sites.
- **Shotgun Surgery**: one logical change requires scattered edits because the
  responsibility is poorly localized.
- **Divergent Change**: one module is being changed for several unrelated
  responsibilities.
- **Speculative Generality**: abstraction or extensibility is added without a
  demonstrated need from the task or architecture.
- **Message Chains**: callers depend on a long navigation chain through objects
  they should not need to understand.
- **Middle Man**: a layer adds delegation without meaningful policy, isolation,
  normalization, or ownership value.
- **Refused Bequest**: inheritance/interface use forces implementations to ignore
  much of the inherited contract.

These are heuristics, never automatic blockers. In QE, especially preserve the
architectural meanings of component, module, domain service, integration
adapter, and external boundary defined by the project documentation.

### 4. Run the two review axes

#### Standards sub-agent

Provide:

- the exact review scope and commands from step 1;
- the relevant standards-source paths from step 3;
- the smell baseline above;
- enough task context to distinguish intentional architecture from accidental
  drift, without giving it the Intent sub-agent's conclusions.

Ask it to report, per file/hunk where relevant:

1. documented-standard or architecture violations, citing the governing source;
2. validation obligations that the change appears to miss;
3. meaningful code smells, clearly labelled as judgement calls rather than hard
   violations.

Require concrete evidence. Skip hypothetical style preferences and unrelated
pre-existing problems.

#### Intent sub-agent

Provide:

- the same review scope;
- the intended-behaviour evidence from step 2;
- any relevant authoritative QE documentation needed to interpret that intent.

Ask it to report:

1. requested behaviour that is missing or only partially implemented;
2. behaviour that appears implemented incorrectly relative to the request;
3. unrequested scope expansion introduced by the change;
4. edge/failure cases explicitly implied by the request or applicable QE
   contracts but not handled by the implementation.

Require a concrete link from every finding to the stated task or authoritative
contract. Do not manufacture acceptance criteria.

If reliable intent is unavailable, skip completeness claims and state that the
Intent axis is limited by missing task context.

### 5. Aggregate

Present the reports under:

- `## Standards`
- `## Intent`

Keep the axes separate. Lightly deduplicate wording within an axis, but do not
merge or rerank Standards findings against Intent findings.

For each finding, make clear whether it is:

- **Blocking**: correctness, contract, architecture, security, data/state, or
  explicit acceptance failure that should be fixed before the change is accepted;
- **Non-blocking**: maintainability or quality improvement that is worth
  considering but does not invalidate the requested change.

End with a compact summary containing:

- finding count by axis and severity;
- the most important issue in each axis, if any;
- whether the available evidence was sufficient to assess Intent completely.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every repository rule but implements the wrong behaviour ->
  **Standards pass, Intent fail.**
- Code that produces the requested behaviour but violates QE's architecture or
  contracts -> **Intent pass, Standards fail.**

Keeping the axes separate prevents code quality from masking requirement errors
and prevents apparent feature completeness from masking architectural problems.
