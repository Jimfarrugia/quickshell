# QE ADR Format

QE stores all architectural decisions in the single authoritative
`docs/DECISIONS.md` file. Do not create `docs/adr/` or individual ADR files.

## Numbering

Scan `docs/DECISIONS.md` for the highest existing `ADR-NNN` identifier and use
the next number. Never fill an old gap, reuse an identifier, or renumber an
accepted ADR as cleanup.

Add the decision to the **Decision Index** and add its full entry to the log.

## Compact template

```md
## ADR-NNN: Short decision title

Status: Accepted by user on YYYY-MM-DD

Decision: What was chosen.

Context: Why a durable decision was needed and what alternatives/trade-off made
it non-obvious.

Consequences: Important downstream effects, constraints, or follow-up.
```

Use only the sections that add real value. Existing QE ADRs may also contain
`Rationale`, `Alternatives considered`, `Affected areas`, `Related decisions`,
or `Revisit if` when those details materially preserve decision context.

## When to offer an ADR

All three must be true:

1. **Hard to reverse**: changing the choice later has meaningful cost.
2. **Surprising without context**: a future reader could reasonably question why
   QE is designed this way.
3. **A real trade-off**: meaningful alternatives existed and one was chosen for
   specific reasons.

Do not use ADRs for implementation chronology, routine refactors, phase status,
or facts already obvious from the current architecture.
