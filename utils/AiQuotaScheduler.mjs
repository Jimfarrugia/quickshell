// AI quota refresh scheduler: pure transitions for refresh cycles, coalescing,
// sleep/resume cancellation, and per-provider backoff. AiQuotaAdapter holds the
// state and performs the returned effects; this module performs none itself.
//
// reduce(state, event, now) -> { state, effects, accepted }
// Events:
//   { type: "activate" } | { type: "deactivate" }
//   { type: "request", reason: "poll" | "startup" | "resume" | "manual" }
//   { type: "sleep" } | { type: "wake" }
//   { type: "startFailed", providerId }
//   { type: "finished", result: { cancelled, success, timedOut, parseError }, document }
//     (`document` is the helper's parsed JSON as plain JS, or null)
// Effects (perform in order):
//   { type: "start", providerId }  run the helper for one provider
//   { type: "cancel" }             cancel the running helper
//   { type: "publish", result }    hand a provider result to the service
//   { type: "resumed" }            woke with nothing queued; the service decides
//                                  whether a resume refresh is due
import { validateQuotaDocument } from "./AiQuota.mjs";

const REASON_PRIORITY = { poll: 0, startup: 1, resume: 2, manual: 3 };
const TRANSIENT_CODES = ["TIMEOUT", "NETWORK_ERROR", "RATE_LIMITED"];
// QE-generated failures a manual refresh may retry during backoff; a provider
// rate limit and its Retry-After deadline are never bypassed.
const MANUAL_RETRY_CODES = ["TIMEOUT", "NETWORK_ERROR"];
export const BACKOFF_STEPS_MS = Object.freeze([600000, 1200000, 1800000]);

function perProvider(ids, value) {
  const result = {};
  for (const id of ids) result[id] = value;
  return result;
}

export function initialState(providerIds) {
  const ids = Array.from(providerIds);
  return {
    providers: ids,
    active: false,
    sleeping: false,
    // { reason, remaining: [ids], attempts, failures } while a cycle runs
    cycle: null,
    queuedReason: "",
    inFlight: "",
    // "" | "sleep" | "deactivate" | "reactivated" while a cancel is outstanding
    cancelling: "",
    nextAllowedAt: perProvider(ids, 0),
    failureStreak: perProvider(ids, 0),
    backoffCodes: perProvider(ids, ""),
    // Last refresh cycle outcome: "idle" until a cycle with an attempt completes.
    outcome: "idle"
  };
}

export function isBusy(state) {
  return state.cycle !== null || state.inFlight !== "" || state.queuedReason !== "";
}

// The service-contract operation: pending while busy, else the last outcome.
export function operation(state) {
  return isBusy(state) ? "pending" : state.outcome;
}

function priority(reason) {
  return REASON_PRIORITY[reason] || 0;
}

function copy(state) {
  return Object.assign({}, state, {
    providers: Array.from(state.providers),
    cycle: state.cycle === null ? null : Object.assign({}, state.cycle, {
      remaining: Array.from(state.cycle.remaining)
    }),
    nextAllowedAt: Object.assign({}, state.nextAllowedAt),
    failureStreak: Object.assign({}, state.failureStreak),
    backoffCodes: Object.assign({}, state.backoffCodes)
  });
}

function eligible(s, id, now) {
  if (now >= (s.nextAllowedAt[id] || 0)) return true;
  return s.cycle !== null && s.cycle.reason === "manual"
    && MANUAL_RETRY_CODES.includes(s.backoffCodes[id]);
}

function applyBackoff(s, id, code, retryAfterSeconds, now) {
  if (!TRANSIENT_CODES.includes(code)) {
    s.nextAllowedAt[id] = 0;
    s.failureStreak[id] = 0;
    s.backoffCodes[id] = "";
    return;
  }
  const streak = Math.min(BACKOFF_STEPS_MS.length, (s.failureStreak[id] || 0) + 1);
  s.failureStreak[id] = streak;
  s.nextAllowedAt[id] = now + (retryAfterSeconds !== null && retryAfterSeconds !== undefined
    ? retryAfterSeconds * 1000 : BACKOFF_STEPS_MS[streak - 1]);
  s.backoffCodes[id] = code;
}

function recordAttempt(s, failed) {
  if (s.cycle === null) return;
  s.cycle.attempts += 1;
  if (failed) s.cycle.failures += 1;
}

function continueCycle(s, effects, now) {
  if (!s.active || s.sleeping || s.inFlight !== "" || s.cycle === null) return;
  while (s.cycle.remaining.length > 0) {
    const id = s.cycle.remaining.shift();
    if (!eligible(s, id, now)) continue;
    s.inFlight = id;
    effects.push({ type: "start", providerId: id });
    return;
  }
  // A cycle that attempted no provider leaves the previous outcome unchanged.
  if (s.cycle.attempts > 0)
    s.outcome = s.cycle.failures === s.cycle.attempts ? "failed" : "succeeded";
  s.cycle = null;
  drainQueued(s, effects, now);
}

