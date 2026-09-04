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
    if (clampPercent(value.usedPercent) === null || clampPercent(value.remainingPercent) === null
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
    if (provider.status === "ok" && (providerError.value !== null || fiveHour.value.status !== "ok" || weekly.value.status !== "ok")) { errors.push(`${id}: status does not match windows`); continue; }
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
  if (days > 0) return `${days}d${hours > 0 ? ` ${hours}h` : ""}`;
  if (hours > 0) return `${hours}h`;
  return `${minutes}m`;
}

export function providerLabel(id) { return id === "opencode" ? "OpenCode Go" : "OpenAI"; }
