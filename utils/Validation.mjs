const THEME_TOKENS = [
  "background",
  "on_background",
  "surface",
  "on_surface",
  "surface_variant",
  "on_surface_variant",
  "surface_panel",
  "surface_sidebar",
  "surface_low",
  "on_surface_panel",
  "surface_tooltip",
  "on_surface_tooltip",
  "surface_hover",
  "surface_pressed",
  "primary",
  "on_primary",
  "primary_container",
  "on_primary_container",
  "secondary",
  "on_secondary",
  "outline",
  "outline_variant",
  "focus_ring",
  "on_surface_disabled",
  "on_surface_placeholder",
  "link",
  "highlight",
  "on_highlight",
  "success",
  "warning",
  "error",
  "shadow",
  "scrim",
  "charging"
];

const COLOR_PATTERN = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/;
const THEME_ID_PATTERN = /^[a-z0-9]+(?:_[a-z0-9]+)*$/;

export const defaultConfig = Object.freeze({
  schemaVersion: 1,
  preview: Object.freeze({ enabled: true }),
  bar: Object.freeze({
    enabled: false,
    edge: "bottom",
    exclusive: true,
    height: 26,
    trayHostEnabled: false,
    moduleSpacing: 8,
    brightnessEnabled: true,
    bluetoothEnabled: true,
    idleInhibitorEnabled: true,
    metrics: Object.freeze({
      cpu: true,
      memory: true,
      disk: true,
      temperature: true,
      order: Object.freeze(["disk", "memory", "cpu", "temperature"])
    })
  }),
  clock: Object.freeze({ showSeconds: false, format24h: false }),
  notifications: Object.freeze({
    enabled: false,
    popupEnabled: true,
    historyEnabled: true,
    historyLimit: 20,
    maxSummaryBytes: 512,
    maxBodyBytes: 8192,
    maxActions: 8
  }),
  osd: Object.freeze({ enabled: false, durationMs: 2000, maxQueue: 8 }),
  commands: Object.freeze({ timeoutMs: 5000, termGraceMs: 1000, maxOutputBytes: 32768 }),
  appearance: Object.freeze({
    fontFamily: "Inter",
    monospaceFontFamily: "JetBrainsMono Nerd Font",
    iconFontFamily: "Material Symbols Rounded",
    fontSize: 14,
    spacing: 8,
    radius: 10,
    borderWidth: 1,
    opacity: 1,
    shadows: true,
    animations: true
  })
});

export const safeDefaultsManifest = Object.freeze({
  schemaVersion: 1,
  defaultTheme: "poimandres"
});

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function integerIn(value, minimum, maximum) {
  return Number.isInteger(value) && value >= minimum && value <= maximum;
}

function numberIn(value, minimum, maximum) {
  return typeof value === "number" && Number.isFinite(value) && value >= minimum && value <= maximum;
}

function copyDefaults() {
  return {
    schemaVersion: defaultConfig.schemaVersion,
    preview: Object.assign({}, defaultConfig.preview),
    bar: Object.assign({}, defaultConfig.bar, {
      metrics: Object.assign({}, defaultConfig.bar.metrics, {
        order: Array.prototype.slice.call(defaultConfig.bar.metrics.order)
      })
    }),
    clock: Object.assign({}, defaultConfig.clock),
    notifications: Object.assign({}, defaultConfig.notifications),
    osd: Object.assign({}, defaultConfig.osd),
    commands: Object.assign({}, defaultConfig.commands),
    appearance: Object.assign({}, defaultConfig.appearance)
  };
}

export function parseJson(text, boundary) {
  try {
    return { ok: true, value: JSON.parse(text), errors: [] };
  } catch (error) {
    return { ok: false, value: null, errors: [`${boundary}: invalid JSON: ${error.message}`] };
  }
}

