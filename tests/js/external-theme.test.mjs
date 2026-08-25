import assert from "node:assert/strict";
import { validateExternalThemeResult } from "../../utils/ExternalTheme.mjs";

const valid = {
  schema: "theme-switcher",
  version: 1,
  mode: "machine",
  requestedTheme: "gruvbox",
  skipGtk: false,
  status: "partial",
  timestamp: "2026-08-25T12:00:00Z",
  persisted: true,
  error: null,
  results: [
    { target: "gtk", status: "applied", exitCode: 0, reason: null, detail: null },
    { target: "waybar", status: "skipped", exitCode: null, reason: "retired", detail: null },
    { target: "nvim", status: "failed", exitCode: 1, reason: null, detail: "failed" }
  ]
};

assert.equal(validateExternalThemeResult(valid, "gruvbox", 3).ok, true);
assert.equal(validateExternalThemeResult(valid, "poimandres", 3).ok, false);
assert.equal(validateExternalThemeResult(valid, "gruvbox", 0).ok, false);
assert.equal(validateExternalThemeResult({ ...valid, status: "success", persisted: false }, "gruvbox", 0).ok, false);
assert.equal(validateExternalThemeResult({ ...valid, status: "success" }, "gruvbox", 0).ok, false);
assert.equal(validateExternalThemeResult({ ...valid, status: "partial", results: valid.results.slice(0, 2) }, "gruvbox", 3).ok, false);
assert.equal(validateExternalThemeResult({ ...valid, status: "failed" }, "gruvbox", 4).ok, false);
assert.equal(validateExternalThemeResult({ ...valid, skipGtk: "false" }, "gruvbox", 3).ok, false);
assert.equal(validateExternalThemeResult({ ...valid, timestamp: "yesterday" }, "gruvbox", 3).ok, false);
assert.equal(validateExternalThemeResult({ ...valid, error: 4 }, "gruvbox", 3).ok, false);
assert.equal(validateExternalThemeResult({ ...valid, status: "success", results: valid.results.slice(0, 2), error: "contradiction" }, "gruvbox", 0).ok, false);
assert.equal(validateExternalThemeResult({ ...valid, status: "failed", persisted: false, results: [], error: null }, "gruvbox", 4).ok, false);
assert.equal(validateExternalThemeResult({ ...valid, results: valid.results.concat(valid.results[0]) }, "gruvbox", 3).ok, false);
assert.equal(validateExternalThemeResult({ ...valid, results: [{ ...valid.results[0], exitCode: 1 }] }, "gruvbox", 3).ok, false);
assert.equal(validateExternalThemeResult({ ...valid, results: [{ ...valid.results[1], reason: "unknown" }] }, "gruvbox", 3).ok, false);
assert.equal(validateExternalThemeResult(null).ok, false);

console.log("external-theme fixtures passed");
