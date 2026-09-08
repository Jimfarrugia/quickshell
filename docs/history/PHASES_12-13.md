# QE Completed Phase History: Phases 12-13

Status: Historical reference; non-authoritative for current QE behavior

This file preserves completed implementation, acceptance, rollback, and handoff
records that previously lived in `docs/PLAN.md`. Phase 12 is archived below;
future completed Phase 13 material should be appended losslessly when that phase
finishes.

For current work, read `AGENTS.md` and the relevant live sections of
`docs/PLAN.md`, `docs/ARCHITECTURE.md`, and `docs/DECISIONS.md`. Consult this
file only when earlier implementation evidence or rollback history is relevant.

## Archived Phase 12: Secure lock replacement

Status: Complete (2026-09-07). Foundation, disposable security acceptance,
production cutover, manual/idle/before-sleep behavior, and rollback passed.

Objective: replace Hyprlock with an isolated, compositor-enforced QE lock after
security and recovery behavior are validated.

Prerequisites:

- stable lock-safe theme/config readers
- verified installed `WlSessionLock` and PAM behavior
- approved test environment and emergency TTY recovery procedure
- chosen PAM service

Foundation record:

- Installed Quickshell 0.3.1 metadata and matching source verify native
  `WlSessionLock`, per-screen `WlSessionLockSurface`, compositor `secure`, and
  `PamContext` behavior.
- ADR-041 selects the existing `/etc/pam.d/login` service. The current
  `/etc/pam.d/hyprlock` delegates its authentication stack to `login`, so this
  introduces no new PAM file and does not retain Hyprlock as a PAM dependency.
- `LockThemeReader` validates configuration, active-theme state, and theme data,
  rejects oversized input, falls back to an opaque-black lock palette, and
  releases its discovery model before lock acquisition. It does not watch files
  after initialization.
- `LockController` is tested through fake session-lock and authenticator seams.
  Acquisition requires ready lock-safe inputs, authentication cannot begin
  before `secure`, and only a successful PAM result after `secure` requests
  unlock. Empty, failed, cancelled, stale, and out-of-state results remain
  locked; acquisition and authentication failures are bounded. Each PAM attempt
  has a five-minute deadline before entering the existing bounded retry/recovery
  path.
- `lock.qml` has no IPC and imports neither persistent-shell services nor
  process/command integrations. Its only optional live read is the lock-local,
  event-driven native UPower display-device view. The production manual and Hypridle lock commands now
  use the stable `qe-lock` launcher; Hyprlock remains installed only as a
  retired legacy package.
- The first disposable Hyprland launch on 2026-09-07 exposed a QML name-shadowing
  error in the lock-surface controller binding before the session became locked.
  The entry point now uses the unambiguous `lockController` ID and a static
  wiring regression test. A repeated direct-terminal launch acquired the lock;
  wrong, empty, and correct passwords behaved as expected through the selected
  `login` PAM stack, and suspend/resume and monitor changes remained locked and
  usable. No PAM response value appeared in the captured output.
- The live test found that long password text rendered outside its field. The
  input now clips its rendering and the source contract covers that property;
  visual confirmation passed on 2026-09-07 in the disposable direct terminal.
  A launch from an existing tmux server did
  not target the disposable compositor because tmux retained the original
  `WAYLAND_DISPLAY` and `HYPRLAND_INSTANCE_SIGNATURE`; direct terminals are the
  required test path until compositor-aware tmux environment handling is scoped.
- Post-secure crash recovery passed in the disposable session on 2026-09-07:
  killing the main lock process left the compositor lock displayed and
  non-interactive, with no fullscreen fallback; terminating the affected
  graphical session from a separate TTY restored its login prompt.
- Hot-plug and multi-output acceptance passed in the disposable session on
  2026-09-07. The lock covered all active outputs at startup, appeared on a
  newly connected output while locked, and remained on the original output
  after disconnect; authentication then released the lock normally.
- The first PAM-helper loss test on 2026-09-07 remained securely locked but
  exposed an unusable prompt: the adapter normalized helper loss while the
  controller accepted failures only after response submission. The controller
  now accepts a failed current attempt during prompt acquisition/input and
  retains the stricter submitted-response gate for success. A repeat confirmed
  that Quickshell logged the helper failure and created a replacement PAM
  session, but keyboard focus returned only after pointer movement. The input now
  explicitly reacquires active focus when the retry enables it. Automated
  helper-loss and focus-source contracts pass. Disposable confirmation then
  passed: keyboard input worked without pointer movement after helper replacement.
  Display repaint still waited for pointer movement after returning from the
  alternate TTY, matching compositor-wide VT-switch behavior outside the lock.
- The first staged Hypridle launch was rejected as evidence because it inherited
  primary login session `c1` and collided with the production Hypridle's shared
  user-bus `ScreenSaver` owner. A second private-bus launch proved Hypridle still
  derives login membership as `c1` despite an overridden `XDG_SESSION_ID`.
  Disposable idle validation therefore invokes the QE lock command directly;
  logind/before-sleep behavior remains a controlled cutover-and-rollback gate.
  No production Hypridle configuration was changed.
