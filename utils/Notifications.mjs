import { truncateUtf8 } from "./Validation.mjs";

const MAX_IMAGE_LENGTH = 2048;
const DEFAULT_SUMMARY_BYTES = 512;
const DEFAULT_BODY_BYTES = 8192;
const DEFAULT_ACTIONS = 8;

function bounded(value, maximum, fallback = "") {
  const result = truncateUtf8(typeof value === "string" ? value : fallback, maximum);
  return result.text;
}

function escapeHtml(value) {
  return value.replace(/&/g, "&amp;").replace(/</g, "&lt;")
    .replace(/>/g, "&gt;").replace(/\"/g, "&quot;").replace(/'/g, "&#39;");
}

export function sanitizeMarkup(value, maximumBytes = DEFAULT_BODY_BYTES) {
  const source = bounded(value, maximumBytes);
  const placeholders = [];
  const tokenized = source.replace(/<\/?(?:b|i|u|br)\s*\/?\s*>/gi, tag => {
    const normalized = tag.toLowerCase().replace(/\s+/g, "");
    const safeTag = normalized === "<br>" || normalized === "<br/>" ? "<br/>" : normalized;
    const index = placeholders.push(safeTag) - 1;
    return `\u0000${index}\u0000`;
  });
  const escaped = escapeHtml(tokenized.replace(/<[^>]*>/g, ""));
  return escaped.replace(/\u0000(\d+)\u0000/g, (_, index) => placeholders[Number(index)] || "");
}

export function plainText(value, maximumBytes = DEFAULT_BODY_BYTES) {
  return bounded(String(value || "").replace(/<[^>]*>/g, ""), maximumBytes);
}

export function normalizeUrgency(value) {
  if (value === 0 || value === "low" || value === "Low") return "low";
  if (value === 2 || value === "critical" || value === "Critical") return "critical";
  return "normal";
}

export function normalizeImage(value) {
  if (typeof value !== "string" || value.length === 0 || value.length > MAX_IMAGE_LENGTH) return "";
  if (/^image:\/\/icon\/[A-Za-z0-9._+-]+(?:\/[A-Za-z0-9._+-]+)*$/.test(value)) return value;
  if (/^file:\/\/\/[^?#\s]+$/.test(value)) return value;
  return "";
}

function normalizeIconName(value) {
  if (typeof value !== "string" || value.length === 0 || value.length > 256
      || !/^[A-Za-z0-9._+-]+(?:\/[A-Za-z0-9._+-]+)*$/.test(value)) return "";
  return value;
}

function normalizeIcon(value) {
  const name = normalizeIconName(value);
  return name.length > 0 ? `image://icon/${name}` : "";
}

function normalizeProgress(hints) {
  if (!hints || typeof hints !== "object") return { hasProgress: false, progress: 0 };
  const raw = hints.value !== undefined ? hints.value : hints["int:value"];
  if (raw === undefined || raw === null || raw === -1) return { hasProgress: false, progress: 0 };
  const value = Number(raw);
  if (!Number.isFinite(value) || value < 0 || value > 100) return { hasProgress: false, progress: 0 };
  return { hasProgress: true, progress: Math.round(value) };
}

function normalizeActions(actions, maximum) {
  if (!actions || typeof actions.length !== "number") return [];
  const result = [];
  const count = Math.min(Math.max(0, Math.floor(actions.length)), maximum);
  for (let index = 0; index < count; index++) {
    const action = actions[index];
    const normalized = {
      identifier: bounded(action && action.identifier, 256),
      text: bounded(action && action.text, 256)
    };
    if (normalized.identifier.length > 0 && normalized.text.length > 0)
      result.push(normalized);
  }
  return result;
}

export function normalizeNotification(input, options = {}) {
  const summaryBytes = options.maxSummaryBytes || DEFAULT_SUMMARY_BYTES;
  const bodyBytes = options.maxBodyBytes || DEFAULT_BODY_BYTES;
  const actionLimit = options.maxActions === undefined ? DEFAULT_ACTIONS : options.maxActions;
  const progress = normalizeProgress(input && input.hints);
  const body = bounded(input && input.body, bodyBytes);
  const appName = bounded(input && input.appName, 256, "Unknown application");
  const urgency = normalizeUrgency(input && input.urgency);
  const appIconName = normalizeIconName(input && input.appIcon);
  const appNameKey = appName.toLowerCase();
  const image = normalizeImage(input && input.image) || normalizeIcon(appIconName);
  let iconName = urgency === "critical" ? "warning" : "notifications";
  if (image.length === 0 && appNameKey === "qe-defaults") iconName = "colors";
  else if (image.length === 0 && appNameKey === "opencode") iconName = "robot_2";
  const isScreenshot = image.length > 0 && appName.toLowerCase() === "hyprshot";
  return {
    id: Number(input && input.id) || 0,
    appName: appName,
    appIcon: bounded(input && input.appIcon, MAX_IMAGE_LENGTH),
    summary: bounded(input && input.summary, summaryBytes),
    body: sanitizeMarkup(body, bodyBytes),
    plainBody: plainText(body, bodyBytes),
    urgency: urgency,
    actions: normalizeActions(input && input.actions, actionLimit),
    image: image,
    iconName: iconName,
    isScreenshot: isScreenshot,
    progress: progress.progress,
    hasProgress: progress.hasProgress,
    resident: input && input.resident === true,
    transient: input && input.transient === true,
    lastGeneration: input && input.lastGeneration === true,
    expireTimeout: Number.isFinite(Number(input && input.expireTimeout)) ? Math.max(0, Number(input.expireTimeout)) : 0
  };
}

export function shouldShowPopup(notification, dnd) {
  return !dnd || notification.urgency === "critical";
}

export function shouldKeepHistory(notification, historyEnabled) {
  return historyEnabled && !notification.transient;
}
