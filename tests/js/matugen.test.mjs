import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { mapMatugenTheme } from "../../utils/Matugen.mjs";

const fixture = JSON.parse(await readFile(new URL("../fixtures/matugen/dark.json", import.meta.url), "utf8"));
const result = mapMatugenTheme(fixture, "dark");

assert.equal(result.ok, true, result.errors.join("; "));
assert.equal(result.value.id, "wallpaper");
assert.equal(result.value.tokens.surface_panel, "#ff101820");
assert.equal(result.value.tokens.surface_sidebar, "#ff0a0f14");
const translucent = mapMatugenTheme(fixture, "dark", { kittyOpacity: 0.96, hyprlandActiveOpacity: 0.95 });
assert.equal(translucent.value.tokens.surface_panel, "#e9101820");
assert.equal(translucent.value.tokens.surface_sidebar, "#e90a0f14");
assert.equal(mapMatugenTheme(fixture, "dark", { kittyOpacity: "invalid" }).value.tokens.surface_panel, "#ff101820");
assert.equal(result.value.tokens.scrim, "#99000000");
assert.equal(result.value.tokens.shadow, "#80000000");
assert.equal(result.value.tokens.highlight, "#513a5e");
assert.equal(result.value.tokens.on_highlight, "#f2daff");
assert.equal(result.value.tokens.success, "#d5bce5");

const actualV4 = JSON.parse(await readFile(new URL("../fixtures/matugen/actual-v4.json", import.meta.url), "utf8"));
const actualResult = mapMatugenTheme(actualV4, "dark");
assert.equal(actualResult.ok, true, actualResult.errors.join("; "));
assert.equal(actualResult.value.tokens.primary, "#9ecaff");

assert.equal(mapMatugenTheme({}, "dark").ok, false);
assert.equal(mapMatugenTheme(fixture, "sepia").ok, false);
const missing = structuredClone(fixture);
delete missing.colors.dark.primary;
assert.equal(mapMatugenTheme(missing, "dark").ok, false);

console.log("matugen fixtures passed");
