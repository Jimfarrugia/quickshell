# ADR-035: Persist idle inhibitor requested state

Status: Accepted by user on 2026-09-04

Decision: persist the idle inhibitor's requested boolean in versioned QE state
and restore it after a QE restart. Persisting the request does not claim that
the compositor has an active inhibitor; the native Wayland inhibitor remains
bound to the current visible QE bar window and is recreated by the integration
when that surface is available.

Context: users expect an explicitly enabled bar preference to survive restarting
the persistent shell, while Quickshell 0.3.1 exposes no compositor-confirmed
active state.

Rationale: this preserves the requested-versus-confirmed distinction while
avoiding a surprising reset after a routine shell restart. Missing, malformed,
or incompatible state safely defaults to disabled.

Consequences: `IdleService` owns a versioned `idle-inhibitor.json` state file
and writes it on user requests. Configuration disablement and loss of the last
bar window still release the active compositor request; no automatic reclaim or
active-state claim is added.