export function validateConfig(document) {
  const value = copyDefaults();
  const errors = [];

  if (!isObject(document))
    return { ok: false, value, errors: ["config: root must be an object"] };
  if (document.schemaVersion !== 1)
    return { ok: false, value, errors: ["config.schemaVersion: expected 1"] };

  if (isObject(document.preview) && typeof document.preview.enabled === "boolean")
    value.preview.enabled = document.preview.enabled;
  else if (document.preview !== undefined)
    errors.push("config.preview.enabled: expected a boolean");

  if (isObject(document.bar)) {
    if (typeof document.bar.enabled === "boolean") value.bar.enabled = document.bar.enabled;
    else if (document.bar.enabled !== undefined) errors.push("config.bar.enabled: expected a boolean");
    if (document.bar.edge === "top" || document.bar.edge === "bottom") value.bar.edge = document.bar.edge;
    else if (document.bar.edge !== undefined) errors.push("config.bar.edge: expected 'top' or 'bottom'");
    if (typeof document.bar.exclusive === "boolean") value.bar.exclusive = document.bar.exclusive;
    else if (document.bar.exclusive !== undefined) errors.push("config.bar.exclusive: expected a boolean");
    if (integerIn(document.bar.height, 16, 128)) value.bar.height = document.bar.height;
    else if (document.bar.height !== undefined) errors.push("config.bar.height: expected an integer from 16 to 128");
    if (typeof document.bar.trayHostEnabled === "boolean") value.bar.trayHostEnabled = document.bar.trayHostEnabled;
    else if (document.bar.trayHostEnabled !== undefined) errors.push("config.bar.trayHostEnabled: expected a boolean");
    if (integerIn(document.bar.moduleSpacing, 0, 64)) value.bar.moduleSpacing = document.bar.moduleSpacing;
    else if (document.bar.moduleSpacing !== undefined) errors.push("config.bar.moduleSpacing: expected an integer from 0 to 64");
    if (typeof document.bar.brightnessEnabled === "boolean") value.bar.brightnessEnabled = document.bar.brightnessEnabled;
    else if (document.bar.brightnessEnabled !== undefined) errors.push("config.bar.brightnessEnabled: expected a boolean");
    if (typeof document.bar.bluetoothEnabled === "boolean") value.bar.bluetoothEnabled = document.bar.bluetoothEnabled;
    else if (document.bar.bluetoothEnabled !== undefined) errors.push("config.bar.bluetoothEnabled: expected a boolean");
    if (typeof document.bar.idleInhibitorEnabled === "boolean") value.bar.idleInhibitorEnabled = document.bar.idleInhibitorEnabled;
    else if (document.bar.idleInhibitorEnabled !== undefined) errors.push("config.bar.idleInhibitorEnabled: expected a boolean");

    if (isObject(document.bar.metrics)) {
      const orderProvided = document.bar.metrics.order !== undefined;
      for (const key of ["cpu", "memory", "disk", "temperature"]) {
        if (typeof document.bar.metrics[key] === "boolean") value.bar.metrics[key] = document.bar.metrics[key];
        else if (document.bar.metrics[key] !== undefined) errors.push(`config.bar.metrics.${key}: expected a boolean`);
      }
      if (Array.isArray(document.bar.metrics.order)) {
        const allowed = ["disk", "memory", "cpu", "temperature"];
        const order = document.bar.metrics.order.filter(item => allowed.indexOf(item) !== -1);
        const unique = Array.from(new Set(order));
        if (order.length !== document.bar.metrics.order.length)
          errors.push("config.bar.metrics.order: unsupported metric key");
        else if (unique.length !== order.length)
          errors.push("config.bar.metrics.order: duplicate metric key");
        else
          value.bar.metrics.order = order;
      } else if (document.bar.metrics.order !== undefined) {
        errors.push("config.bar.metrics.order: expected an array");
      }
      const enabledMetrics = ["disk", "memory", "cpu", "temperature"]
        .filter(key => value.bar.metrics[key]);
      if (value.bar.metrics.order.length !== enabledMetrics.length
          || enabledMetrics.some(key => value.bar.metrics.order.indexOf(key) === -1)) {
        if (orderProvided)
          errors.push("config.bar.metrics.order: must contain every enabled metric exactly once and no disabled metrics");
        value.bar.metrics.order = enabledMetrics;
      }
    } else if (document.bar.metrics !== undefined) {
      errors.push("config.bar.metrics: expected an object");
    }
  } else if (document.bar !== undefined) {
    errors.push("config.bar: expected an object");
  }

  if (isObject(document.clock)) {
    if (typeof document.clock.showSeconds === "boolean") value.clock.showSeconds = document.clock.showSeconds;
    else if (document.clock.showSeconds !== undefined) errors.push("config.clock.showSeconds: expected a boolean");
    if (typeof document.clock.format24h === "boolean") value.clock.format24h = document.clock.format24h;
    else if (document.clock.format24h !== undefined) errors.push("config.clock.format24h: expected a boolean");
  } else if (document.clock !== undefined) {
    errors.push("config.clock: expected an object");
  }

  if (isObject(document.notifications)) {
    if (typeof document.notifications.enabled === "boolean") value.notifications.enabled = document.notifications.enabled;
    else if (document.notifications.enabled !== undefined) errors.push("config.notifications.enabled: expected a boolean");
    if (typeof document.notifications.popupEnabled === "boolean") value.notifications.popupEnabled = document.notifications.popupEnabled;
    else if (document.notifications.popupEnabled !== undefined) errors.push("config.notifications.popupEnabled: expected a boolean");
    if (typeof document.notifications.historyEnabled === "boolean") value.notifications.historyEnabled = document.notifications.historyEnabled;
    else if (document.notifications.historyEnabled !== undefined) errors.push("config.notifications.historyEnabled: expected a boolean");
    if (integerIn(document.notifications.historyLimit, 1, 100)) value.notifications.historyLimit = document.notifications.historyLimit;
    else if (document.notifications.historyLimit !== undefined) errors.push("config.notifications.historyLimit: expected an integer from 1 to 100");
    if (integerIn(document.notifications.maxSummaryBytes, 64, 4096)) value.notifications.maxSummaryBytes = document.notifications.maxSummaryBytes;
    else if (document.notifications.maxSummaryBytes !== undefined) errors.push("config.notifications.maxSummaryBytes: expected an integer from 64 to 4096");
    if (integerIn(document.notifications.maxBodyBytes, 256, 65536)) value.notifications.maxBodyBytes = document.notifications.maxBodyBytes;
    else if (document.notifications.maxBodyBytes !== undefined) errors.push("config.notifications.maxBodyBytes: expected an integer from 256 to 65536");
    if (integerIn(document.notifications.maxActions, 0, 16)) value.notifications.maxActions = document.notifications.maxActions;
    else if (document.notifications.maxActions !== undefined) errors.push("config.notifications.maxActions: expected an integer from 0 to 16");
  } else if (document.notifications !== undefined) {
    errors.push("config.notifications: expected an object");
  }

  if (isObject(document.osd)) {
    if (typeof document.osd.enabled === "boolean") value.osd.enabled = document.osd.enabled;
    else if (document.osd.enabled !== undefined) errors.push("config.osd.enabled: expected a boolean");
    if (integerIn(document.osd.durationMs, 500, 10000)) value.osd.durationMs = document.osd.durationMs;
    else if (document.osd.durationMs !== undefined) errors.push("config.osd.durationMs: expected an integer from 500 to 10000");
    if (integerIn(document.osd.maxQueue, 1, 32)) value.osd.maxQueue = document.osd.maxQueue;
    else if (document.osd.maxQueue !== undefined) errors.push("config.osd.maxQueue: expected an integer from 1 to 32");
  } else if (document.osd !== undefined) {
    errors.push("config.osd: expected an object");
  }

  if (isObject(document.commands)) {
    if (integerIn(document.commands.timeoutMs, 100, 300000))
      value.commands.timeoutMs = document.commands.timeoutMs;
    else if (document.commands.timeoutMs !== undefined)
      errors.push("config.commands.timeoutMs: expected an integer from 100 to 300000");
    if (integerIn(document.commands.termGraceMs, 0, 30000))
      value.commands.termGraceMs = document.commands.termGraceMs;
    else if (document.commands.termGraceMs !== undefined)
      errors.push("config.commands.termGraceMs: expected an integer from 0 to 30000");
    if (integerIn(document.commands.maxOutputBytes, 1024, 1048576))
      value.commands.maxOutputBytes = document.commands.maxOutputBytes;
    else if (document.commands.maxOutputBytes !== undefined)
      errors.push("config.commands.maxOutputBytes: expected an integer from 1024 to 1048576");
  } else if (document.commands !== undefined) {
    errors.push("config.commands: expected an object");
  }

  if (isObject(document.appearance)) {
    if (typeof document.appearance.fontFamily === "string" && document.appearance.fontFamily.length > 0)
      value.appearance.fontFamily = document.appearance.fontFamily;
    else if (document.appearance.fontFamily !== undefined)
      errors.push("config.appearance.fontFamily: expected a non-empty string");
    if (typeof document.appearance.monospaceFontFamily === "string" && document.appearance.monospaceFontFamily.length > 0)
      value.appearance.monospaceFontFamily = document.appearance.monospaceFontFamily;
    else if (document.appearance.monospaceFontFamily !== undefined)
      errors.push("config.appearance.monospaceFontFamily: expected a non-empty string");
    if (typeof document.appearance.iconFontFamily === "string" && document.appearance.iconFontFamily.length > 0)
      value.appearance.iconFontFamily = document.appearance.iconFontFamily;
    else if (document.appearance.iconFontFamily !== undefined)
      errors.push("config.appearance.iconFontFamily: expected a non-empty string");
    if (numberIn(document.appearance.fontSize, 8, 48)) value.appearance.fontSize = document.appearance.fontSize;
    else if (document.appearance.fontSize !== undefined) errors.push("config.appearance.fontSize: expected 8 to 48");
    if (numberIn(document.appearance.spacing, 0, 64)) value.appearance.spacing = document.appearance.spacing;
    else if (document.appearance.spacing !== undefined) errors.push("config.appearance.spacing: expected 0 to 64");
    if (numberIn(document.appearance.radius, 0, 64)) value.appearance.radius = document.appearance.radius;
    else if (document.appearance.radius !== undefined) errors.push("config.appearance.radius: expected 0 to 64");
    if (numberIn(document.appearance.borderWidth, 0, 8)) value.appearance.borderWidth = document.appearance.borderWidth;
    else if (document.appearance.borderWidth !== undefined) errors.push("config.appearance.borderWidth: expected 0 to 8");
    if (numberIn(document.appearance.opacity, 0.1, 1)) value.appearance.opacity = document.appearance.opacity;
    else if (document.appearance.opacity !== undefined) errors.push("config.appearance.opacity: expected 0.1 to 1");
    if (typeof document.appearance.shadows === "boolean") value.appearance.shadows = document.appearance.shadows;
    else if (document.appearance.shadows !== undefined) errors.push("config.appearance.shadows: expected a boolean");
    if (typeof document.appearance.animations === "boolean") value.appearance.animations = document.appearance.animations;
    else if (document.appearance.animations !== undefined) errors.push("config.appearance.animations: expected a boolean");
  } else if (document.appearance !== undefined) {
    errors.push("config.appearance: expected an object");
  }

  return { ok: true, value, errors };
}

