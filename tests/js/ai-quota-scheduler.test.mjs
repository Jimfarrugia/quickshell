import assert from "node:assert/strict";
import { providerIds } from "../../utils/AiQuota.mjs";
import { BACKOFF_STEPS_MS, initialState, isBusy, operation, reduce } from "../../utils/AiQuotaScheduler.mjs";

// Drives the scheduler like AiQuotaAdapter does and records performed effects.
function harness(now = 1_000_000) {
  const h = { state: initialState(providerIds), now, effects: [] };
  h.send = event => {
    const next = reduce(h.state, event, h.now);
    h.state = next.state;
    h.effects.push(...next.effects);
    return next.accepted;
  };
  h.take = () => h.effects.splice(0);
  h.starts = effects => effects.filter(effect => effect.type === "start").map(effect => effect.providerId);
  return h;
}

const window = (remaining, error = null) => error
  ? { status: "error", usedPercent: null, remainingPercent: null, resetsAt: null, error }
  : { status: "ok", usedPercent: 100 - remaining, remainingPercent: remaining, resetsAt: "2026-12-01T00:00:00Z", error: null };
function document(id, error = null) {
  const provider = error
    ? { status: "error", lastUpdated: null, error, fiveHour: window(0, error), weekly: window(0, error) }
    : { status: "ok", lastUpdated: "2026-11-22T00:00:00Z", error: null, fiveHour: window(80), weekly: window(60) };
  return { schemaVersion: 1, observedAt: "2026-11-22T00:00:00Z", providers: { [id]: provider } };
}
const ok = id => ({ type: "finished", result: { success: true }, document: document(id) });
const sourceError = (id, code, retryAfterSeconds = null) => ({ type: "finished", result: { success: true },
  document: document(id, { code, retryable: true, retryAfterSeconds }) });
const timeout = { type: "finished", result: { success: false, timedOut: true }, document: null };
const networkError = { type: "finished", result: { success: false }, document: null };
const cancelled = { type: "finished", result: { cancelled: true }, document: null };

// A cycle attempts providers in catalogue order and stays pending between them.
{
  const h = harness();
  assert.equal(h.send({ type: "request", reason: "poll" }), false, "inactive scheduler rejects requests");
  assert.equal(h.send({ type: "activate" }), true);
  assert.deepEqual(h.starts(h.take()), [providerIds[0]]);
  assert.equal(operation(h.state), "pending");
  h.send(ok(providerIds[0]));
  const effects = h.take();
  assert.deepEqual(effects.map(effect => effect.type), ["publish", "start"]);
  assert.equal(effects[0].result.providerId, providerIds[0]);
  assert.equal(effects[0].result.ok, true);
  assert.deepEqual(h.starts(effects), [providerIds[1]]);
  assert.equal(isBusy(h.state), true, "cycle stays one pending operation between providers");
  h.send(ok(providerIds[1]));
  h.send(ok(providerIds[2]));
  assert.equal(operation(h.state), "succeeded");
}

