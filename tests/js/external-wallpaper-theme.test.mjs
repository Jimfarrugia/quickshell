import assert from "node:assert/strict";
import {
  generateWallpaperExternalTargets,
  validateExternalTargetContent
} from "../../utils/ExternalWallpaperTheme.mjs";

const palette = {
  background: "#101820", on_background: "#f4f7fb", surface: "#18232d", on_surface: "#f4f7fb",
  surface_variant: "#3f4b56", on_surface_variant: "#d1dae4", primary: "#9ecaff",
  on_primary: "#003258", primary_container: "#1c4a73", on_primary_container: "#d1e5ff",
  secondary: "#b5c9e2", on_secondary: "#1f3348", secondary_container: "#364b62",
  on_secondary_container: "#d1e5ff", tertiary: "#d5bce5", tertiary_container: "#513a5e",
  on_tertiary_container: "#f2daff", outline: "#8b96a2", outline_variant: "#414b56",
  error: "#ffb4ab", shadow: "#000000", scrim: "#000000"
};

const bases = {
  home: "/tmp/qe-test/home",
  config: "/tmp/qe-test/home/.config",
  zshConfig: "/tmp/qe-test/home/.config/zsh",
  cache: "/tmp/qe-test/home/.cache"
};

const result = generateWallpaperExternalTargets(palette, bases, "dark");
assert.equal(result.ok, true);
assert.equal(result.errors.length, 0);
assert.equal(result.targets.length, 13);

const ids = result.targets.map(target => target.id).sort();
assert.deepEqual(ids, [
  "bat", "btop", "dunst", "eza", "fzf", "hyprland", "hyprlock",
  "kitty", "nvim", "opencode", "rofi", "starship", "tmux"
].sort());

for (const target of result.targets) {
  assert.equal(validateExternalTargetContent(target), null, `target ${target.id}`);
  assert.match(target.path, /^\//);
  assert.equal(target.path.includes(".."), false);
  assert.equal(target.content.length > 0, true);
}

const byId = Object.fromEntries(result.targets.map(target => [target.id, target]));
assert.match(byId.kitty.content, /^color0 #101820$/m);
assert.match(byId.kitty.content, /^color15 /m);
assert.match(byId.hyprland.content, /hl\.config\(/);
assert.match(byId.hyprlock.content, /^\$background/m);
assert.match(byId.rofi.content, /@white;/);
assert.match(byId.tmux.content, /^set -g @default_fg/m);
assert.match(byId.fzf.content, /--color=fg:/);
assert.match(byId.nvim.content, /"schema":\s*"qe-nvim-palette"/);
for (const token of [
  "primary", "secondary", "tertiary", "tertiary_container", "secondary_container",
  "error", "on_surface_variant"
]) {
  assert.match(byId.starship.content, new RegExp(`^${token}=`, "m"));
}
assert.match(byId.starship.content, /^export OS_FG="\$primary"$/m);
assert.match(byId.starship.content, /^export GIT_FG="\$secondary"$/m);
assert.match(byId.starship.content, /^export ENV_FG="\$tertiary_container"$/m);
assert.match(byId.starship.content, /^export CHAR_ERROR_FG="\$error"$/m);
assert.match(byId.starship.content, /^export CMD_DURATION_FG="\$on_surface_variant"$/m);
for (const colorAlias of ["white", "black", "gray", "red", "green", "yellow", "blue", "purple", "cyan"]) {
  assert.doesNotMatch(byId.starship.content, new RegExp(`^${colorAlias}=`, "m"));
}
for (const placeholder of [
  "OS_BG", "OS_FG", "DIR_PATH_FG", "GIT_FG", "ENV_FG", "CMD_DURATION_FG",
  "BATTERY_FG", "HOSTNAME_FG", "TIME_FG", "CHAR_SUCCESS_FG", "CHAR_ERROR_FG",
  "CHAR_VIM_FG", "USERNAME_USER_FG", "DOCKER_FG"
]) {
  assert.match(byId.starship.content, new RegExp(`^export ${placeholder}=`, "m"));
}
for (const placeholder of [
  "OS_BG", "DIR_PATH_BG", "GIT_BG", "ENV_BG", "BATTERY_BG", "HOSTNAME_BG", "TIME_BG", "USERNAME_USER_BG", "USERNAME_ROOT_BG", "DOCKER_BG"
]) {
  assert.match(byId.starship.content, new RegExp(`^export ${placeholder}=""$`, "m"));
}
assert.equal(validateExternalTargetContent({
  ...byId.starship,
  content: byId.starship.content.replace(/^export OS_BG=.*\n/m, "")
}), "target 'starship': generated content is missing a template placeholder export");
assert.equal(JSON.parse(byId.nvim.content).variant, "dark");
assert.equal(JSON.parse(byId.nvim.content).colors.surface_variant, "#3f4b56");
assert.equal(JSON.parse(byId.nvim.content).colors.primary, "#9ecaff");
assert.equal(JSON.parse(byId.opencode.content).theme.background.dark, "background");
assert.equal(byId.nvim.path, "/tmp/qe-test/home/.cache/matugen/nvim-colors.json");

const light = generateWallpaperExternalTargets(palette, bases, "light");
assert.equal(light.ok, true);
assert.equal(JSON.parse(light.targets.find(target => target.id === "nvim").content).variant, "light");
assert.equal(JSON.parse(byId.nvim.content).variant, "dark");

assert.equal(generateWallpaperExternalTargets({ ...palette, background: undefined }, bases, "dark").ok, false);
assert.equal(generateWallpaperExternalTargets({ ...palette, background: "nope" }, bases, "dark").ok, false);
assert.equal(generateWallpaperExternalTargets(null, bases, "dark").ok, false);
assert.equal(generateWallpaperExternalTargets(palette, null, "dark").ok, false);
assert.equal(generateWallpaperExternalTargets(palette, { ...bases, config: "relative" }, "dark").ok, false);
assert.equal(generateWallpaperExternalTargets(palette, { ...bases, cache: "/tmp/../etc" }, "dark").ok, false);

assert.equal(validateExternalTargetContent({ id: "kitty", path: "relative", content: "x" }) !== null, true);
assert.equal(validateExternalTargetContent({ id: "kitty", path: "/abs", content: "" }) !== null, true);
assert.equal(validateExternalTargetContent({ id: "kitty", path: "/abs", content: "no color0 here" }) !== null, true);
assert.equal(validateExternalTargetContent({ id: "ghost", path: "/abs", content: "anything" }), null);

console.log("external-wallpaper-theme fixtures passed");
