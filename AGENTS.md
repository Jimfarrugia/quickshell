# QE Agent Instructions

QE (Quickshell Environment) is a Quickshell/QML desktop shell for Hyprland on
Arch Linux, in maintenance and refinement mode. `shell.qml` is the persistent
shell; `lock.qml` is the isolated secure lock.

## Where things are

- `docs/ARCHITECTURE.md`: layers, principles, topology, and which
  `docs/architecture/*.md` file covers each domain.
- `docs/STATUS.md`: production baseline, known limitations, deferred work, and
  live risk triggers.
- `tests/qe-check`: `lint [paths]`, `unit`, `test <path>`, `all` (headless
  suite). `docs/VALIDATION.md` says what to run for each changed area.
- `CODING_STANDARDS.md`: the rules changes are reviewed against.
- `docs/USER_GUIDE.md` is user-facing; `docs/history/` is non-authoritative
  provenance.

## Safety

- Never exercise notification-ownership, service-supervision, credential, or
  lock changes on the primary session; use the isolation/recovery procedure in
  the matching `docs/VALIDATION.md` section.
- Run tests only through `tests/qe-check`: a bare `quickshell -p` test run
  writes live QE state. `tests/qe-check live` starts shells in the current
  session; use it only when those boundaries changed.
- Verify Quickshell APIs against the installed version's metadata and matching
  upstream docs/source before relying on them.

## Agent skills

### Issue tracker

GitHub Issues on `Jimfarrugia/quickshell`, via the `gh` CLI. See
`docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`,
`ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` and `docs/adr/` at the repo root. See
`docs/agents/domain.md`.
