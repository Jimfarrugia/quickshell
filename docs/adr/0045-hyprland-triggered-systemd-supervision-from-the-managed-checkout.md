# ADR-045: Hyprland-triggered systemd supervision from the managed checkout

Status: Accepted by user on 2026-09-08

Decision: retain the existing project checkout as QE's managed production
location. Hyprland imports the current Wayland display, instance signature, and
desktop identity before restarting a systemd user service; systemd owns the
persistent shell process, journal output, and bounded restart on failure. The
lock remains an unsupervised, on-demand process and is never automatically
restarted. Hyprland invokes the stable `qe-shell --service-start` lifecycle mode
rather than embedding shell sequencing in presentation/session configuration.

Context: Phase 13 had deferred both deployment location and supervision until
runtime behavior was known. The persistent shell now has established guarded
entry points and daily-use evidence. This system has no active systemd
graphical-session target, so enabling the unit against such a target would add
an unverified startup dependency. Hyprland is already the reliable session
trigger and can hand process ownership to systemd after importing its
environment.

Consequences: the checkout must remain at a stable location or its XDG user-bin
links must be deliberately redeployed. Quickshell 0.3.1 internally relaunches a
crashed shell child only when the prior launch survived at least 10 seconds and
exits after an immediate repeat crash. Systemd waits two seconds before
restarting that failed launcher and limits starts to three per 60 seconds;
failures separated by more than the inner guard may still continue to relaunch
and remain journal-visible. `qe-shell --restart` delegates to the active service
but retains a guarded direct fallback for development and recovery. This
decision resolves and supersedes ADR-010's deferral; it does not supervise the
security-critical lock process.
