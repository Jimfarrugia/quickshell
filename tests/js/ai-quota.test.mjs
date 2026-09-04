import assert from "node:assert/strict";
import { clampPercent, formatPercent, formatReset, formatTimeUntil, validateAiQuotaState, validateQuotaDocument } from "../../utils/AiQuota.mjs";

assert.equal(clampPercent(-4), 0);
assert.equal(clampPercent(104), 100);
assert.equal(clampPercent("50"), null);
assert.equal(formatPercent(96.6), "96.6");
assert.equal(formatReset(new Date(2026, 8, 7, 12, 28)), "Monday 7th September at 12:28 PM");
const resetTime = new Date(2026, 8, 9, 0, 28).getTime();
assert.equal(formatTimeUntil(resetTime, new Date(2026, 8, 6, 12, 28).getTime()), "2d 12h");
assert.equal(formatTimeUntil(resetTime, resetTime - 30 * 60000), "30m");
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
console.log("AI_QUOTA_TEST_PASSED");
