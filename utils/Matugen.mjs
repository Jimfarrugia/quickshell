import { validateTheme } from "./Validation.mjs";
import { alphaHex } from "./Opacity.mjs";

const COLOR_PATTERN = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/;
const REQUIRED_COLORS = [
  "background", "on_background", "surface", "on_surface", "surface_container",
  "surface_variant",
  "on_surface_variant", "primary", "on_primary", "primary_container",
  "on_primary_container", "secondary", "on_secondary", "secondary_container",
  "on_secondary_container", "outline", "outline_variant", "error"
];
const SIDEBAR_LIGHTNESS_DELTA = 9 / 255;

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function colorAt(colors, key, variant, fallback = null) {
  const value = colors[key] ?? (fallback === null ? null : colors[fallback]);
  if (typeof value === "string" && COLOR_PATTERN.test(value)) return value.toLowerCase();
  if (!isObject(value)) return null;
  const variantValue = value[variant] ?? value.default;
  if (!isObject(variantValue) || typeof variantValue.color !== "string" || !COLOR_PATTERN.test(variantValue.color))
    return null;
  return variantValue.color.toLowerCase();
}

function withAlpha(color, alpha) {
  return color.length === 7 ? `#${alpha}${color.slice(1)}` : color;
}

function darkenHsl(hex, lightnessDelta) {
  const [red, green, blue] = hex.slice(1, 7).match(/../g).map(value => Number.parseInt(value, 16) / 255);
  const maximum = Math.max(red, green, blue);
  const minimum = Math.min(red, green, blue);
  const lightness = (maximum + minimum) / 2;
  const chroma = maximum - minimum;
  const saturation = chroma === 0 ? 0 : chroma / (1 - Math.abs(2 * lightness - 1));
  let hue = 0;
  if (chroma !== 0) {
    if (maximum === red) hue = ((green - blue) / chroma) % 6;
    else if (maximum === green) hue = (blue - red) / chroma + 2;
    else hue = (red - green) / chroma + 4;
    hue /= 6;
    if (hue < 0) hue += 1;
  }

  const nextLightness = Math.max(0, lightness - lightnessDelta);
  const nextChroma = (1 - Math.abs(2 * nextLightness - 1)) * saturation;
  const second = nextLightness - nextChroma / 2;
  const huePrime = hue * 6;
  const x = nextChroma * (1 - Math.abs((huePrime % 2) - 1));
  let redPrime = 0;
  let greenPrime = 0;
  let bluePrime = 0;
  if (huePrime < 1) [redPrime, greenPrime] = [nextChroma, x];
  else if (huePrime < 2) [redPrime, greenPrime] = [x, nextChroma];
  else if (huePrime < 3) [greenPrime, bluePrime] = [nextChroma, x];
  else if (huePrime < 4) [greenPrime, bluePrime] = [x, nextChroma];
  else if (huePrime < 5) [redPrime, bluePrime] = [x, nextChroma];
  else [redPrime, bluePrime] = [nextChroma, x];

  return `#${[redPrime + second, greenPrime + second, bluePrime + second]
    .map(value => Math.round(value * 255).toString(16).padStart(2, "0")).join("")}`;
}

export function mapMatugenTheme(document, variant = "dark", opacitySnapshot = null) {
  const errors = [];
  if (!isObject(document))
    return { ok: false, errors: ["matugen: root must be an object"], value: null };
  if (!isObject(document.colors))
    return { ok: false, errors: ["matugen.colors: expected an object"], value: null };
  if (variant !== "dark" && variant !== "light")
    return { ok: false, errors: ["matugen variant: expected 'dark' or 'light'"], value: null };

  const colors = isObject(document.colors[variant]) && !isObject(document.colors[variant].background)
    ? document.colors[variant] : document.colors;

  for (const key of REQUIRED_COLORS) {
    if (colorAt(colors, key, variant) === null)
      errors.push(`matugen.colors.${key}.${variant}: expected a hex color`);
  }
  if (errors.length > 0) return { ok: false, errors, value: null };

  const color = (key, fallback) => colorAt(colors, key, variant, fallback);
  const sidebarBackground = darkenHsl(color("background"), SIDEBAR_LIGHTNESS_DELTA);
  const palette = {};
  for (const [key, value] of Object.entries(colors)) {
    const resolved = colorAt(colors, key, variant);
    if (resolved !== null) palette[key] = resolved;
  }
  palette.shadow = color("shadow") || "#000000";
  palette.scrim = color("scrim") || "#000000";

  const rawTheme = {
    schemaVersion: 1,
    id: "wallpaper",
    name: "Wallpaper",
    variant,
    palette,
    tokens: {
      background: color("background"),
      on_background: color("on_background"),
      surface: color("surface"),
      on_surface: color("on_surface"),
      surface_variant: color("surface_container"),
      on_surface_variant: color("on_surface_variant"),
      surface_panel: withAlpha(color("background"), alphaHex(opacitySnapshot)),
      surface_sidebar: sidebarBackground,
      surface_low: sidebarBackground,
      on_surface_panel: color("on_surface"),
      surface_tooltip: color("surface_variant"),
      on_surface_tooltip: color("on_surface_variant"),
      surface_hover: color("surface_variant"),
      surface_pressed: color("primary_container"),
      primary: color("primary"),
      on_primary: color("on_primary"),
      primary_container: color("primary_container"),
      on_primary_container: color("on_primary_container"),
      secondary: color("secondary"),
      on_secondary: color("on_secondary"),
      outline: color("outline"),
      outline_variant: color("outline_variant"),
      focus_ring: color("primary"),
      on_surface_disabled: color("on_surface_variant"),
      on_surface_placeholder: color("on_surface_variant"),
      link: color("primary"),
      highlight: color("tertiary_container", "secondary_container"),
      on_highlight: color("on_tertiary_container", "on_secondary_container"),
      success: color("tertiary", "secondary"),
      charging: color("tertiary", "primary"),
      warning: color("tertiary", "error"),
      error: color("error"),
      shadow: withAlpha(palette.shadow, "80"),
      scrim: withAlpha(palette.scrim, "99")
    }
  };

  const validated = validateTheme(rawTheme);
  if (!validated.ok)
    return { ok: false, errors: validated.errors.map(error => `matugen theme: ${error}`), value: null };
  return { ok: true, errors: [], value: rawTheme };
}