export function validateDefaultsManifest(document) {
  const value = Object.assign({}, safeDefaultsManifest);
  const errors = [];

  if (!isObject(document))
    return { ok: false, value, errors: ["defaults manifest: root must be an object"] };
  if (document.schemaVersion !== 1)
    errors.push("defaults manifest.schemaVersion: expected 1");
  if (typeof document.defaultTheme !== "string" || !THEME_ID_PATTERN.test(document.defaultTheme))
    errors.push("defaults manifest.defaultTheme: expected a normalized theme ID");
  else
    value.defaultTheme = document.defaultTheme;
  for (const key of Object.keys(document)) {
    if (key !== "schemaVersion" && key !== "defaultTheme")
      errors.push(`defaults manifest.${key}: unsupported property`);
  }
  return { ok: errors.length === 0, value, errors };
}

function resolveThemeValue(value, palette, tokens, trail) {
  if (COLOR_PATTERN.test(value)) return value.toLowerCase();
  const match = /^\{(palette|tokens)\.([A-Za-z][A-Za-z0-9]*)\}$/.exec(value);
  if (!match) throw new Error(`unsupported color or reference '${value}'`);
  const key = `${match[1]}.${match[2]}`;
  if (trail.indexOf(key) !== -1) throw new Error(`reference cycle: ${trail.concat([key]).join(" -> ")}`);
  const source = match[1] === "palette" ? palette : tokens;
  if (typeof source[match[2]] !== "string") throw new Error(`missing reference '${key}'`);
  return resolveThemeValue(source[match[2]], palette, tokens, trail.concat([key]));
}

