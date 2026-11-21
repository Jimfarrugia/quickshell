# ADR-044: Use native UPower for optional lock battery presentation

Status: Accepted by user on 2026-09-08

Decision: add one lock-local, read-only adapter over Quickshell's native UPower
display device. The adapter exposes only battery availability and normalized
percentage. Lock presentation hides the battery block when no laptop battery is
available.

Context: the requested Hyprlock-inspired layout includes battery percentage,
but the retired layout obtained it through repeatedly executed shell commands.
The lock process must remain minimal and must not add command execution or
polling.

Consequences: the isolated lock gains one event-driven native DBus dependency
without importing the persistent shell service graph. UPower failure affects
only the optional battery visual and cannot block lock acquisition,
authentication, or unlock.
