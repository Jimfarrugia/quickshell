import { validateTheme } from "./Validation.mjs";

const COLOR_PATTERN = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/;
const REQUIRED_COLORS = [
  "background", "on_background", "surface", "on_surface", "surface_variant",
  "on_surface_variant", "primary", "on_primary", "primary_container",
  "on_primary_container", "secondary", "on_secondary", "secondary_container",
  "on_secondary_container", "outline", "outline_variant", "error"
];

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

export function mapMatugenTheme(document, variant = "dark") {
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
      surface_variant: color("surface_variant"),
      on_surface_variant: color("on_surface_variant"),
      surface_panel: withAlpha(color("surface"), "e6"),
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
