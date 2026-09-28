const PROVIDERS = ["openai", "opencode"];
const WINDOWS = ["fiveHour", "weekly"];
const ERROR_CODES = ["AUTH_MISSING", "AUTH_INVALID", "AUTH_EXPIRED", "UNAUTHORIZED", "NOT_ENTITLED", "RATE_LIMITED", "TIMEOUT", "NETWORK_ERROR", "INVALID_RESPONSE"];
const validDate = value => typeof value === "string" && Number.isFinite(new Date(value).getTime());
const exactKeys = (value, keys) => value && Object.keys(value).every(key => keys.includes(key)) && keys.every(key => Object.prototype.hasOwnProperty.call(value, key));
const exactOptionalKeys = (value, required, optional) => value && Object.keys(value).every(key => required.includes(key) || optional.includes(key)) && required.every(key => Object.prototype.hasOwnProperty.call(value, key));

export function clampPercent(value) {
  return typeof value === "number" && Number.isFinite(value) ? Math.max(0, Math.min(100, value)) : null;
}

export function formatPercent(value) {
  if (typeof value !== "number" || !Number.isFinite(value)) return "--";
  return Number.isInteger(value) ? String(value) : value.toFixed(1).replace(/\.0$/, "");
}

export function validateError(value) {
  if (value === null) return { ok: true, value: null };
  if (!exactKeys(value, ["code", "retryable", "retryAfterSeconds"]) || !ERROR_CODES.includes(value.code) || typeof value.retryable !== "boolean") return { ok: false };
  if (value.retryAfterSeconds !== null && (!Number.isInteger(value.retryAfterSeconds) || value.retryAfterSeconds < 1 || value.retryAfterSeconds > 3600)) return { ok: false };
  return { ok: true, value: { code: value.code, retryable: value.retryable, retryAfterSeconds: value.retryAfterSeconds } };
}

export function validateWindow(value) {
  if (!exactKeys(value, ["status", "usedPercent", "remainingPercent", "resetsAt", "error"]) || !["ok", "error"].includes(value.status)) return { ok: false };
  const error = validateError(value.error);
  if (!error.ok) return { ok: false };
  if (value.status === "ok") {
    if (error.value !== null
        || clampPercent(value.usedPercent) === null || clampPercent(value.remainingPercent) === null
        || value.usedPercent !== clampPercent(value.usedPercent)
        || value.remainingPercent !== clampPercent(value.remainingPercent)
        || Math.abs(value.remainingPercent - (100 - value.usedPercent)) > 0.01
        || !validDate(value.resetsAt)) return { ok: false };
    return { ok: true, value: { status: "ok", usedPercent: clampPercent(value.usedPercent), remainingPercent: clampPercent(value.remainingPercent), resetsAt: value.resetsAt, error: null } };
  }
  if (error.value === null) return { ok: false };
  return { ok: true, value: { status: "error", usedPercent: null, remainingPercent: null, resetsAt: null, error: error.value } };
}

export function validateQuotaDocument(document, requiredProviders = PROVIDERS) {
  if (!exactKeys(document, ["schemaVersion", "observedAt", "providers"]) || document.schemaVersion !== 1 || !validDate(document.observedAt) || !document.providers) return { ok: false, errors: ["invalid quota document"] };
  if (!Object.keys(document.providers).every(id => PROVIDERS.includes(id)) || !requiredProviders.every(id => Object.prototype.hasOwnProperty.call(document.providers, id))) return { ok: false, errors: ["invalid quota providers"] };
  const providers = {};
  const errors = [];
  for (const id of requiredProviders) {
    const provider = document.providers[id];
    if (!exactOptionalKeys(provider, ["status", "lastUpdated", "fiveHour", "weekly", "error"], ["monthly"]) || !["ok", "error"].includes(provider.status) || (provider.lastUpdated !== null && typeof provider.lastUpdated !== "string") || !WINDOWS.every(name => provider[name])) { errors.push(`${id}: invalid provider`); continue; }
    const fiveHour = validateWindow(provider.fiveHour);
    const weekly = validateWindow(provider.weekly);
    const monthly = provider.monthly === undefined ? { ok: true, value: null } : validateWindow(provider.monthly);
    const providerError = validateError(provider.error);
    if (!fiveHour.ok || !weekly.ok || !monthly.ok || !providerError.ok) { errors.push(`${id}: invalid provider window`); continue; }
    if (provider.lastUpdated !== null && !validDate(provider.lastUpdated)) { errors.push(`${id}: invalid update time`); continue; }
    const hasWindowError = fiveHour.value.status === "error" || weekly.value.status === "error"
      || (monthly.value !== null && monthly.value.status === "error");
    if ((provider.status === "ok" && (providerError.value !== null || hasWindowError))
        || (provider.status === "error" && (providerError.value === null || !hasWindowError))) {
      errors.push(`${id}: status does not match windows`); continue;
    }
    const normalized = { status: provider.status, lastUpdated: provider.lastUpdated || null, fiveHour: fiveHour.value, weekly: weekly.value, error: providerError.value };
    if (monthly.value) normalized.monthly = monthly.value;
    providers[id] = normalized;
  }
  return errors.length ? { ok: false, errors } : { ok: true, value: { schemaVersion: 1, observedAt: document.observedAt, providers } };
}