function queueReason(s, reason) {
  if (reason === "poll" && (s.queuedReason !== "" || s.cycle !== null)) return;
  if (s.queuedReason !== "" && priority(reason) <= priority(s.queuedReason)) return;
  s.queuedReason = reason;
}

function request(s, effects, reason, now) {
  reason = reason || "poll";
  if (!s.active) return false;
  if (s.sleeping || s.inFlight !== "" || s.cycle !== null) {
    queueReason(s, reason);
    return true;
  }
  if (s.queuedReason !== "") {
    if (priority(s.queuedReason) > priority(reason)) reason = s.queuedReason;
    s.queuedReason = "";
  }
  s.cycle = { reason: reason, remaining: Array.from(s.providers), attempts: 0, failures: 0 };
  continueCycle(s, effects, now);
  return true;
}

function drainQueued(s, effects, now) {
  if (!s.active || s.sleeping || s.inFlight !== "" || s.cycle !== null || s.queuedReason === "") return;
  const reason = s.queuedReason;
  s.queuedReason = "";
  request(s, effects, reason, now);
}

function completeCancellation(s, effects, now) {
  const reason = s.cancelling;
  s.cancelling = "";
  s.inFlight = "";
  s.cycle = null;
  if (reason === "deactivate") s.queuedReason = "";
  else drainQueued(s, effects, now);
}

function failureCode(result) {
  return result.timedOut ? "TIMEOUT" : (result.parseError ? "INVALID_RESPONSE" : "NETWORK_ERROR");
}

function finish(s, effects, event, now) {
  if (s.inFlight === "") return;
  const result = event.result || {};
  if (result.cancelled) {
    completeCancellation(s, effects, now);
    return;
  }
  const id = s.inFlight;
  s.inFlight = "";
  let published = false;
  if (result.success && event.document !== null && event.document !== undefined) {
    const checked = validateQuotaDocument(event.document, [id]);
    if (checked.ok) {
      const sourceError = checked.value.providers[id].error;
      applyBackoff(s, id, sourceError ? sourceError.code : null,
        sourceError ? sourceError.retryAfterSeconds : null, now);
      effects.push({ type: "publish", result: { ok: true, data: checked.value, providerId: id } });
      recordAttempt(s, sourceError !== null);
      published = true;
    }
  }
  if (!published) {
    const code = failureCode(result);
    applyBackoff(s, id, code, null, now);
    effects.push({ type: "publish", result: { ok: false, error: code, providerId: id } });
    recordAttempt(s, true);
  }
  // The helper finished before an outstanding cancel took effect.
  if (s.cancelling !== "") completeCancellation(s, effects, now);
  else continueCycle(s, effects, now);
}

export function reduce(state, event, now) {
  const s = copy(state);
  const effects = [];
  let accepted = true;
  switch (event.type) {
  case "activate":
    if (s.active) break;
    s.active = true;
    if (s.cancelling === "deactivate") s.cancelling = "reactivated";
    accepted = request(s, effects, "startup", now);
    break;
  case "deactivate":
    if (!s.active) break;
    s.active = false;
    s.sleeping = false;
    s.queuedReason = "";
    s.cycle = null;
    if (s.inFlight !== "") {
      s.cancelling = "deactivate";
      effects.push({ type: "cancel" });
    }
    break;
  case "request":
    accepted = request(s, effects, event.reason, now);
    break;
  case "sleep":
    if (s.sleeping) break;
    s.sleeping = true;
    s.cycle = null;
    if (s.inFlight !== "" && s.cancelling === "") {
      s.cancelling = "sleep";
      effects.push({ type: "cancel" });
    }
    break;
  case "wake":
    if (!s.sleeping) break;
    s.sleeping = false;
    // A request queued while asleep runs now; otherwise the service checks
    // whether a resume refresh is due.
    if (s.queuedReason !== "" && s.inFlight === "") drainQueued(s, effects, now);
    else effects.push({ type: "resumed" });
    break;
  case "startFailed":
    if (s.inFlight !== event.providerId) break;
    s.inFlight = "";
    effects.push({ type: "publish", result: { ok: false, error: "FAILED_TO_START", providerId: event.providerId } });
    recordAttempt(s, true);
    continueCycle(s, effects, now);
    break;
  case "finished":
    finish(s, effects, event, now);
    break;
  default:
    accepted = false;
  }
  return { state: s, effects: effects, accepted: accepted };
}
