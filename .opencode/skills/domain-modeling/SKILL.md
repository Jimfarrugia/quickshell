---
name: domain-modeling
description: Maintain QE domain vocabulary and architectural decisions.
---

# Domain Modeling

Actively build and sharpen the project's domain model as you design. This is the
*active* discipline: challenge terms, probe edge cases, and write durable
vocabulary or decisions down when they crystallize. Merely reading `CONTEXT.md`
for vocabulary is not this skill.

## QE document ownership

QE is a single-context repository with two distinct durable stores:

```text
/
├── CONTEXT.md          # domain glossary only
└── docs/
    └── DECISIONS.md    # authoritative architectural decision log
```

Do not create `docs/adr/`, per-context ADR directories, or another decision log.
`AGENTS.md` defines the repository's document authority and always takes
precedence over generic skill conventions.

Create `CONTEXT.md` lazily only if it does not exist and a durable term needs to
be recorded. `docs/DECISIONS.md` already exists; add to it only when an ADR is
warranted and the decision has actually been accepted.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in
`CONTEXT.md`, call it out immediately. Distinguish a genuine terminology change
from a one-off conversational synonym.

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term.
Prefer terminology already established by `CONTEXT.md` and
`docs/ARCHITECTURE.md`.

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific
scenarios that probe edge cases and force precision about concept boundaries.

### Cross-reference with code and authoritative docs

When the user states how something works, check whether the implementation and
relevant authoritative documentation agree. If they conflict, surface the
disagreement rather than silently rewriting the glossary or an ADR.

### Update CONTEXT.md inline

When a durable term is resolved, update `CONTEXT.md` at that point rather than
batching glossary work. Use the format in
[CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

`CONTEXT.md` is a glossary and nothing else. Keep it free of:

- project or phase status;
- implementation steps or file-level design;
- version-specific facts unless they define a durable domain term;
- test procedures or acceptance criteria;
- architectural rationale already owned by `docs/DECISIONS.md`;
- current limitations that belong in `docs/PLAN.md` or `docs/ARCHITECTURE.md`.

### Offer ADRs sparingly

Only offer an ADR when all three are true:

1. **Hard to reverse**: changing the choice later would have meaningful cost.
2. **Surprising without context**: a future maintainer could reasonably wonder
   why QE is designed this way.
3. **A real trade-off**: meaningful alternatives existed and one was chosen for
   specific reasons.

If any condition is missing, skip the ADR. For a qualifying accepted decision,
append the next available `ADR-NNN` entry to `docs/DECISIONS.md` and update its
decision index using [ADR-FORMAT.md](./ADR-FORMAT.md). Do not mark a proposal as
accepted, renumber an existing ADR, or revise an accepted decision without the
approval/process required by `AGENTS.md`.
