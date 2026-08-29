// Pure transformations for brightness helper structured output.
// These functions have no QML or Qt dependencies and are fixture-tested.

const DEVICE_NAME_PATTERN = /^[a-zA-Z0-9_:.-]+$/;

function isValidDevice(device) {
  return typeof device === "object" && device !== null
      && typeof device.name === "string" && DEVICE_NAME_PATTERN.test(device.name)
      && typeof device.class === "string" && device.class.length > 0
      && Number.isInteger(device.brightness) && device.brightness >= 0
      && Number.isInteger(device.maxBrightness) && device.maxBrightness > 0
      && device.brightness <= device.maxBrightness
      && Number.isInteger(device.percent) && device.percent >= 0 && device.percent <= 100
      && device.percent === Math.round(100 * device.brightness / device.maxBrightness);
}

export function parseDiscoverOutput(text) {
  if (typeof text !== "string") return { ok: false, error: "discover output is not a string" };
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch (error) {
    return { ok: false, error: `discover JSON parse failed: ${error.message}` };
  }
  if (parsed.schemaVersion !== 1) return { ok: false, error: "discover output schemaVersion must be 1" };
  if (!Array.isArray(parsed.devices)) return { ok: false, error: "discover output missing devices array" };
  const devices = [];
  for (const device of parsed.devices) {
    if (!isValidDevice(device)) return { ok: false, error: "discover output contains an invalid device" };
    devices.push({
      name: device.name,
      class: device.class,
      brightness: device.brightness,
      maxBrightness: device.maxBrightness,
      percent: device.percent
    });
  }
  return { ok: true, devices };
}

function isValidRead(parsed) {
  return typeof parsed === "object" && parsed !== null
      && typeof parsed.name === "string" && DEVICE_NAME_PATTERN.test(parsed.name)
      && Number.isInteger(parsed.brightness) && parsed.brightness >= 0
      && Number.isInteger(parsed.maxBrightness) && parsed.maxBrightness > 0
      && parsed.brightness <= parsed.maxBrightness
      && Number.isInteger(parsed.percent) && parsed.percent >= 0 && parsed.percent <= 100
      && parsed.percent === Math.round(100 * parsed.brightness / parsed.maxBrightness);
}

export function parseReadOutput(text) {
  if (typeof text !== "string") return { ok: false, error: "read output is not a string" };
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch (error) {
    return { ok: false, error: `read JSON parse failed: ${error.message}` };
  }
  if (parsed.schemaVersion !== 1) return { ok: false, error: "read output schemaVersion must be 1" };
  if (!isValidRead(parsed)) return { ok: false, error: "read output contains invalid fields" };
  return {
    ok: true,
    name: parsed.name,
    brightness: parsed.brightness,
    maxBrightness: parsed.maxBrightness,
    percent: parsed.percent
  };
}

export function parseSetOutput(text) {
  return parseReadOutput(text);
}

export function selectBacklightDevice(devices) {
  return selectDevice(devices, "backlight");
}

export function selectDevice(devices, deviceClass) {
  if (!Array.isArray(devices) || devices.length === 0) return null;
  const candidates = devices.filter(device => device.class === deviceClass);
  if (candidates.length === 0) return null;
  if (deviceClass === "leds") {
    const keyboard = candidates.find(device => /kbd|keyboard/i.test(device.name));
    if (keyboard) return keyboard;
  }
  return candidates[0];
}

export function parseSysfsSnapshot(brightnessText, maxBrightnessText, name, deviceClass) {
  if (typeof brightnessText !== "string" || typeof maxBrightnessText !== "string")
    return { ok: false, error: "sysfs values must be strings" };
  if (typeof name !== "string" || !DEVICE_NAME_PATTERN.test(name))
    return { ok: false, error: "invalid sysfs device name" };
  const brightnessValue = brightnessText.trim();
  const maxValue = maxBrightnessText.trim();
  if (!/^\d+$/.test(brightnessValue) || !/^\d+$/.test(maxValue))
    return { ok: false, error: "sysfs values must be non-negative integers" };
  const brightness = Number(brightnessValue);
  const maxBrightness = Number(maxValue);
  if (!Number.isSafeInteger(brightness) || !Number.isSafeInteger(maxBrightness)
      || maxBrightness <= 0 || brightness > maxBrightness)
    return { ok: false, error: "sysfs values are outside the valid range" };
  return {
    ok: true,
    name,
    class: typeof deviceClass === "string" ? deviceClass : "backlight",
    brightness,
    maxBrightness,
    percent: Math.round(100 * brightness / maxBrightness)
  };
}

export function clampPercent(value) {
  if (typeof value !== "number" || !Number.isFinite(value)) return 1;
  return Math.max(1, Math.min(100, Math.round(value)));
}

export function percentToRaw(percent, maxBrightness) {
  const max = Number.isInteger(maxBrightness) && maxBrightness > 0 ? maxBrightness : 1;
  const clamped = clampPercent(percent);
  return Math.max(1, Math.round(clamped * max / 100));
}