- `scripts/run-qe-lock.sh` now provides a project-relative, single-instance lock
  command, and `tests/fixtures/lock/hypridle.conf` stages direct idle invocation
  with a 15-second timeout. Staged idle passed before production cutover.
- Staged direct idle invocation passed in the disposable session on 2026-09-07:
  Hypridle fired its 15-second rule, launched `run-qe-lock.sh`, observed Wayland
  lock, and observed normal unlock after successful PAM authentication.
  Private-bus portal warnings were confined to the fixture.
- Production cutover then installed `~/.local/bin/qe-lock`, changed
  `config/programs.lua` and `hypridle.conf` to use it, reloaded Hyprland with no
  config errors, and restarted the compositor-owned Hypridle successfully.
  `Super+Backspace` then launched the QE lock on the primary session and normal
  PAM authentication released it. With QE idle inhibition temporarily disabled,
  the production five-minute Hypridle timeout also launched QE and normal PAM
  authentication released it. With the user's idle-inhibitor preference restored,
  suspend resumed directly into QE and normal PAM authentication released it.
  The rollback drill then restored Hyprlock for manual, before-sleep, and idle
  paths; all three passed, with the idle timeout temporarily reduced to one
  minute and restored to five minutes afterward. QE was reapplied with no
  Hyprland config errors and Hypridle restarted; the final `Super+Backspace` QE
  smoke passed.

Threat and failure checklist:

- Pre-secure protocol, surface, or secure-confirmation timeout exits without
  claiming a locked state; Hyprlock is not required for recovery.
- Post-secure process failure remains compositor-locked and must never trigger
  automatic QE restart or a fullscreen fallback.
- PAM responses exist only in the local input and native PAM call; the input is
  cleared before submission and no response is logged or persisted.
- PAM failure, error, cancellation, stale completion, and empty input never set
  `locked` false; failed attempts use a bounded retry delay and attempt limit
  with generic UI text.
- The lock exposes no IPC endpoint and the presentation component receives the
  controller rather than direct unlock authority.
- Invalid or unavailable disk input uses an opaque-black fallback; no file or
  source reload is consumed after initialization.
- Idle/before-sleep integration passed on 2026-09-07. Hyprlock rollback was
  historically exercised before the fallback was retired.

Emergency recovery gate for every destructive test:

1. Before starting, switch to an alternate TTY and prove the user can log in,
   then return to the graphical session.
2. Record the graphical session ID with `loginctl list-sessions` and keep these
   instructions available outside that session.
3. If the lock process dies after compositor `secure`, do not restart QE. From
   the verified TTY, terminate the affected graphical session with
   `loginctl terminate-session <graphical-session-id>`.
4. Start a fresh graphical session with the unchanged QE configuration. A
   machine reboot is the final recovery path if session termination fails.

Alternate-TTY access, post-secure crash recovery, and hot-plug/multi-output
behavior were manually confirmed in the disposable session on 2026-09-07. The
lock remained compositor-enforced after the main process was killed, terminating
the affected graphical session from a separate TTY restored login recovery, and
output attach/detach preserved lock coverage.

Relevant decisions: ADR-002 (separate lock process), ADR-011 (native integration
before commands), and ADR-041 (`login` PAM service) in `docs/DECISIONS.md`.

Scope:

- minimal `lock.qml` process graph
- one session-lock surface per screen
- PAM password conversation
- secure-state and authentication state machine
- battery/time/background as optional read-only visuals
- manual lock entry point
- idle and before-sleep integration
- file watching/reload disabled while locked

Likely affected files/subsystems:

- `lock.qml`
- `lock/`
- lock-safe config/theme adapter
- Hyprland keybindings and Hypridle config at final cutover

Deliverables:

- secure lock process
- threat/failure checklist
- emergency recovery instructions
- explicit Hyprlock retirement and recovery record

Acceptance criteria:

- compositor `secure` is confirmed on all active outputs
- no ordinary fullscreen fallback exists
- wrong/empty/cancelled PAM responses remain locked
- successful PAM completion is the only UI path to `locked = false`
- secrets are cleared and absent from logs
- monitor hot-plug behavior is tested
- suspend/resume remains locked
- pre-secure surface creation failure does not expose a false locked state
- post-secure process crash behavior and TTY recovery are explicitly tested in
  a disposable session where feasible
- no IPC method can unlock
- Hyprlock is not required by the QE lock path

Validation:

- automated state-machine tests with fake PAM results where possible
- nested/disposable compositor tests
- controlled real-session manual checklist with TTY access confirmed first
- idle and before-sleep tests

Rollback/recovery:

- The production Hypr config is version-controlled in the dotfiles repository.
  `~/.local/bin/qe-lock` remains the manual and Hypridle entry point.
- The Hyprlock rollback was completed during Phase 12 validation and is now
  retired. Do not claim a Hyprlock cutover rollback as an available recovery
  path; use the alternate TTY session-termination procedure above.
- a crash after secure lock requires compositor/session recovery, not QE restart

Out of scope:

- fingerprint, face authentication, remote unlock, lock-screen dashboards