export function validateAiQuotaState(document) {
  if (!document || document.schemaVersion !== 1 || !PROVIDERS.includes(document.selectedProvider)) return { ok: false, value: { schemaVersion: 1, selectedProvider: "openai" }, errors: ["invalid AI quota state"] };
  if (Object.keys(document).some(key => !["schemaVersion", "selectedProvider"].includes(key))) return { ok: false, value: { schemaVersion: 1, selectedProvider: "openai" }, errors: ["unsupported AI quota state property"] };
  return { ok: true, value: { schemaVersion: 1, selectedProvider: document.selectedProvider }, errors: [] };
}

export function formatReset(value) {
  if (!value) return "date unavailable";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "date unavailable";
  const day = date.getDate();
  const suffix = day % 100 >= 11 && day % 100 <= 13
    ? "th" : ({ 1: "st", 2: "nd", 3: "rd" }[day % 10] || "th");
  const hour = date.getHours();
  const hour12 = hour % 12 || 12;
  const minute = String(date.getMinutes()).padStart(2, "0");
  return `${["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][date.getDay()]} ${day}${suffix} ${["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][date.getMonth()]} at ${hour12}:${minute} ${hour < 12 ? "AM" : "PM"}`;
}

export function formatTimeUntil(value, now = Date.now()) {
  const remaining = new Date(value).getTime() - now;
  if (!Number.isFinite(remaining)) return "--";
  const minutes = Math.max(0, Math.ceil(remaining / 60000));
  const days = Math.floor(minutes / 1440);
  const hours = Math.floor((minutes % 1440) / 60);
  const mins = minutes % 60;
  if (days > 0) return `${days}d${hours > 0 ? ` ${hours}h` : ""}`;
  if (hours > 0) return `${hours}h ${mins}m`;
  return `${minutes}m`;
}

export function providerLabel(id) { return id === "opencode" ? "OpenCode Go" : "OpenAI"; }

// ----- provider state reducer -----
// Pure transforms that fold a refresh result (or failure) into the normalized
// provider map. Time is injected as epoch milliseconds so the retention and
// staleness rules are deterministic in tests.

export const STALE_AFTER_MS = 900000;

export function blankWindow() {
  return { status: "error", usedPercent: null, remainingPercent: null,
    resetsAt: null, error: null, freshness: "unknown", lastUpdated: null };
}

export function blankProvider(id) {
  return { id: id, label: providerLabel(id), availability: "unknown",
    freshness: "unknown", lastUpdated: null, lastAttempt: null, lastError: null,
    fiveHour: blankWindow(), weekly: blankWindow(), monthly: blankWindow() };
}

function providerOf(providers, id) {
  return providers[id] || blankProvider(id);
}

export function safeErrorSummary(code) {
  if (code === "AUTH_EXPIRED") return "Run an OpenCode request with an openai/... model to refresh the login";
  if (code === "AUTH_MISSING") return "OpenCode credentials are not configured";
  if (code === "NOT_ENTITLED") return "OpenCode Go is not enabled for this account";
  if (code === "RATE_LIMITED") return "Quota service rate limited";
  if (code === "UNAUTHORIZED") return "Provider authentication was rejected";
  return "Provider quota is temporarily unavailable";
}

export function providerError(code, now) {
  const retryable = ["TIMEOUT", "NETWORK_ERROR", "RATE_LIMITED", "AUTH_EXPIRED"].indexOf(code) !== -1;
  return { code: code, boundary: "ai-quota", summary: safeErrorSummary(code), detail: "",
    timestamp: new Date(now), retryable: retryable, operationId: null };
}

export function publishProviderFailure(providers, providerId, code, now) {
  const next = Object.assign({}, providers);
  (providerId ? [providerId] : PROVIDERS).forEach(id => {
    const current = providerOf(providers, id);
    const age = current.lastUpdated instanceof Date ? now - current.lastUpdated.getTime() : Infinity;
    const hasValue = current.fiveHour.status === "ok" || current.weekly.status === "ok";
    const stale = hasValue && age >= STALE_AFTER_MS;
    const failure = providerError(code, now);
    const windows = {};
    ["fiveHour", "weekly", "monthly"].forEach(name => {
      windows[name] = Object.assign({}, current[name], {
        error: failure,
        freshness: hasValue && current[name].status === "ok" ? (stale ? "stale" : "current") : current[name].freshness
      });
    });
    next[id] = Object.assign({}, current, {
      availability: hasValue ? "degraded" : "unavailable",
      freshness: hasValue ? (stale ? "stale" : "current") : "unknown",
      lastAttempt: new Date(now),
      lastError: failure
    }, windows);
  });
  return next;
}

