# QE Agent Instructions

QE (Quickshell Environment) is a Quickshell/QML desktop shell for Hyprland on
Arch Linux, in maintenance and refinement mode. `shell.qml` is the persistent
shell; `lock.qml` is the isolated secure lock.

## Where things are

- `docs/ARCHITECTURE.md`: layers, principles, topology, and which
  `docs/architecture/*.md` file covers each domain.
- `docs/STATUS.md`: production baseline, known limitations, deferred work, and
  live risk triggers.
- `docs/VALIDATION.md`: lint/test commands, what to run for each changed area,
  and expected markers.
- `CODING_STANDARDS.md`: the rules changes are reviewed against.
- `docs/USER_GUIDE.md` is user-facing; `docs/history/` is non-authoritative
  provenance.

## Safety

- Never exercise notification-ownership, service-supervision, credential, or
  lock changes on the primary session; use the isolation/recovery procedure in
  the matching `docs/VALIDATION.md` section.
- Verify Quickshell APIs against the installed version's metadata and matching
  upstream docs/source before relying on them.
