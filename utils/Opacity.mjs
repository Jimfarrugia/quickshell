function opacity(value) {
  const number = typeof value === "number" ? value : Number(value);
  return Number.isFinite(number) && number >= 0 && number <= 1 ? number : 1;
}

export function effectivePanelAlpha(snapshot) {
  const kitty = opacity(snapshot?.kittyOpacity);
  const hyprland = opacity(snapshot?.hyprlandActiveOpacity);
  return Math.max(0, Math.min(1, kitty * hyprland));
}

export function alphaHex(snapshot) {
  return Math.round(effectivePanelAlpha(snapshot) * 255).toString(16).padStart(2, "0");
}
