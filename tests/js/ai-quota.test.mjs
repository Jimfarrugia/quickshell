import assert from "node:assert/strict";
import { clampPercent, formatPercent, formatReset, formatTimeUntil, validateAiQuotaState, validateQuotaDocument,
  blankProvider, mergeQuotaResult, markProvidersStale, publishProviderFailure, providerError, safeErrorSummary,
  STALE_AFTER_MS } from "../../utils/AiQuota.mjs";

assert.equal(clampPercent(-4), 0);
assert.equal(clampPercent(104), 100);
assert.equal(clampPercent("50"), null);
assert.equal(formatPercent(96.6), "96.6");
assert.equal(formatReset(new Date(2026, 8, 7, 12, 28)), "Monday 7th September at 12:28 PM");
const resetTime = new Date(2026, 8, 9, 0, 28).getTime();
assert.equal(formatTimeUntil(resetTime, new Date(2026, 8, 6, 12, 28).getTime()), "2d 12h");
assert.equal(formatTimeUntil(resetTime, resetTime - 30 * 60000), "30m");
assert.equal(formatTimeUntil(resetTime, resetTime - 90 * 60000), "1h 30m");
assert.equal(formatTimeUntil(resetTime, resetTime - 5.5 * 3600000), "5h 30m");
assert.equal(formatTimeUntil(resetTime, resetTime - 23 * 3600000 - 45 * 60000), "23h 45m");
assert.equal(validateAiQuotaState({ schemaVersion: 1, selectedProvider: "opencode" }).ok, true);
assert.equal(validateAiQuotaState({ schemaVersion: 1, selectedProvider: "other" }).value.selectedProvider, "openai");

const window = { status: "ok", usedPercent: 25, remainingPercent: 75,
  resetsAt: "2026-09-08T00:00:00Z", error: null };
const document = { schemaVersion: 1, observedAt: "2026-09-04T00:00:00Z", providers: {
  openai: { status: "ok", lastUpdated: "2026-09-04T00:00:00Z", fiveHour: window, weekly: window, error: null },
  opencode: { status: "ok", lastUpdated: "2026-09-04T00:00:00Z", fiveHour: window, weekly: window, error: null }
} };
assert.equal(validateQuotaDocument(document).ok, true);
assert.equal(validateQuotaDocument({ ...document, providers: { openai: document.providers.openai } }).ok, false);
assert.equal(validateQuotaDocument({ ...document, providers: { ...document.providers, openai: { ...document.providers.openai, weekly: { ...window, remainingPercent: 101 } } } }).ok, false);
assert.equal(validateQuotaDocument({ ...document, providers: { ...document.providers, openai: { ...document.providers.openai, status: "unexpected" } } }).ok, false);
assert.equal(validateQuotaDocument({ ...document, providers: { ...document.providers, openai: { ...document.providers.openai, weekly: { ...window, error: null, status: "error", usedPercent: null, remainingPercent: null, resetsAt: null } } } }).ok, false);
const quotaError = { code: "INVALID_RESPONSE", retryable: false, retryAfterSeconds: null };
const errorWindow = { status: "error", usedPercent: null, remainingPercent: null, resetsAt: null, error: quotaError };
assert.equal(validateQuotaDocument({ ...document, providers: { ...document.providers, openai: { ...document.providers.openai, weekly: { ...window, error: quotaError } } } }).ok, false);
assert.equal(validateQuotaDocument({ ...document, providers: { ...document.providers, openai: { ...document.providers.openai, status: "error", error: quotaError } } }).ok, false);
assert.equal(validateQuotaDocument({ ...document, providers: { ...document.providers, openai: { ...document.providers.openai, status: "error", fiveHour: errorWindow, error: quotaError } } }).ok, true);

// ----- provider state reducer (retention, freshness, staleness) -----
const win = used => ({ status: "ok", usedPercent: used, remainingPercent: 100 - used,
  resetsAt: "2026-09-11T00:00:00Z", error: null });
const errWin = code => ({ status: "error", usedPercent: null, remainingPercent: null,
  resetsAt: null, error: { code, retryable: true, retryAfterSeconds: null } });
const now = new Date("2026-09-04T12:00:00Z").getTime();
const observedAt = "2026-09-04T12:00:00Z";
const blankProviders = { openai: blankProvider("openai"), opencode: blankProvider("opencode") };

