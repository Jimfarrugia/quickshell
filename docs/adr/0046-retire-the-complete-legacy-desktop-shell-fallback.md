# ADR-046: Retire the complete legacy desktop-shell fallback

Status: Accepted by user on 2026-09-08

Decision: after sustained daily-use validation, Phase 13 no longer maintains or
acceptance-tests a complete Waybar/Rofi/Dunst/Hyprlock restoration profile.
Production recovery restarts the supervised QE shell or, for a post-secure lock
failure, recovers the graphical session from a TTY. Rofi remains for specialized
flows and the power menu. `pavucontrol`, Blueman Manager, and
`nm-connection-editor` remain scoped escape hatches for unsupported dashboard
operations rather than a desktop-shell rollback.

Context: the original Phase 13 fallback requirement existed until QE completed
an agreed daily-use period. The user confirmed that QE is fully validated in
daily use and explicitly stated that a complete fallback is no longer needed.
The discovered stale Waybar binary and absent active Dunst configuration do not
justify repairing and maintaining an otherwise retired profile.

Consequences: `qe-doctor` checks current production dependencies, ownership, and
conflicts but does not require retired fallback executables or configuration.
Waybar, Dunst, and Hyprlock packages and archived files may be removed separately
after explicit package/configuration cleanup approval. This decision does not
remove the direct guarded QE launcher or the lock's TTY recovery procedure.
