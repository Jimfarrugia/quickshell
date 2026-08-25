import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { themeTokenNames, validateConfig, validateTheme, validateThemeState, truncateUtf8 } from "../../utils/Validation.mjs";

const fixture = async path => JSON.parse(await readFile(new URL(`../fixtures/${path}`, import.meta.url), "utf8"));

const expectedThemeTokens = [
  "background", "on_background", "surface", "on_surface", "surface_variant", "on_surface_variant",
  "surface_panel", "on_surface_panel", "surface_tooltip", "on_surface_tooltip", "surface_hover",
  "surface_pressed", "primary", "on_primary", "primary_container", "on_primary_container", "secondary",
  "on_secondary", "outline", "outline_variant", "focus_ring", "on_surface_disabled",
  "on_surface_placeholder", "link", "highlight", "on_highlight", "success", "charging", "warning",
  "error", "shadow", "scrim"
];

function contrastRatio(first, second) {
  function luminance(color) {
    const channels = color.slice(1).match(/../g).map(value => Number.parseInt(value, 16) / 255)
      .map(value => value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4);
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
  }
  const firstLuminance = luminance(first);
  const secondLuminance = luminance(second);
  return (Math.max(firstLuminance, secondLuminance) + 0.05)
    / (Math.min(firstLuminance, secondLuminance) + 0.05);
}

function compositeArgb(color, background) {
  if (color.length === 7) return color;
  const alpha = Number.parseInt(color.slice(1, 3), 16) / 255;
  const foregroundChannels = color.slice(3).match(/../g).map(value => Number.parseInt(value, 16));
  const backgroundChannels = background.slice(1).match(/../g).map(value => Number.parseInt(value, 16));
  const channels = foregroundChannels.map((value, index) => Math.round(value * alpha + backgroundChannels[index] * (1 - alpha)));
  return `#${channels.map(value => value.toString(16).padStart(2, "0")).join("")}`;
}

assert.deepEqual(themeTokenNames(), expectedThemeTokens);

for (const path of ["../../config/qe.json", "../../themes/poimandres.json", "../../themes/gruvbox.json"])
  JSON.parse(await readFile(new URL(path, import.meta.url), "utf8"));

const validConfig = validateConfig(await fixture("config/valid.json"));
assert.equal(validConfig.ok, true);
assert.equal(validConfig.value.bar.brightnessEnabled, true);
const invalidBrightness = validateConfig({ schemaVersion: 1, bar: { brightnessEnabled: "yes" } });
assert.equal(invalidBrightness.value.bar.brightnessEnabled, true);
assert.match(invalidBrightness.errors.join(" "), /brightnessEnabled/);
const invalidBluetooth = validateConfig({ schemaVersion: 1, bar: { bluetoothEnabled: "yes" } });
assert.equal(invalidBluetooth.value.bar.bluetoothEnabled, true);
assert.match(invalidBluetooth.errors.join(" "), /bluetoothEnabled/);
const invalidIdle = validateConfig({ schemaVersion: 1, bar: { idleInhibitorEnabled: "yes" } });
assert.equal(invalidIdle.value.bar.idleInhibitorEnabled, true);
assert.match(invalidIdle.errors.join(" "), /idleInhibitorEnabled/);
const fieldFallback = validateConfig(await fixture("config/invalid-field.json"));
assert.equal(fieldFallback.ok, true);
assert.equal(fieldFallback.value.defaultTheme, "poimandres");
assert.ok(fieldFallback.errors.length >= 2);
assert.equal(validateConfig(await fixture("config/invalid-root.json")).ok, false);

for (const path of ["../../themes/poimandres.json", "../../themes/gruvbox.json", "../fixtures/themes/valid.json"]) {
  const result = validateTheme(JSON.parse(await readFile(new URL(path, import.meta.url), "utf8")));
  assert.equal(result.ok, true, `${path}: ${result.errors.join("; ")}`);
}
const poimandres = validateTheme(JSON.parse(await readFile(new URL("../../themes/poimandres.json", import.meta.url), "utf8")));
assert.equal(poimandres.value.tokens.surface_tooltip, "#171922");
assert.equal(poimandres.value.tokens.outline, "#8290a5");
assert.equal(poimandres.value.tokens.on_primary, "#171922");
const gruvbox = validateTheme(JSON.parse(await readFile(new URL("../../themes/gruvbox.json", import.meta.url), "utf8")));
assert.equal(gruvbox.value.tokens.surface_tooltip, "#3c3836");
assert.equal(gruvbox.value.tokens.outline, "#b8a98a");
assert.equal(gruvbox.value.tokens.on_primary_container, "#32302f");
for (const theme of [poimandres.value, gruvbox.value]) {
  for (const [surface, foreground] of [
    ["background", "on_background"], ["surface", "on_surface"],
    ["surface_variant", "on_surface_variant"], ["surface_tooltip", "on_surface_tooltip"],
    ["primary", "on_primary"], ["primary_container", "on_primary_container"],
    ["secondary", "on_secondary"], ["highlight", "on_highlight"]
  ]) {
    assert.ok(contrastRatio(theme.tokens[surface], theme.tokens[foreground]) >= 4.5,
      `${theme.id}: ${foreground} must contrast with ${surface}`);
  }
  assert.ok(contrastRatio(theme.tokens.surface, theme.tokens.outline) >= 3,
    `${theme.id}: outline must contrast with surface`);
  assert.ok(contrastRatio(theme.tokens.surface, theme.tokens.focus_ring) >= 3,
    `${theme.id}: focus_ring must contrast with surface`);
  const compositedPanel = compositeArgb(theme.tokens.surface_panel, theme.tokens.background);
  assert.ok(contrastRatio(compositedPanel, theme.tokens.on_surface_panel) >= 4.5,
    `${theme.id}: on_surface_panel must contrast with surface_panel over background`);
}
assert.equal(validateTheme(await fixture("themes/missing-token.json")).ok, false);
const emptyPalette = await fixture("themes/valid.json");
emptyPalette.palette = {};
assert.equal(validateTheme(emptyPalette).ok, false);
assert.match(validateTheme(await fixture("themes/cycle.json")).errors.join(" "), /cycle/);
assert.equal(validateThemeState(await fixture("state/valid.json")).ok, true);
assert.equal(validateThemeState(await fixture("state/invalid.json")).ok, false);
assert.deepEqual(truncateUtf8("abcd", 3), { text: "abc", truncated: true });

console.log("validation fixtures passed");