// Retry-After is converted from seconds, and backoff is scoped per provider.
{
  const h = harness();
  h.send({ type: "activate" });
  h.send(ok("claude"));
  h.send(sourceError("openai", "RATE_LIMITED", 3600));
  h.send(timeout);
  assert.equal(h.state.nextAllowedAt.openai, h.now + 3600 * 1000);
  assert.equal(h.state.failureStreak.claude, 0);
  assert.equal(h.state.failureStreak.openai, 1);
  assert.equal(h.state.failureStreak.opencode, 1);
  assert.equal(h.state.nextAllowedAt.opencode, h.now + BACKOFF_STEPS_MS[0]);
  assert.equal(operation(h.state), "succeeded", "one provider succeeding makes the cycle succeed");

  // Automatic cycles skip providers in backoff.
  h.take();
  h.send({ type: "request", reason: "poll" });
  assert.deepEqual(h.starts(h.take()), ["claude"]);
  h.send(ok("claude"));
  assert.equal(isBusy(h.state), false);

  // Manual refresh retries a QE-generated timeout but never a provider rate limit.
  h.send({ type: "request", reason: "manual" });
  assert.deepEqual(h.starts(h.take()), ["claude"]);
  h.send(ok("claude"));
  assert.deepEqual(h.starts(h.take()), ["opencode"], "manual refresh skipped the rate-limited provider");
  h.send(timeout);
  assert.equal(h.state.failureStreak.opencode, 2);
  assert.equal(h.state.nextAllowedAt.opencode, h.now + BACKOFF_STEPS_MS[1]);

  // A non-transient result clears that provider's backoff.
  h.now = h.state.nextAllowedAt.openai + 1;
  h.send({ type: "request", reason: "manual" });
  h.take();
  h.send(ok("claude"));
  h.send(ok("openai"));
  assert.equal(h.state.nextAllowedAt.openai, 0);
  assert.equal(h.state.backoffCodes.openai, "");
}

// Backoff steps cap at the last step.
{
  const h = harness();
  h.send({ type: "activate" });
  for (let round = 0; round < 5; round++) {
    h.now = Math.max(...Object.values(h.state.nextAllowedAt), h.now) + 1;
    if (round > 0) h.send({ type: "request", reason: "poll" });
    while (h.state.inFlight !== "") h.send(networkError);
  }
  assert.equal(h.state.failureStreak.claude, BACKOFF_STEPS_MS.length);
  assert.equal(h.state.nextAllowedAt.claude, h.now + BACKOFF_STEPS_MS[BACKOFF_STEPS_MS.length - 1]);
}

// Outcome: failed only when every attempted provider failed; a failed start counts.
{
  const h = harness();
  h.send({ type: "activate" });
  h.send({ type: "startFailed", providerId: "claude" });
  const effects = h.take();
  assert.equal(effects[1].type, "publish");
  assert.deepEqual(effects[1].result, { ok: false, error: "FAILED_TO_START", providerId: "claude" });
  h.send(networkError);
  h.send(sourceError("opencode", "UNAUTHORIZED"));
  assert.equal(operation(h.state), "failed");
  assert.equal(h.state.nextAllowedAt.opencode, 0, "non-transient provider error sets no backoff");

  // A failed start sets no backoff either.
  h.take();
  h.send({ type: "request", reason: "poll" });
  assert.deepEqual(h.starts(h.take()), ["claude"]);
  h.send(networkError);
  assert.deepEqual(h.starts(h.take()), ["opencode"], "openai was still backing off");
  h.send(timeout);
  assert.equal(operation(h.state), "failed");

  // A cycle that attempts no provider leaves the outcome unchanged.
  h.send({ type: "request", reason: "poll" });
  assert.deepEqual(h.starts(h.take()), []);
  assert.equal(isBusy(h.state), false);
  assert.equal(operation(h.state), "failed");
}

// Requests during a cycle coalesce; manual and resume outrank polling.
{
  const h = harness();
  h.send({ type: "activate" });
  h.send({ type: "request", reason: "poll" });
  assert.equal(h.state.queuedReason, "", "poll during a cycle is dropped");
  h.send({ type: "request", reason: "resume" });
  h.send({ type: "request", reason: "manual" });
  h.send({ type: "request", reason: "resume" });
  assert.equal(h.state.queuedReason, "manual");
  h.take();
  h.send(ok("claude"));
  h.send(ok("openai"));
  h.send(ok("opencode"));
  assert.equal(h.state.cycle.reason, "manual", "queued request runs as one follow-up cycle");
  assert.equal(h.state.queuedReason, "");
}