// Error summaries and retryability.
assert.equal(safeErrorSummary("AUTH_MISSING"), "OpenCode credentials are not configured");
assert.equal(providerError("TIMEOUT", now).retryable, true);
assert.equal(providerError("INVALID_RESPONSE", now).retryable, false);
assert.equal(providerError("AUTH_EXPIRED", now).boundary, "ai-quota");
assert.equal(providerError("AUTH_EXPIRED", now).timestamp.getTime(), now);

// Fresh success: both windows current and available.
const freshProviders = { openai: { status: "ok", lastUpdated: observedAt, fiveHour: win(25), weekly: win(40), error: null } };
const merged = mergeQuotaResult(blankProviders, { ok: true, data: { observedAt, providers: freshProviders }, providerId: "openai" }, now);
assert.equal(merged.openai.availability, "available");
assert.equal(merged.openai.freshness, "current");
assert.equal(merged.openai.weekly.status, "ok");
assert.equal(merged.openai.weekly.freshness, "current");
assert.equal(merged.openai.weekly.lastUpdated.getTime(), now);
assert.equal(merged.openai.lastError, null);
assert.equal(merged.openai.lastAttempt.getTime(), now);
assert.equal(merged.opencode.availability, "unknown");

// Monthly present contributes to availability; absent monthly keeps the retained window.
assert.equal(mergeQuotaResult(blankProviders, { ok: true, data: { observedAt,
  providers: { openai: { status: "ok", lastUpdated: observedAt, fiveHour: win(25), weekly: win(40), monthly: win(5), error: null } } },
  providerId: "openai" }, now).openai.monthly.status, "ok");
assert.equal(mergeQuotaResult(blankProviders, { ok: true, data: { observedAt, providers: freshProviders }, providerId: "openai" }, now)
  .openai.monthly.status, "error");

// Partial failure retains the previous successful window and marks the provider degraded.
const partialProviders = { openai: { status: "error", lastUpdated: observedAt,
  fiveHour: errWin("RATE_LIMITED"), weekly: win(50), error: { code: "RATE_LIMITED", retryable: true, retryAfterSeconds: null } } };
const partial = mergeQuotaResult(merged, { ok: true, data: { observedAt, providers: partialProviders }, providerId: "openai" }, now + 300000);
assert.equal(partial.openai.availability, "degraded");
assert.equal(partial.openai.weekly.remainingPercent, 50);
assert.equal(partial.openai.fiveHour.status, "ok");
assert.equal(partial.openai.fiveHour.error.code, "RATE_LIMITED");
assert.equal(partial.openai.freshness, "current");
assert.equal(partial.openai.lastError.code, "RATE_LIMITED");

// Total failure after a successful value: degraded with a retryable error, retention preserved.
const failed = publishProviderFailure(merged, "openai", "AUTH_EXPIRED", now + 1000);
assert.equal(failed.openai.availability, "degraded");
assert.equal(failed.openai.lastError.code, "AUTH_EXPIRED");
assert.equal(failed.openai.lastError.retryable, true);
assert.equal(failed.openai.lastAttempt.getTime(), now + 1000);
assert.equal(failed.openai.fiveHour.error.code, "AUTH_EXPIRED");
assert.equal(failed.openai.freshness, "current");

// Failure with no prior value: unavailable/unknown.
const failedBlank = publishProviderFailure(blankProviders, "openai", "TIMEOUT", now);
assert.equal(failedBlank.openai.availability, "unavailable");
assert.equal(failedBlank.openai.freshness, "unknown");

// Failure without a provider id applies to every provider.
const failedAll = publishProviderFailure(blankProviders, null, "NETWORK_ERROR", now);
assert.equal(failedAll.openai.availability, "unavailable");
assert.equal(failedAll.opencode.availability, "unavailable");

// Staleness is inclusive at the threshold and demotes availability to degraded.
const stale = markProvidersStale(merged, now + STALE_AFTER_MS);
assert.equal(stale.openai.availability, "degraded");
assert.equal(stale.openai.freshness, "stale");
assert.equal(stale.openai.weekly.freshness, "stale");
assert.equal(stale.openai.fiveHour.freshness, "stale");
assert.equal(markProvidersStale(merged, now + STALE_AFTER_MS - 1).openai.freshness, "current");

console.log("AI_QUOTA_TEST_PASSED");
