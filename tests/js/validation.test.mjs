import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { validateConfig, validateTheme, validateThemeState, truncateUtf8 } from "../../utils/Validation.mjs";

const fixture = async path => JSON.parse(await readFile(new URL(`../fixtures/${path}`, import.meta.url), "utf8"));

for (const path of ["../../config/qe.json", "../../themes/poimandres.json", "../../themes/gruvbox.json"])
  JSON.parse(await readFile(new URL(path, import.meta.url), "utf8"));

assert.equal(validateConfig(await fixture("config/valid.json")).ok, true);
const fieldFallback = validateConfig(await fixture("config/invalid-field.json"));
assert.equal(fieldFallback.ok, true);
assert.equal(fieldFallback.value.defaultTheme, "poimandres");
assert.ok(fieldFallback.errors.length >= 2);
assert.equal(validateConfig(await fixture("config/invalid-root.json")).ok, false);

for (const path of ["../../themes/poimandres.json", "../../themes/gruvbox.json", "../fixtures/themes/valid.json"]) {
  const result = validateTheme(JSON.parse(await readFile(new URL(path, import.meta.url), "utf8")));
  assert.equal(result.ok, true, `${path}: ${result.errors.join("; ")}`);
}
assert.equal(validateTheme(await fixture("themes/missing-token.json")).ok, false);
assert.match(validateTheme(await fixture("themes/cycle.json")).errors.join(" "), /cycle/);
assert.equal(validateThemeState(await fixture("state/valid.json")).ok, true);
assert.equal(validateThemeState(await fixture("state/invalid.json")).ok, false);
assert.deepEqual(truncateUtf8("abcd", 3), { text: "abc", truncated: true });

console.log("validation fixtures passed");
