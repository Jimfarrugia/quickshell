# Testing Strategy

Authoritative for QE testing layers and architectural acceptance expectations. Concrete commands and expected markers live in `docs/VALIDATION.md`.

## Testing Layers

### Static validation

- `qmllint` all QML files with installed Quickshell module metadata.
- Parse every JSON configuration, schema fixture, and theme.
- Validate every authored theme against the same runtime contract.
- Run `shellcheck` on new shell helpers.
- Search for forbidden absolute home paths and direct command execution in
  presentation directories.

### Unit and contract tests

- Pure JavaScript token resolution, validation, formatting, sorting, and state
  transformations use deterministic fixtures.
- QML services are tested with injected fake adapters where practical.
- Command helpers are tested against temporary directories and structured
  golden outputs.
- Malformed, empty, oversized, timeout, missing executable, and partial failure
  cases are first-class tests.
- State schema migration tests preserve originals and verify idempotence.

### Smoke and integration tests

- Start the development shell with `quickshell -p shell.qml` under a timeout and
  inspect stderr/logs.
- Exercise native services against the current session only in opt-in tests.
- Use non-exclusive development surfaces or a non-conflicting alternate edge
  when intentionally testing alongside a legacy bar. Verify that any
  development reservation does not alter the other bar's edge reservation.
- Test notification ownership only in an isolated test window/session using the
  current QE owner. Historical Dunst restoration evidence is archived; the
  current production state is masked/inactive Dunst with QE owning the name.
- Test lock behavior in a disposable session or nested compositor where
  protocol support permits, followed by a documented real-session checklist.

### Acceptance testing

Each module requires tests for unavailable dependencies, daemon restart,
operation timeout, stale state, multi-monitor behavior where relevant, theme
change while visible, and QE reload. Changes that transfer ownership of a live desktop boundary additionally require
a recovery or rollback exercise appropriate to that boundary.
