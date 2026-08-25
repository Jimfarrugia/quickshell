const THEME_ID_PATTERN = /^[a-z0-9]+(?:_[a-z0-9]+)*$/;
const RESULT_STATUSES = ["applied", "skipped", "failed"];
const OPERATION_STATUSES = ["success", "partial", "failed"];
const SKIP_REASONS = ["retired", "optional_gtk_skip"];
const RFC3339_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$/;

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

export function isExternalThemeId(value) {
  return typeof value === "string" && THEME_ID_PATTERN.test(value);
}

export function validateExternalThemeResult(document, requestedThemeId = "", exitCode = null) {
  const errors = [];
  if (!isObject(document))
    return { ok: false, errors: ["external theme result: root must be an object"], value: null };
  if (document.schema !== "theme-switcher") errors.push("external theme result.schema: expected 'theme-switcher'");
  if (document.version !== 1) errors.push("external theme result.version: expected 1");
  if (document.mode !== "machine") errors.push("external theme result.mode: expected 'machine'");
  if (!isExternalThemeId(document.requestedTheme))
    errors.push("external theme result.requestedTheme: expected a normalized theme ID");
  if (requestedThemeId && document.requestedTheme !== requestedThemeId)
    errors.push("external theme result.requestedTheme: does not match the request");
  if (!OPERATION_STATUSES.includes(document.status))
    errors.push("external theme result.status: unsupported status");
  if (typeof document.skipGtk !== "boolean")
    errors.push("external theme result.skipGtk: expected a boolean");
  if (typeof document.timestamp !== "string" || !RFC3339_PATTERN.test(document.timestamp)
      || Number.isNaN(Date.parse(document.timestamp)))
    errors.push("external theme result.timestamp: expected an RFC 3339 UTC timestamp");
  if (typeof document.persisted !== "boolean")
    errors.push("external theme result.persisted: expected a boolean");
  if (document.error !== null && typeof document.error !== "string")
    errors.push("external theme result.error: expected a string or null");
  if (!Array.isArray(document.results)) errors.push("external theme result.results: expected an array");

  const results = [];
  const targets = new Set();
  if (Array.isArray(document.results)) {
    for (const [index, result] of document.results.entries()) {
      const prefix = `external theme result.results[${index}]`;
      if (!isObject(result)) {
        errors.push(`${prefix}: expected an object`);
        continue;
      }
      if (typeof result.target !== "string" || !/^[a-z0-9_-]+$/.test(result.target))
        errors.push(`${prefix}.target: expected a normalized target ID`);
      else if (targets.has(result.target)) errors.push(`${prefix}.target: duplicate target ID`);
      else targets.add(result.target);
      if (!RESULT_STATUSES.includes(result.status)) errors.push(`${prefix}.status: unsupported status`);
      if (result.exitCode !== null && !Number.isInteger(result.exitCode))
        errors.push(`${prefix}.exitCode: expected an integer or null`);
      if (result.reason !== null && typeof result.reason !== "string")
        errors.push(`${prefix}.reason: expected a string or null`);
      if (result.detail !== null && typeof result.detail !== "string")
        errors.push(`${prefix}.detail: expected a string or null`);
      if (typeof result.detail === "string" && result.detail.length > 2000)
        errors.push(`${prefix}.detail: exceeds 2000 characters`);
      if (result.status === "applied" && result.exitCode !== 0)
        errors.push(`${prefix}.exitCode: applied targets must exit 0`);
      if (result.status === "skipped" && result.exitCode !== null)
        errors.push(`${prefix}.exitCode: skipped targets must use null`);
      if (result.status === "failed" && (!Number.isInteger(result.exitCode) || result.exitCode === 0))
        errors.push(`${prefix}.exitCode: failed targets require a non-zero exit code`);
      if (result.status === "skipped" && !SKIP_REASONS.includes(result.reason))
        errors.push(`${prefix}.reason: skipped targets require a supported reason`);
      if (result.status !== "skipped" && result.reason !== null)
        errors.push(`${prefix}.reason: only skipped targets may have a reason`);
      if (result.status !== "failed" && result.detail !== null)
        errors.push(`${prefix}.detail: only failed targets may have detail`);
      results.push({
        target: result.target,
        status: result.status,
        exitCode: result.exitCode,
        reason: result.reason,
        detail: result.detail
      });
    }
  }

  if (document.status === "success" && document.persisted !== true)
    errors.push("external theme result: success requires persisted state");
  if (document.status === "success" && document.error !== null)
    errors.push("external theme result: success cannot contain an error");
  if (document.status === "failed" && Array.isArray(document.results)
      && document.results.length === 0 && !(typeof document.error === "string" && document.error.length > 0))
    errors.push("external theme result: a pre-apply failure requires an error");
  if (Array.isArray(document.results)) {
    const applied = document.results.filter(result => isObject(result) && result.status === "applied").length;
    const failed = document.results.filter(result => isObject(result) && result.status === "failed").length;
    if (document.status === "success" && failed > 0)
      errors.push("external theme result: success cannot contain failed targets");
    if (document.status === "partial" && !(applied > 0 && (failed > 0 || document.persisted === false)))
      errors.push("external theme result: partial requires an applied target and a target or persistence failure");
    if (document.status === "failed" && applied > 0)
      errors.push("external theme result: failed cannot contain applied targets");
  }
  if (exitCode !== null) {
    const expectedExit = document.status === "success" ? 0 : document.status === "partial" ? 3 : 4;
    if (exitCode !== expectedExit)
      errors.push(`external theme result: status '${document.status}' requires exit ${expectedExit}`);
  }

  return {
    ok: errors.length === 0,
    errors,
    value: errors.length === 0 ? {
      schema: "theme-switcher",
      version: 1,
      mode: "machine",
      requestedTheme: document.requestedTheme,
      skipGtk: document.skipGtk,
      status: document.status,
      timestamp: document.timestamp,
      persisted: document.persisted,
      error: typeof document.error === "string" ? document.error : null,
      results
    } : null
  };
}