// Sleep cancels the in-flight helper without recording a failure; a manual
// request queued while asleep runs once on wake.
{
  const h = harness();
  h.send({ type: "activate" });
  h.take();
  h.send({ type: "sleep" });
  assert.deepEqual(h.take(), [{ type: "cancel" }]);
  assert.equal(operation(h.state), "pending", "cancellation stays pending");
  assert.equal(h.send({ type: "request", reason: "manual" }), true);
  assert.equal(h.state.queuedReason, "manual");
  h.send(cancelled);
  assert.deepEqual(h.take(), [], "no publish for a cancelled request");
  assert.equal(h.state.failureStreak.claude, 0);
  h.send({ type: "wake" });
  h.send({ type: "wake" });
  const effects = h.take();
  assert.deepEqual(h.starts(effects), ["claude"]);
  assert.equal(effects.some(effect => effect.type === "resumed"), false, "queued request replaces the resume check");
  assert.equal(h.state.cycle.reason, "manual");
  assert.equal(operation(h.state), "pending");
}

// Wake with nothing queued hands the resume decision to the service, and a
// resume request during an outstanding cancellation starts after it completes.
{
  const h = harness();
  h.send({ type: "activate" });
  h.send({ type: "sleep" });
  h.send({ type: "wake" });
  assert.deepEqual(h.take().map(effect => effect.type), ["start", "cancel", "resumed"]);
  h.send({ type: "request", reason: "resume" });
  assert.equal(h.state.queuedReason, "resume");
  h.send(cancelled);
  assert.deepEqual(h.starts(h.take()), ["claude"]);
  assert.equal(h.state.cycle.reason, "resume");
}

// A cancelled cycle leaves the previous outcome unchanged.
{
  const h = harness();
  h.send({ type: "activate" });
  h.send(networkError);
  h.send(networkError);
  h.send(networkError);
  assert.equal(operation(h.state), "failed");
  h.now += BACKOFF_STEPS_MS[0];
  h.send({ type: "request", reason: "poll" });
  h.send({ type: "sleep" });
  h.send(cancelled);
  h.send({ type: "wake" });
  assert.equal(operation(h.state), "failed");
}

// Deactivation cancels and clears queued work; reactivating before the cancel
// completes keeps the new startup cycle.
{
  const h = harness();
  h.send({ type: "activate" });
  h.send({ type: "request", reason: "manual" });
  h.take();
  h.send({ type: "deactivate" });
  assert.deepEqual(h.take(), [{ type: "cancel" }]);
  assert.equal(h.state.queuedReason, "");
  assert.equal(h.send({ type: "request", reason: "manual" }), false);
  h.send(cancelled);
  assert.equal(isBusy(h.state), false);
  assert.equal(operation(h.state), "idle");

  h.send({ type: "activate" });
  h.take();
  h.send({ type: "deactivate" });
  h.send({ type: "activate" });
  assert.equal(h.state.queuedReason, "startup");
  h.send(cancelled);
  assert.deepEqual(h.starts(h.take()), ["claude"], "reactivation kept its startup cycle");
}

// A helper that finishes before an outstanding cancel publishes its result and
// stops; invalid documents become a transient failure, as before.
{
  const h = harness();
  h.send({ type: "activate" });
  h.send({ type: "sleep" });
  h.take();
  h.send(ok("claude"));
  const effects = h.take();
  assert.deepEqual(effects.map(effect => effect.type), ["publish"]);
  assert.equal(h.state.cancelling, "");
  assert.equal(isBusy(h.state), false);

  const g = harness();
  g.send({ type: "activate" });
  g.take();
  g.send({ type: "finished", result: { success: true }, document: { schemaVersion: 2 } });
  assert.equal(g.take()[0].result.error, "NETWORK_ERROR");
}

// reduce never mutates its input state.
{
  const state = initialState(providerIds);
  const frozen = JSON.stringify(state);
  reduce(state, { type: "activate" }, 5);
  assert.equal(JSON.stringify(state), frozen);
}

console.log("AI_QUOTA_SCHEDULER_TEST_PASSED");
