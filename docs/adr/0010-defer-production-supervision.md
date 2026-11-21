# ADR-010: Defer production supervision

Status: Accepted by user

Decision: do not choose systemd user service or Hyprland autostart until runtime
behavior is known.

Context: restart policy, environment import, and failure handling depend on the
mature process topology.

Rationale: avoids encoding lifecycle assumptions before the shell is stable.

Alternatives considered: systemd user service immediately; Hyprland autostart
immediately.

Consequences: development uses explicit launch commands; Phase 13 must make and
record the production decision.

Affected areas: entry points, diagnostics, deployment.

Revisit if: an earlier cutover requires automatic session startup.
