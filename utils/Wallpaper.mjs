const ABSOLUTE_PATH_PATTERN = /^\/(?:[^/]+\/)*[^/]+$/;

export function isWallpaperPath(value, root) {
  if (typeof value !== "string" || typeof root !== "string") return false;
  if (!ABSOLUTE_PATH_PATTERN.test(value) || !ABSOLUTE_PATH_PATTERN.test(root)) return false;
  const normalizedRoot = root.replace(/\/+$/, "");
  return value.startsWith(`${normalizedRoot}/`) && !value.split("/").includes("..");
}

export function validateWallpaperState(document) {
  if (document === null || typeof document !== "object" || Array.isArray(document))
    return { ok: false, errors: ["wallpaper state: root must be an object"], value: null };
  const errors = [];
  if (document.schemaVersion !== 1)
    errors.push("wallpaper state.schemaVersion: expected 1");
  if (typeof document.selectedPath !== "string" || !ABSOLUTE_PATH_PATTERN.test(document.selectedPath))
    errors.push("wallpaper state.selectedPath: expected an absolute path");
  return {
    ok: errors.length === 0,
    errors,
    value: errors.length === 0 ? { schemaVersion: 1, selectedPath: document.selectedPath } : null
  };
}
