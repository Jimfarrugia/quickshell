import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { themeTokenNames, validateConfig, validateDefaultsManifest, validateTheme, validateThemeState, validateNotificationState, validateIdleInhibitorState, truncateUtf8 } from "../../utils/Validation.mjs";
import { normalizeNotification, sanitizeMarkup, shouldKeepHistory, shouldShowPopup } from "../../utils/Notifications.mjs";

const fixture = async path => JSON.parse(await readFile(new URL(`../fixtures/${path}`, import.meta.url), "utf8"));

const expectedThemeTokens = [
  "background", "on_background", "surface", "on_surface", "surface_variant", "on_surface_variant",
  "surface_panel", "surface_sidebar", "surface_low", "on_surface_panel", "surface_tooltip", "on_surface_tooltip", "surface_hover",
  "surface_pressed", "primary", "on_primary", "primary_container", "on_primary_container", "secondary",
  "on_secondary", "outline", "outline_variant", "focus_ring", "on_surface_disabled",
  "on_surface_placeholder", "link", "highlight", "on_highlight", "success", "warning", "error",
  "shadow", "scrim", "charging"
];

function contrastRatio(first, second) {
  const firstLuminance = relativeLuminance(first);
  const secondLuminance = relativeLuminance(second);
  return (Math.max(firstLuminance, secondLuminance) + 0.05)
    / (Math.min(firstLuminance, secondLuminance) + 0.05);
}

function relativeLuminance(color) {
  const channels = color.slice(1).match(/../g).map(value => Number.parseInt(value, 16) / 255)
    .map(value => value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4);
  return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
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
assert.ok(fieldFallback.errors.length >= 2);
assert.equal(validateConfig(await fixture("config/invalid-root.json")).ok, false);
assert.equal(validateConfig({ schemaVersion: 1, notifications: { enabled: true, historyLimit: 30 } }).value.notifications.historyLimit, 30);
assert.equal(validateConfig({ schemaVersion: 1, notifications: { maxActions: 99 } }).value.notifications.maxActions, 8);
assert.deepEqual(validateDefaultsManifest({ schemaVersion: 1, defaultTheme: "wallpaper" }), {
  ok: true,
  value: { schemaVersion: 1, defaultTheme: "wallpaper" },
  errors: []
});
assert.equal(validateDefaultsManifest({ schemaVersion: 1, defaultTheme: "Not Valid" }).ok, false);
assert.equal(validateDefaultsManifest({ schemaVersion: 1, defaultTheme: "poimandres", extra: true }).ok, false);

for (const path of ["../../themes/poimandres.json", "../../themes/gruvbox.json", "../fixtures/themes/valid.json"]) {
  const result = validateTheme(JSON.parse(await readFile(new URL(path, import.meta.url), "utf8")));
  assert.equal(result.ok, true, `${path}: ${result.errors.join("; ")}`);
}
const poimandres = validateTheme(JSON.parse(await readFile(new URL("../../themes/poimandres.json", import.meta.url), "utf8")));
const poimandresSource = JSON.parse(await readFile(new URL("../../themes/poimandres.json", import.meta.url), "utf8"));
assert.deepEqual(Object.keys(poimandres.value.palette), Object.keys(poimandresSource.palette));
assert.equal(Object.keys(poimandres.value.tokens).at(-1), "charging");
assert.equal(poimandres.value.tokens.surface_sidebar, "#171922");
assert.equal(poimandres.value.tokens.surface_low, "#171922");
assert.equal(poimandres.value.tokens.surface_tooltip, "#171922");
assert.equal(poimandres.value.tokens.on_surface_tooltip, "#8290a5");
assert.equal(poimandres.value.tokens.surface, "#1b1e28");
assert.equal(poimandres.value.tokens.surface_variant, "#303340");
assert.equal(poimandres.value.tokens.surface_hover, "#41434f");
assert.equal(poimandres.value.tokens.outline_variant, "#506477");
assert.equal(poimandres.value.tokens.outline, "#767c9d");
assert.equal(poimandres.value.tokens.on_primary, "#171922");
const gruvbox = validateTheme(JSON.parse(await readFile(new URL("../../themes/gruvbox.json", import.meta.url), "utf8")));
assert.equal(Object.keys(gruvbox.value.tokens).at(-1), "charging");
assert.equal(gruvbox.value.palette.sidebar, "#1d2021");
assert.equal(gruvbox.value.tokens.surface_sidebar, "#1d2021");
assert.equal(gruvbox.value.tokens.surface_low, "#1d2021");
assert.equal(gruvbox.value.tokens.surface_tooltip, "#3c3836");
assert.equal(gruvbox.value.tokens.surface_hover, "#504945");
assert.equal(gruvbox.value.tokens.surface_pressed, "#458588");
assert.equal(gruvbox.value.tokens.outline, "#928374");
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
  const compositedSidebar = compositeArgb(theme.tokens.surface_sidebar, theme.tokens.background);
  assert.ok(relativeLuminance(compositedSidebar) < relativeLuminance(theme.tokens.background),
    `${theme.id}: surface_sidebar must be darker than background`);
}
assert.equal(validateTheme(await fixture("themes/missing-token.json")).ok, false);
const emptyPalette = await fixture("themes/valid.json");
emptyPalette.palette = {};
assert.equal(validateTheme(emptyPalette).ok, false);
assert.match(validateTheme(await fixture("themes/cycle.json")).errors.join(" "), /cycle/);
assert.equal(validateThemeState(await fixture("state/valid.json")).ok, true);
assert.equal(validateThemeState(await fixture("state/invalid.json")).ok, false);
assert.deepEqual(validateNotificationState({ schemaVersion: 1, dnd: true }), {
  ok: true, value: { schemaVersion: 1, dnd: true }, errors: []
});
assert.equal(validateNotificationState({ schemaVersion: 1, dnd: "yes" }).ok, false);
assert.deepEqual(validateIdleInhibitorState({ schemaVersion: 1, requested: true }), {
  ok: true,
  value: { schemaVersion: 1, requested: true },
  errors: []
});
assert.equal(validateIdleInhibitorState({ schemaVersion: 1, requested: "yes" }).ok, false);
assert.deepEqual(truncateUtf8("abcd", 3), { text: "abc", truncated: true });

assert.equal(sanitizeMarkup("<b>safe</b><script>bad</script><a href='x'>link</a>"), "<b>safe</b>badlink");
const notification = normalizeNotification({
  id: 7,
  appName: "Fixture",
  summary: "Summary",
  body: "<i>Body</i>",
  urgency: 2,
  actions: [{ identifier: "open", text: "Open" }, { identifier: "", text: "Discard" }],
  image: "https://example.invalid/image.png",
  hints: { value: 45 }
});
assert.equal(notification.urgency, "critical");
assert.equal(notification.body, "<i>Body</i>");
assert.equal(notification.actions.length, 1);
assert.equal(notification.image, "");
assert.equal(normalizeNotification({ appIcon: "dialog-information" }).image, "image://icon/dialog-information");
const qeDefaultsNotification = normalizeNotification({ appName: "qe-defaults" });
assert.equal(qeDefaultsNotification.image, "");
assert.equal(qeDefaultsNotification.iconName, "colors");
assert.equal(notification.progress, 45);
assert.equal(shouldShowPopup(notification, true), true);
assert.equal(shouldKeepHistory(notification, true), true);
assert.equal(shouldKeepHistory({ transient: true }, true), false);

console.log("validation fixtures passed");