export function validateTheme(document) {
  const errors = [];
  if (!isObject(document)) return { ok: false, errors: ["theme: root must be an object"] };
  if (document.schemaVersion !== 1) errors.push("theme.schemaVersion: expected 1");
  if (typeof document.id !== "string" || !THEME_ID_PATTERN.test(document.id))
    errors.push("theme.id: expected lowercase snake_case");
  if (typeof document.name !== "string" || document.name.trim().length === 0)
    errors.push("theme.name: expected a non-empty string");
  if (document.variant !== "dark" && document.variant !== "light")
    errors.push("theme.variant: expected 'dark' or 'light'");
  if (!isObject(document.palette)) errors.push("theme.palette: expected an object");
  if (!isObject(document.tokens)) errors.push("theme.tokens: expected an object");
  if (errors.length > 0) return { ok: false, errors };
  if (Object.keys(document.palette).length === 0)
    errors.push("theme.palette: expected at least one color");

  for (const [key, color] of Object.entries(document.palette)) {
    if (typeof color !== "string" || !COLOR_PATTERN.test(color))
      errors.push(`theme.palette.${key}: expected #RRGGBB or #RRGGBBAA`);
  }
  for (const token of THEME_TOKENS) {
    if (typeof document.tokens[token] !== "string") errors.push(`theme.tokens.${token}: required`);
  }
  for (const token of Object.keys(document.tokens)) {
    if (THEME_TOKENS.indexOf(token) === -1) errors.push(`theme.tokens.${token}: unsupported token`);
  }

  const resolvedPalette = {};
  const resolvedTokens = {};
  if (errors.length === 0) {
    for (const [key, color] of Object.entries(document.palette))
      resolvedPalette[key] = color.toLowerCase();
    for (const token of THEME_TOKENS) {
      try {
        resolvedTokens[token] = resolveThemeValue(document.tokens[token], document.palette, document.tokens, [`tokens.${token}`]);
      } catch (error) {
        errors.push(`theme.tokens.${token}: ${error.message}`);
      }
    }
  }

  return {
    ok: errors.length === 0,
    errors,
    value: errors.length === 0 ? {
      schemaVersion: 1,
      id: document.id,
      name: document.name,
      variant: document.variant,
      palette: resolvedPalette,
      tokens: resolvedTokens
    } : null
  };
}

