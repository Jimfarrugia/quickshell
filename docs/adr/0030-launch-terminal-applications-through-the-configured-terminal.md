# ADR-030: Launch terminal applications through the configured terminal

Status: Accepted by user on 2026-09-01

Decision: the Phase 7 launcher includes eligible desktop entries marked
`Terminal=true`. When launching one, `LauncherService` prepends the value of
`$TERMINAL` (falling back to `kitty`) and the `--` argument to the structured
desktop-entry command. Arguments remain an array and are never passed through a
shell.

Context: useful TUI applications such as `jellyfin-tui` and `btop` are commonly
registered as terminal desktop entries. Excluding them makes the launcher omit
valid applications, while guessing or parsing a terminal command from a shell
string would violate the structured-launch boundary.

Consequences: terminal entries require a usable terminal emulator in `$TERMINAL`
or the fallback `kitty`. Usage counts represent successful terminal launches in
the same way as graphical launches. The launcher does not add a new terminal
configuration field in this phase.

Affected areas: launcher eligibility and launch command construction, launcher
tests, Phase 7 documentation, and the terminal application acceptance matrix.

Revisit if: QE adds an authored terminal-emulator configuration or needs
terminal-specific arguments beyond the standard `--` separator.
