# ADR-013: Idle inhibition exposes requested state only

Status: Accepted by user on 2026-08-24

Decision: implement the Phase 3 native Wayland idle-inhibitor toggle as
process-session requested state bound to a persistent QE bar window. Do not
claim or synthesize compositor-confirmed active state.

Context: installed Quickshell 0.3.0 exposes `IdleInhibitor.enabled` and `window`
but no active property, protocol-object status, rejection signal, or compositor
acknowledgement. Treating `enabled` as confirmed would violate QE's
requested-versus-confirmed state rule.

Rationale: requested-only state preserves the native no-command boundary and
honestly represents what QE can know. The Wayland object lifetime still gives
safe automatic release when the window or process disappears.

Alternatives considered: defer the module entirely; add a C++ native extension
in Phase 3; present `enabled` as confirmed active.

Consequences: the bar indicates that inhibition is requested, not guaranteed;
confirmed-active reporting remains deferred. The requested boolean is persisted
by the later ADR-035 decision, but the compositor request remains ephemeral and
does not replace Hypridle, manual locking, or suspend policy.

Affected areas: `IdleService`, bar idle-inhibitor presentation, Phase 3
acceptance language, later control-center idle state.

Revisit if: Quickshell exposes reliable inhibitor status or QE adopts a reviewed
native extension that can distinguish protocol creation/revocation. Persistence
of the requested boolean is defined by ADR-035.