export function validateThemeState(document) {
  if (!isObject(document)) return { ok: false, errors: ["theme state: root must be an object"] };
  if (document.schemaVersion !== 1) return { ok: false, errors: ["theme state.schemaVersion: expected 1"] };
  if (typeof document.activeThemeId !== "string" || !THEME_ID_PATTERN.test(document.activeThemeId))
    return { ok: false, errors: ["theme state.activeThemeId: expected a normalized theme ID"] };
  return { ok: true, value: { schemaVersion: 1, activeThemeId: document.activeThemeId }, errors: [] };
}

export function truncateUtf8(text, maximumBytes) {
  if (typeof text !== "string") return { text: "", truncated: false };
  function characterBytes(codePoint) {
    if (codePoint <= 0x7f) return 1;
    if (codePoint <= 0x7ff) return 2;
    if (codePoint <= 0xffff) return 3;
    return 4;
  }

  let bytes = 0;
  let end = 0;
  while (end < text.length) {
    const first = text.charCodeAt(end);
    const surrogatePair = first >= 0xd800 && first <= 0xdbff && end + 1 < text.length;
    const codePoint = surrogatePair
      ? ((first - 0xd800) * 0x400) + (text.charCodeAt(end + 1) - 0xdc00) + 0x10000
      : first;
    const size = characterBytes(codePoint);
    if (bytes + size > maximumBytes) return { text: text.slice(0, end), truncated: true };
    bytes += size;
    end += surrogatePair ? 2 : 1;
  }
  return { text, truncated: false };
}

export function validateNotificationState(document) {
  if (!isObject(document)) return { ok: false, value: { schemaVersion: 1, dnd: false }, errors: ["notification state: root must be an object"] };
  if (document.schemaVersion !== 1)
    return { ok: false, value: { schemaVersion: 1, dnd: false }, errors: ["notification state.schemaVersion: expected 1"] };
  if (typeof document.dnd !== "boolean")
    return { ok: false, value: { schemaVersion: 1, dnd: false }, errors: ["notification state.dnd: expected a boolean"] };
  for (const key of Object.keys(document)) {
    if (key !== "schemaVersion" && key !== "dnd")
      return { ok: false, value: { schemaVersion: 1, dnd: false }, errors: [`notification state.${key}: unsupported property`] };
  }
  return { ok: true, value: { schemaVersion: 1, dnd: document.dnd }, errors: [] };
}

export function themeTokenNames() {
  return THEME_TOKENS.slice();
}
