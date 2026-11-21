# ADR-024: Isolated QE notification ownership prototype

Status: Accepted by user on 2026-08-29

Decision: implement notification ownership through the native Quickshell
`NotificationServer`, with a separate structured DBus owner watcher for readiness
and diagnostics. DND suppresses Low and Normal popups but retains their
current-process history; Critical notifications remain visible. The Phase 5
acceptance test may stop Dunst in the current graphical session only within a
trapped stop/test/restart procedure. Production Dunst disablement, keybinding
migration, legacy producer changes, and hardware OSDs remain deferred to Phase 6.

Context: the notification DBus name is exclusive, while Quickshell 0.3.1 exposes
notification capabilities and objects but no QML property reporting successful
service acquisition. Dunst currently owns the name through a static DBus-activated
user service, and existing hardware producers still target Dunst.

Rationale: native notification delivery preserves Quickshell object lifetime and
event handling. A structured owner boundary prevents QE from claiming readiness
when Dunst or another service owns the name. The trapped test preserves the daily
fallback without pretending that two notification servers can coexist.

Alternatives considered: one-shot owner probes, early production Dunst disablement,
and keeping notification work entirely behind Dunst. One-shot probes do not report
owner loss promptly; early disablement violates staged migration; deferral provides
no validation of the notification contract.

Consequences: Phase 5 requires an independently tested owner-watcher contract,
bounded untrusted-content rendering, and explicit owner checks before and after the
exclusive test. Notification history is intentionally lost when QE exits, and
existing Dunst-based keybindings and producers remain the rollback path.

Affected areas: `NotificationService`, `NotificationsIntegration`, notification
modules, owner-watcher helper, notification configuration, diagnostics, and Phase 5
validation scripts.

Revisit if: Quickshell exposes reliable notification ownership state, or a separate
DBus test session becomes necessary to protect the primary session.
