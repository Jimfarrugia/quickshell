# ADR-043: Share the QE active theme state with the lock process

Status: Accepted for lock visual correctness

Decision: persist the authoritative QE active theme state at the
process-independent `$XDG_STATE_HOME/quickshell/active-theme.json` path. The
persistent shell writes this file, and the isolated lock reads it before
publishing its lock-safe theme. Existing per-shell active-theme files are read
once as a migration source when the shared file is absent.

Context: Quickshell's default `statePath()` is scoped by configuration path and
therefore gives the persistent shell and `lock.qml` different state files. The
lock consequently used its emergency theme even when the persistent shell had a
valid active QE theme, making semantic `primary` and `warning` colors appear
white or otherwise incorrect.

Consequences: QE remains the sole owner of its active theme; the external theme
switcher's independent state is not used as a lock theme source. The lock can
now render the same confirmed QE theme across process boundaries, while an
unavailable or invalid shared state still fails closed to the opaque emergency
theme.