export function mergeQuotaResult(providers, result, now) {
  if (!result.ok) return publishProviderFailure(providers, result.providerId, result.error, now);
  const next = Object.assign({}, providers);
  const ids = result.providerId ? [result.providerId] : PROVIDERS;
  ids.forEach(id => {
    const source = result.data.providers[id];
    const current = providerOf(providers, id);
    const goodFiveHour = source.fiveHour.status === "ok";
    const goodWeekly = source.weekly.status === "ok";
    const hasMonthly = source.monthly !== undefined;
    const goodMonthly = hasMonthly && source.monthly.status === "ok";
    const retainedFiveHour = current.fiveHour.status === "ok";
    const retainedWeekly = current.weekly.status === "ok";
    const retainedMonthly = current.monthly.status === "ok";
    const hasValue = goodFiveHour || goodWeekly || goodMonthly || retainedFiveHour || retainedWeekly || retainedMonthly;
    const sourceUpdated = (goodFiveHour || goodWeekly || goodMonthly)
      ? new Date(source.lastUpdated || result.data.observedAt) : current.lastUpdated;
    const stale = hasValue && sourceUpdated instanceof Date
      && now - sourceUpdated.getTime() >= STALE_AFTER_MS;
    const updateTime = (goodFiveHour || goodWeekly || goodMonthly)
      ? new Date(source.lastUpdated || result.data.observedAt) : null;
    const fiveHourAge = current.fiveHour.lastUpdated instanceof Date ? now - current.fiveHour.lastUpdated.getTime() : Infinity;
    const weeklyAge = current.weekly.lastUpdated instanceof Date ? now - current.weekly.lastUpdated.getTime() : Infinity;
    const monthlyAge = current.monthly.lastUpdated instanceof Date ? now - current.monthly.lastUpdated.getTime() : Infinity;
    const fiveHour = goodFiveHour
      ? Object.assign({}, source.fiveHour, { freshness: "current", lastUpdated: updateTime })
      : (retainedFiveHour
        ? Object.assign({}, current.fiveHour, { error: providerError(source.fiveHour.error?.code || "NETWORK_ERROR", now), freshness: fiveHourAge >= STALE_AFTER_MS ? "stale" : "current" })
        : source.fiveHour);
    const weekly = goodWeekly
      ? Object.assign({}, source.weekly, { freshness: "current", lastUpdated: updateTime })
      : (retainedWeekly
        ? Object.assign({}, current.weekly, { error: providerError(source.weekly.error?.code || "NETWORK_ERROR", now), freshness: weeklyAge >= STALE_AFTER_MS ? "stale" : "current" })
        : source.weekly);
    const monthly = hasMonthly
      ? (goodMonthly
        ? Object.assign({}, source.monthly, { freshness: "current", lastUpdated: updateTime })
        : (retainedMonthly
          ? Object.assign({}, current.monthly, { error: providerError(source.monthly.error?.code || "NETWORK_ERROR", now), freshness: monthlyAge >= STALE_AFTER_MS ? "stale" : "current" })
          : source.monthly))
      : current.monthly;
    next[id] = Object.assign({}, current, {
      availability: goodFiveHour && goodWeekly && (!hasMonthly || goodMonthly)
        ? "available" : (hasValue ? "degraded" : "unavailable"),
      freshness: hasValue
        ? ((stale || fiveHour.freshness === "stale" || weekly.freshness === "stale" || monthly.freshness === "stale") ? "stale" : "current")
        : "unknown",
      lastUpdated: sourceUpdated,
      lastAttempt: new Date(now),
      lastError: source.error ? providerError(source.error.code, now) : null,
      fiveHour: fiveHour,
      weekly: weekly,
      monthly: monthly
    });
  });
  return next;
}

export function markProvidersStale(providers, now) {
  const next = Object.assign({}, providers);
  PROVIDERS.forEach(id => {
    const current = providerOf(providers, id);
    if (current.lastUpdated instanceof Date && now - current.lastUpdated.getTime() >= STALE_AFTER_MS
        && (current.fiveHour.status === "ok" || current.weekly.status === "ok")) {
      next[id] = Object.assign({}, current, {
        availability: "degraded", freshness: "stale",
        fiveHour: Object.assign({}, current.fiveHour, current.fiveHour.status === "ok" ? { freshness: "stale" } : {}),
        weekly: Object.assign({}, current.weekly, current.weekly.status === "ok" ? { freshness: "stale" } : {}),
        monthly: Object.assign({}, current.monthly, current.monthly.status === "ok" ? { freshness: "stale" } : {})
      });
    }
  });
  return next;
}
