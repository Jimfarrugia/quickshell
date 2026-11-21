# ADR-025: QE-owned OSD and reversible action cutover

Status: Accepted for Phase 6 implementation

Decision: hardware feedback is owned by an independent QE OSD service rather than
being sent through desktop notifications. Hardware keybindings call typed QE
IPC actions. Dunst is blocked with a reversible user-service mask only after
the switcher's Dunst target is retired, and rollback restores the original
bindings, target list, service activation, and legacy producers.

Context: Dunst and QE cannot own `org.freedesktop.Notifications` concurrently.
The existing hardware scripts also combine subsystem mutation with Dunst
feedback, while native PipeWire and MPRIS APIs are available for the required
operations.

Rationale: separating OSD feedback from notification delivery prevents a
notification-owner failure from breaking hardware controls, preserves truthful
pending/confirmed state, and makes the ownership transition independently
reversible. The user selected persistent masking in the symlinked dotfiles
systemd directory and approved preservation of the legacy volume semantics.
The presentation policy uses one active slot so newly triggered feedback is
visible immediately and superseded state is not replayed after its relevance
has passed.

Consequences: Phase 6 adds OSD/action fixtures, native microphone and media
coverage, and a keyboard LED adapter. The external theme switcher continues to
support Dunst as a source target but skips it through the validated retirement
list after cutover.

Revisit if: QE gains a native action transport that is more stable than the
current namespaced IPC contract, or keyboard LED discovery cannot be made
portable without a user-authored device override.
