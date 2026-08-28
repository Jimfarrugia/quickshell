const HEX_PATTERN = /^#[0-9a-fA-F]{6}$/;
const ANSI_KEYS = [
  "background",
  "error",
  "tertiary",
  "secondary",
  "primary",
  "secondaryContainer",
  "tertiaryContainer",
  "foreground",
  "surfaceVariant",
  "error",
  "tertiary",
  "secondaryContainer",
  "primaryContainer",
  "tertiaryContainer",
  "secondary",
  "onSurfaceVariant",
];

function buildCode(palette) {
  const read = (role) => {
    const value = palette[role];
    return HEX_PATTERN.test(value) ? value.toLowerCase() : "#000000";
  };
  return {
    background: read("background"),
    surfaceContainer: read("surface_container"),
    surfaceContainerLow: read("surface_container_low"),
    surfaceContainerHigh: read("surface_container_high"),
    foreground: read("on_background"),
    surface: read("surface"),
    onSurface: read("on_surface"),
    surfaceVariant: read("surface_variant"),
    onSurfaceVariant: read("on_surface_variant"),
    primary: read("primary"),
    onPrimary: read("on_primary"),
    primaryContainer: read("primary_container"),
    onPrimaryContainer: read("on_primary_container"),
    secondary: read("secondary"),
    onSecondary: read("on_secondary"),
    secondaryContainer: read("secondary_container"),
    onSecondaryContainer: read("on_secondary_container"),
    tertiary: read("tertiary"),
    tertiaryContainer: read("tertiary_container"),
    onTertiaryContainer: read("on_tertiary_container"),
    error: read("error"),
    outline: read("outline"),
    outlineVariant: read("outline_variant"),
  };
}

function hex(value, fallback = "#000000") {
  return HEX_PATTERN.test(value) ? value.toLowerCase() : fallback;
}

function stripHash(value) {
  return hex(value).slice(1).toUpperCase();
}

function ansiColors(c) {
  return ANSI_KEYS.map((key) => c[key]);
}

function kittyTheme(c) {
  const a = ansiColors(c);
  const lines = [
    "# vim:ft=kitty",
    `background ${c.background}`,
    `foreground ${c.foreground}`,
    `selection_background ${c.primaryContainer}`,
    `selection_foreground ${c.onPrimaryContainer}`,
    `url_color ${c.primary}`,
    `cursor ${c.primary}`,
    `cursor_text_color ${c.background}`,
    "active_tab_background " + c.primary,
    "active_tab_foreground " + c.onPrimary,
    "inactive_tab_background " + c.surfaceVariant,
    "inactive_tab_foreground " + c.onSurfaceVariant,
    "active_border_color " + c.primary,
    "inactive_border_color " + c.outlineVariant,
  ];
  for (let i = 0; i < 16; i++) lines.push(`color${i} ${a[i]}`);
  return lines.join("\n") + "\n";
}

function batTheme(c) {
  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<plist version="1.0">',
    "<dict>",
    "  <key>name</key><string>Wallpaper</string>",
    "  <key>uuid</key><string>qe-wallpaper-external-bat</string>",
    "  <key>settings</key>",
    "  <array>",
    "    <dict><key>settings</key><dict>",
    `      <key>background</key><string>${c.background}</string>`,
    `      <key>foreground</key><string>${c.foreground}</string>`,
    `      <key>caret</key><string>${c.primary}</string>`,
    `      <key>selection</key><string>${c.primaryContainer}</string>`,
    `      <key>invisibles</key><string>${c.outlineVariant}</string>`,
    "    </dict></dict>",
    `    <dict><key>scope</key><string>comment, comment.*</string><key>settings</key><dict><key>foreground</key><string>${c.outline}</string></dict></dict>`,
    `    <dict><key>scope</key><string>keyword, storage, keyword.*</string><key>settings</key><dict><key>foreground</key><string>${c.primary}</string></dict></dict>`,
    `    <dict><key>scope</key><string>string, string.*</string><key>settings</key><dict><key>foreground</key><string>${c.tertiary}</string></dict></dict>`,
    `    <dict><key>scope</key><string>constant.numeric</string><key>settings</key><dict><key>foreground</key><string>${c.secondary}</string></dict></dict>`,
    `    <dict><key>scope</key><string>entity.name.function, entity.name.class, entity.name.type</string><key>settings</key><dict><key>foreground</key><string>${c.onPrimaryContainer}</string></dict></dict>`,
    `    <dict><key>scope</key><string>invalid, invalid.*, constant.language</string><key>settings</key><dict><key>foreground</key><string>${c.error}</string></dict></dict>`,
    "  </array>",
    "</dict>",
    "</plist>",
    "",
  ].join("\n");
}

function yaziPalette(c) {
  const lines = [
    "#!/usr/bin/env bash",
    "",
    "# Yazi semantic palette generated from the active wallpaper palette",
    `export BACKGROUND="${c.background}"`,
    `export SURFACE="${c.surface}"`,
    `export SURFACE_HIGH="${c.surfaceContainerHigh}"`,
    `export BORDER="${c.outlineVariant}"`,
    `export FOREGROUND="${c.foreground}"`,
    `export FOREGROUND_MUTED="${c.onSurfaceVariant}"`,
    `export FOREGROUND_SUBTLE="${c.outline}"`,
    `export PRIMARY="${c.primary}"`,
    `export PRIMARY_BRIGHT="${c.primaryContainer}"`,
    `export SECONDARY="${c.secondary}"`,
    `export SECONDARY_BRIGHT="${c.tertiary}"`,
    `export SECONDARY_LIGHT="${c.onSurfaceVariant}"`,
    `export SECONDARY_PALE="${c.onSurface}"`,
    `export ACCENT="${c.tertiary}"`,
    `export WARNING="${c.tertiary}"`,
    `export DESTRUCTIVE="${c.error}"`,
    `export ERROR="${c.error}"`,
    "",
  ];
  return lines.join("\n");
}

function yaziTmTheme(c) {
  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    "<plist version=\"1.0\">",
    "<dict>",
    "  <key>name</key><string>Wallpaper</string>",
    "  <key>uuid</key><string>qe-wallpaper-external-yazi</string>",
    "  <key>settings</key>",
    "  <array>",
    "    <dict><key>settings</key><dict>",
    `      <key>background</key><string>${c.background}</string>`,
    `      <key>foreground</key><string>${c.foreground}</string>`,
    `      <key>caret</key><string>${c.primary}</string>`,
    `      <key>selection</key><string>${c.primaryContainer}</string>`,
    `      <key>invisibles</key><string>${c.outlineVariant}</string>`,
    "    </dict></dict>",
    `    <dict><key>scope</key><string>comment, comment.*</string><key>settings</key><dict><key>foreground</key><string>${c.outline}</string></dict></dict>`,
    `    <dict><key>scope</key><string>keyword, storage, keyword.*</string><key>settings</key><dict><key>foreground</key><string>${c.primary}</string></dict></dict>`,
    `    <dict><key>scope</key><string>string, string.*</string><key>settings</key><dict><key>foreground</key><string>${c.tertiary}</string></dict></dict>`,
    `    <dict><key>scope</key><string>constant.numeric</string><key>settings</key><dict><key>foreground</key><string>${c.secondary}</string></dict></dict>`,
    `    <dict><key>scope</key><string>entity.name.function, entity.name.class, entity.name.type</string><key>settings</key><dict><key>foreground</key><string>${c.onPrimaryContainer}</string></dict></dict>`,
    `    <dict><key>scope</key><string>invalid, invalid.*, constant.language</string><key>settings</key><dict><key>foreground</key><string>${c.error}</string></dict></dict>`,
    "  </array>",
    "</dict>",
    "</plist>",
    "",
  ].join("\n");
}

function gradientSuffix(c) {
  return [
    `theme[temp_start]="${stripHash(c.secondary)}"`,
    `theme[temp_mid]="${stripHash(c.tertiary)}"`,
    `theme[temp_end]="${stripHash(c.foreground)}"`,
    `theme[cpu_start]="${stripHash(c.secondary)}"`,
    `theme[cpu_mid]="${stripHash(c.tertiary)}"`,
    `theme[cpu_end]="${stripHash(c.foreground)}"`,
    `theme[free_start]="${stripHash(c.secondary)}"`,
    `theme[free_mid]="${stripHash(c.tertiary)}"`,
    `theme[free_end]="${stripHash(c.foreground)}"`,
    `theme[cached_start]="${stripHash(c.secondary)}"`,
    `theme[cached_mid]="${stripHash(c.tertiary)}"`,
    `theme[cached_end]="${stripHash(c.foreground)}"`,
    `theme[available_start]="${stripHash(c.secondary)}"`,
    `theme[available_mid]="${stripHash(c.tertiary)}"`,
    `theme[available_end]="${stripHash(c.foreground)}"`,
    `theme[used_start]="${stripHash(c.secondary)}"`,
    `theme[used_mid]="${stripHash(c.tertiary)}"`,
    `theme[used_end]="${stripHash(c.foreground)}"`,
    `theme[download_start]="${stripHash(c.secondary)}"`,
    `theme[download_mid]="${stripHash(c.tertiary)}"`,
    `theme[download_end]="${stripHash(c.foreground)}"`,
    `theme[upload_start]="${stripHash(c.secondary)}"`,
    `theme[upload_mid]="${stripHash(c.tertiary)}"`,
    `theme[upload_end]="${stripHash(c.foreground)}"`,
  ].join("\n");
}

function btopTheme(c) {
  return [
    "# btop theme generated from the active wallpaper palette",
    `theme[main_bg]="${stripHash(c.background)}"`,
    `theme[main_fg]="${stripHash(c.foreground)}"`,
    `theme[title]="${stripHash(c.primary)}"`,
    `theme[hi_fg]="${stripHash(c.secondary)}"`,
    `theme[selected_bg]="${stripHash(c.surfaceVariant)}"`,
    `theme[selected_fg]="${stripHash(c.foreground)}"`,
    `theme[inactive_fg]="${stripHash(c.outlineVariant)}"`,
    `theme[proc_misc]="${stripHash(c.secondary)}"`,
    `theme[cpu_box]="${stripHash(c.outlineVariant)}"`,
    `theme[mem_box]="${stripHash(c.outlineVariant)}"`,
    `theme[net_box]="${stripHash(c.outlineVariant)}"`,
    `theme[proc_box]="${stripHash(c.outlineVariant)}"`,
    `theme[div_line]="${stripHash(c.outlineVariant)}"`,
    gradientSuffix(c),
    "",
  ].join("\n");
}

function ezaYml(c) {
  const fg = c.foreground;
  const dim = c.onSurfaceVariant;
  const accent = c.primary;
  const accent2 = c.secondary;
  const accent3 = c.tertiary;
  const danger = c.error;
  const group = (items) =>
    items.map((kv) => `  ${kv.key}: {foreground: "${kv.value}"}`).join("\n");
  return [
    "colourful: false",
    "",
    "filekinds:",
    group([
      { key: "normal", value: fg },
      { key: "directory", value: accent },
      { key: "symlink", value: accent3 },
      { key: "pipe", value: dim },
      { key: "block_device", value: accent2 },
      { key: "char_device", value: accent2 },
      { key: "socket", value: accent2 },
      { key: "special", value: accent2 },
      { key: "executable", value: accent2 },
      { key: "mount_point", value: accent },
    ]),
    "",
    "perms:",
    group([
      { key: "user_read", value: fg },
      { key: "user_write", value: accent2 },
      { key: "user_execute_file", value: accent3 },
      { key: "user_execute_other", value: accent3 },
      { key: "group_read", value: fg },
      { key: "group_write", value: accent2 },
      { key: "group_execute", value: accent3 },
      { key: "other_read", value: accent },
      { key: "other_write", value: accent2 },
      { key: "other_execute", value: accent3 },
      { key: "special_user_file", value: accent2 },
      { key: "special_other", value: dim },
      { key: "attribute", value: accent },
    ]),
    "",
    "size:",
    group([
      { key: "major", value: accent },
      { key: "minor", value: accent2 },
      { key: "number_byte", value: fg },
      { key: "number_kilo", value: accent },
      { key: "number_mega", value: accent3 },
      { key: "number_giga", value: accent2 },
      { key: "number_huge", value: accent2 },
      { key: "unit_byte", value: accent },
      { key: "unit_kilo", value: accent3 },
      { key: "unit_mega", value: accent2 },
      { key: "unit_giga", value: accent2 },
      { key: "unit_huge", value: accent3 },
    ]),
    "",
    "users:",
    group([
      { key: "user_you", value: fg },
      { key: "user_root", value: dim },
      { key: "user_other", value: accent2 },
      { key: "group_yours", value: accent },
      { key: "group_other", value: dim },
      { key: "group_root", value: dim },
    ]),
    "",
    "links:",
    group([
      { key: "normal", value: accent2 },
      { key: "multi_link_file", value: accent3 },
    ]),
    "",
    "git:",
    group([
      { key: "new", value: accent },
      { key: "modified", value: accent2 },
      { key: "deleted", value: dim },
      { key: "renamed", value: accent3 },
      { key: "typechange", value: accent2 },
      { key: "ignored", value: dim },
      { key: "conflicted", value: danger },
    ]),
    "",
    "git_repo:",
    group([
      { key: "branch_main", value: fg },
      { key: "branch_other", value: accent2 },
      { key: "git_clean", value: accent3 },
      { key: "git_dirty", value: danger },
    ]),
    "",
    "security_context:",
    group([
      { key: "colon", value: accent3 },
      { key: "user", value: accent },
      { key: "role", value: accent2 },
      { key: "typ", value: dim },
      { key: "range", value: accent2 },
    ]),
    "",
    "file_type:",
    group([
      { key: "image", value: accent3 },
      { key: "video", value: accent2 },
      { key: "music", value: accent },
      { key: "lossless", value: accent2 },
      { key: "crypto", value: dim },
      { key: "document", value: fg },
      { key: "compressed", value: accent2 },
      { key: "temp", value: danger },
      { key: "compiled", value: accent3 },
      { key: "build", value: dim },
      { key: "source", value: accent2 },
    ]),
    "",
    `punctuation: {foreground: "${fg}"}`,
    `date: {foreground: "${accent3}"}`,
    `inode: {foreground: "${accent}"}`,
    `blocks: {foreground: "${dim}"}`,
    `header: {foreground: "${fg}"}`,
    `octal: {foreground: "${accent3}"}`,
    `flags: {foreground: "${accent2}"}`,
    "",
    `symlink_path: {foreground: "${accent2}"}`,
    `control_char: {foreground: "${accent3}"}`,
    `broken_symlink: {foreground: "${danger}"}`,
    `broken_path_overlay: {foreground: "${dim}"}`,
    "",
    "filenames:",
    "extensions:",
    "",
  ].join("\n");
}

function dunstTheme(c) {
  return [
    "# dunst theme generated from the active wallpaper palette",
    "[global]",
    `  highlight = "${c.primary}"`,
    `  frame_color = "${c.primary}"`,
    "",
    "[urgency_low]",
    `  background = "${c.background}"`,
    `  foreground = "${c.foreground}"`,
    "",
    "[urgency_normal]",
    `  background = "${c.surface}"`,
    `  foreground = "${c.onSurface}"`,
    "",
    "[urgency_critical]",
    `  background = "${c.error}"`,
    `  foreground = "${c.background}"`,
    "",
  ].join("\n");
}

function fzfZsh(c) {
  return [
    'FZF_DEFAULT_OPTS=""',
    "",
    `FZF_DEFAULT_OPTS+=" --color=border:${c.outline},label:${c.secondary}"`,
    `FZF_DEFAULT_OPTS+=" --color=fg:${c.foreground},bg:${c.background},hl:${c.primary}"`,
    `FZF_DEFAULT_OPTS+=" --color=fg+:${c.onPrimaryContainer},bg+:${c.primaryContainer},hl+:${c.primary}"`,
    `FZF_DEFAULT_OPTS+=" --color=info:${c.tertiary},prompt:${c.secondary},pointer:${c.secondary}"`,
    `FZF_DEFAULT_OPTS+=" --color=marker:${c.tertiary},spinner:${c.tertiary},header:${c.outlineVariant}"`,
    "",
    "export FZF_DEFAULT_OPTS",
    "",
  ].join("\n");
}

function hyprlandLua(c) {
  const rgb = (value) => `rgb(${stripHash(value)})`;
  return [
    "-- hyprland colors generated from the active wallpaper palette",
    `local black = "${rgb(c.background)}"`,
    `local white = "${rgb(c.foreground)}"`,
    `local gray = "${rgb(c.surfaceVariant)}"`,
    `local red = "${rgb(c.error)}"`,
    `local yellow = "${rgb(c.tertiary)}"`,
    `local blue = "${rgb(c.primary)}"`,
    `local cyan = "${rgb(c.secondary)}"`,
    "",
    "hl.config({",
    "\tgeneral = {",
    "\t\tcol = {",
    "\t\t\tactive_border = { colors = { cyan, white, cyan }, angle = 45 },",
    "\t\t\tinactive_border = gray,",
    "\t\t},",
    "\t},",
    "})",
    "",
    "hl.config({",
    "\tgroup = {",
    "\t\tgroupbar = {",
    "\t\t\tcol = {",
    "\t\t\t\tactive = cyan,",
    "\t\t\t\tinactive = gray,",
    "\t\t\t},",
    "\t\t},",
    "\t},",
    "})",
    "",
  ].join("\n");
}

function hyprlockConf(c) {
  const rgb = (value) => `rgb(${stripHash(value)})`;
  return [
    "# hyprlock colors generated from the active wallpaper palette",
    `$black     = ${rgb(c.background)}`,
    `$white     = ${rgb(c.foreground)}`,
    `$gray      = ${rgb(c.surfaceVariant)}`,
    `$red       = ${rgb(c.error)}`,
    `$yellow    = ${rgb(c.tertiary)}`,
    `$yellowRaw = ${stripHash(c.tertiary)}`,
    `$blue      = ${rgb(c.primary)}`,
    `$cyan      = ${rgb(c.secondary)}`,
    `$cyanRaw   = ${stripHash(c.secondary)}`,
    "",
    "$foreground      = $white",
    "$background      = $black",
    "$shadow_color    = $black",
    "$date_color      = $cyanRaw",
    `$rect_background = rgba(${stripHash(c.background)}4A)`,
    "$rect_border     = $white",
    "$icon_color      = $yellowRaw",
    "",
  ].join("\n");
}

function rofiRasi(c) {
  return [
    "* {",
    "  /* Theme Colors */",
    `  background: ${c.background};`,
    `  outline: ${c.outline};`,
    `  surface-container-low: ${c.surfaceContainerLow};`,
    `  on-background: ${c.foreground};`,
    `  primary: ${c.primary};`,
    `  secondary: ${c.secondary};`,
    `  tertiary: ${c.tertiary};`,
    `  tertiary-container: ${c.tertiaryContainer};`,
    `  secondary-container: ${c.secondaryContainer};`,
    `  error: ${c.error};`,
    "",
    "  /* Rofi Colors */",
    "  foreground: @on-background;",
    "  background-color: @background;",
    "  active-background: @surface-container-low;",
    "  active-foreground: @secondary;",
    "  urgent-background: @on-background;",
    "  urgent-foreground: @outline;",
    "  selected-background: @active-background;",
    "  selected-foreground: @secondary;",
    "  selected-urgent-background: @urgent-background;",
    "  selected-active-background: @active-background;",
    "  separatorcolor: @active-background;",
    "  textbox-prompt-colon-foreground: @tertiary-container;",
    "  bordercolor: @primary;",
    "  entry-foreground: @on-background;",
    "  prompt-foreground: @primary;",
    "}",
    "",
  ].join("\n");
}

function starshipSh(c) {
  return [
    "# starship semantic colors generated from the active wallpaper palette",
    `primary="${c.primary}"`,
    `secondary="${c.secondary}"`,
    `tertiary="${c.tertiary}"`,
    `tertiary_container="${c.tertiaryContainer}"`,
    `secondary_container="${c.secondaryContainer}"`,
    `error="${c.error}"`,
    `on_surface_variant="${c.onSurfaceVariant}"`,
    "",
    "# Template placeholders",
    'export LP_SEPARATOR=""',
    'export LP_LEFT_EDGE_SYMBOL=""',
    'export OS_BG=""',
    'export OS_FG="$primary"',
    'export DIR_PATH_BG=""',
    'export DIR_PATH_FG="$primary"',
    'export GIT_BG=""',
    'export GIT_FG="$secondary"',
    'export ENV_BG=""',
    'export ENV_FG="$tertiary_container"',
    'export LP_RIGHT_EDGE_SYMBOL=""',
    'export CMD_DURATION_FG="$on_surface_variant"',
    'export FILL_FG="$on_surface_variant"',
    'export FILL_SYMBOL=""',
    'export RP_SEPARATOR="  "',
    'export RP_LEFT_EDGE_SYMBOL=""',
    'export BATTERY_BG=""',
    'export BATTERY_FG="$on_surface_variant"',
    'export HOSTNAME_BG=""',
    'export HOSTNAME_FG="$tertiary"',
    'export TIME_BG=""',
    'export TIME_FG="$on_surface_variant"',
    'export RP_RIGHT_EDGE_SYMBOL=""',
    'export CHAR_SUCCESS_FG="$tertiary"',
    'export CHAR_SUCCESS_SYMBOL="◆"',
    'export CHAR_ERROR_FG="$error"',
    'export CHAR_ERROR_SYMBOL="◆"',
    'export CHAR_VIM_FG="$secondary_container"',
    'export CHAR_VIM_SYMBOL="◆"',
    'export CHAR_VIM_REPLACE_ONE_FG="$tertiary_container"',
    'export CHAR_VIM_REPLACE_ONE_SYMBOL="◆"',
    'export CHAR_VIM_REPLACE_FG="$primary"',
    'export CHAR_VIM_REPLACE_SYMBOL="◆"',
    'export CHAR_VIM_VISUAL_FG="$tertiary"',
    'export CHAR_VIM_VISUAL_SYMBOL="◆"',
    'export USERNAME_USER_BG=""',
    'export USERNAME_USER_FG="$on_surface_variant"',
    'export USERNAME_ROOT_BG=""',
    'export USERNAME_ROOT_FG="$on_surface_variant"',
    'export DOCKER_BG=""',
    'export DOCKER_FG="$on_surface_variant"',
    "",
  ].join("\n");
}

const STARSHIP_EXPORTS = [
  "LP_SEPARATOR",
  "LP_LEFT_EDGE_SYMBOL",
  "OS_BG",
  "OS_FG",
  "DIR_PATH_BG",
  "DIR_PATH_FG",
  "GIT_BG",
  "GIT_FG",
  "ENV_BG",
  "ENV_FG",
  "LP_RIGHT_EDGE_SYMBOL",
  "CMD_DURATION_FG",
  "FILL_FG",
  "FILL_SYMBOL",
  "RP_SEPARATOR",
  "RP_LEFT_EDGE_SYMBOL",
  "BATTERY_BG",
  "BATTERY_FG",
  "HOSTNAME_BG",
  "HOSTNAME_FG",
  "TIME_BG",
  "TIME_FG",
  "RP_RIGHT_EDGE_SYMBOL",
  "CHAR_SUCCESS_FG",
  "CHAR_SUCCESS_SYMBOL",
  "CHAR_ERROR_FG",
  "CHAR_ERROR_SYMBOL",
  "CHAR_VIM_FG",
  "CHAR_VIM_SYMBOL",
  "CHAR_VIM_REPLACE_ONE_FG",
  "CHAR_VIM_REPLACE_ONE_SYMBOL",
  "CHAR_VIM_REPLACE_FG",
  "CHAR_VIM_REPLACE_SYMBOL",
  "CHAR_VIM_VISUAL_FG",
  "CHAR_VIM_VISUAL_SYMBOL",
  "USERNAME_USER_BG",
  "USERNAME_USER_FG",
  "USERNAME_ROOT_BG",
  "USERNAME_ROOT_FG",
  "DOCKER_BG",
  "DOCKER_FG",
];

function tmuxConf(c) {
  return [
    "# tmux colors generated from the active wallpaper palette",
    `set -g @bg "default"`,
    `set -g @default_fg "${c.foreground}"`,
    `set -g @pane_border_fg "${c.outlineVariant}"`,
    `set -g @active_pane_border "${c.surfaceVariant}"`,
    `set -g @session_bg "default"`,
    `set -g @session_fg "${c.primary}"`,
    `set -g @session_selection_fg "${c.secondary}"`,
    `set -g @session_selection_bg "${c.surfaceVariant}"`,
    `set -g @window_index_fg "${c.outline}"`,
    `set -g @window_index_bg "default"`,
    `set -g @window_fg "${c.outline}"`,
    `set -g @window_bg "default"`,
    `set -g @active_window_fg "${c.secondary}"`,
    `set -g @active_window_bg "default"`,
    `set -g @prev_window_fg "${c.outline}"`,
    `set -g @prev_window_bg "default"`,
    `set -g @status_fg "${c.outline}"`,
    `set -g @status_icon_fg "${c.secondary}"`,
    `set -g @status_bg "default"`,
    `set -g @mode_fg "${c.background}"`,
    `set -g @mode_bg "${c.secondaryContainer}"`,
    `set -g @command_fg "default"`,
    `set -g @command_bg "default"`,
    `set -g @message_fg "${c.secondaryContainer}"`,
    `set -g @message_bg "default"`,
    "",
  ].join("\n");
}

function opencodeJson(c) {
  const palette = {
    background: c.background,
    surface_container: c.surfaceContainer,
    surface_container_low: c.surfaceContainerLow,
    surface_variant: c.surfaceVariant,
    primary_container: c.primaryContainer,
    on_background: c.foreground,
    on_surface_variant: c.onSurfaceVariant,
    outline: c.outline,
    secondary: c.secondary,
    tertiary: c.tertiary,
    secondary_container: c.secondaryContainer,
    tertiary_container: c.tertiaryContainer,
    error: c.error,
    on_primary_container: c.onPrimaryContainer,
    on_tertiary_container: c.onTertiaryContainer,
    on_secondary_container: c.onSecondaryContainer,
    primary: c.primary,
  };
  const theme = {
    primary: { dark: "primary", light: "primary" },
    secondary: { dark: "secondary", light: "secondary" },
    accent: { dark: "tertiary", light: "tertiary" },
    error: { dark: "error", light: "error" },
    warning: { dark: "tertiary", light: "tertiary" },
    success: { dark: "secondary", light: "secondary" },
    info: { dark: "primary", light: "primary" },
    text: { dark: "on_background", light: "on_background" },
    textMuted: { dark: "outline", light: "outline" },
    background: { dark: "background", light: "background" },
    backgroundPanel: { dark: "surface_container", light: "surface_container" },
    backgroundElement: {
      dark: "surface_container_low",
      light: "surface_container_low",
    },
    border: { dark: "outline", light: "outline" },
    borderActive: { dark: "primary", light: "primary" },
    borderSubtle: { dark: "outline", light: "outline" },
    diffAdded: { dark: "tertiary", light: "tertiary" },
    diffRemoved: { dark: "error", light: "error" },
    diffContext: { dark: "outline", light: "outline" },
    diffHunkHeader: { dark: "outline", light: "outline" },
    diffHighlightAdded: {
      dark: "on_tertiary_container",
      light: "on_tertiary_container",
    },
    diffHighlightRemoved: { dark: "error", light: "error" },
    diffAddedBg: {
      dark: "surface_container_low",
      light: "surface_container_low",
    },
    diffRemovedBg: {
      dark: "surface_container_low",
      light: "surface_container_low",
    },
    diffContextBg: { dark: "surface_container", light: "surface_container" },
    diffLineNumber: { dark: "outline", light: "outline" },
    diffAddedLineNumberBg: {
      dark: "surface_container_low",
      light: "surface_container_low",
    },
    diffRemovedLineNumberBg: {
      dark: "surface_container_low",
      light: "surface_container_low",
    },
    markdownText: { dark: "on_background", light: "on_background" },
    markdownHeading: { dark: "primary", light: "primary" },
    markdownLink: { dark: "secondary", light: "secondary" },
    markdownLinkText: { dark: "tertiary", light: "tertiary" },
    markdownCode: {
      dark: "on_tertiary_container",
      light: "on_tertiary_container",
    },
    markdownBlockQuote: { dark: "outline", light: "outline" },
    markdownEmph: {
      dark: "on_secondary_container",
      light: "on_secondary_container",
    },
    markdownStrong: {
      dark: "on_primary_container",
      light: "on_primary_container",
    },
    markdownHorizontalRule: { dark: "outline", light: "outline" },
    markdownListItem: { dark: "primary", light: "primary" },
    markdownListEnumeration: { dark: "tertiary", light: "tertiary" },
    markdownImage: { dark: "secondary", light: "secondary" },
    markdownImageText: { dark: "tertiary", light: "tertiary" },
    markdownCodeBlock: { dark: "on_background", light: "on_background" },
    syntaxComment: { dark: "outline", light: "outline" },
    syntaxKeyword: { dark: "tertiary", light: "tertiary" },
    syntaxFunction: { dark: "tertiary", light: "tertiary" },
    syntaxVariable: { dark: "secondary", light: "secondary" },
    syntaxString: {
      dark: "on_primary_container",
      light: "on_primary_container",
    },
    syntaxNumber: { dark: "error", light: "error" },
    syntaxType: {
      dark: "on_secondary_container",
      light: "on_secondary_container",
    },
    syntaxOperator: { dark: "tertiary", light: "tertiary" },
    syntaxPunctuation: {
      dark: "on_surface_variant",
      light: "on_surface_variant",
    },
  };
  return (
    JSON.stringify(
      { $schema: "https://opencode.ai/theme.json", defs: palette, theme },
      null,
      2,
    ) + "\n"
  );
}

function nvimPalette(palette, variant) {
  const sorted = {};
  for (const role of Object.keys(palette).sort())
    sorted[role] = hex(palette[role]);
  return (
    JSON.stringify(
      { schema: "qe-nvim-palette", version: 1, variant, colors: sorted },
      null,
      2,
    ) + "\n"
  );
}

const TARGETS = [
  {
    id: "kitty",
    executable: "kitty",
    path: (b, c) => `${b.config}/kitty/themes/wallpaper.conf`,
    generate: kittyTheme,
  },
  {
    id: "bat",
    executable: "bat",
    path: (b, c) => `${b.config}/bat/themes/wallpaper.tmTheme`,
    generate: batTheme,
  },
  {
    id: "btop",
    executable: "btop",
    path: (b, c) => `${b.config}/btop/themes/wallpaper.theme`,
    generate: btopTheme,
  },
  {
    id: "eza",
    executable: "eza",
    path: (b, c) => `${b.config}/eza/themes/wallpaper.yml`,
    generate: ezaYml,
  },
  {
    id: "dunst",
    executable: "dunst",
    path: (b, c) => `${b.config}/dunst/themes/wallpaper.conf`,
    generate: dunstTheme,
  },
  {
    id: "fzf",
    executable: "fzf",
    path: (b, c) => `${b.zshConfig}/fzf_themes/wallpaper.zsh`,
    generate: fzfZsh,
  },
  {
    id: "hyprland",
    executable: "Hyprland",
    path: (b, c) => `${b.config}/hypr/themes/hyprland/wallpaper.lua`,
    generate: hyprlandLua,
  },
  {
    id: "hyprlock",
    executable: "hyprlock",
    path: (b, c) => `${b.config}/hypr/themes/hyprlock/wallpaper.conf`,
    generate: hyprlockConf,
  },
  {
    id: "rofi",
    executable: "rofi",
    path: (b, c) => `${b.config}/rofi/themes/colorschemes/wallpaper.rasi`,
    generate: rofiRasi,
  },
  {
    id: "starship",
    executable: "starship",
    path: (b, c) => `${b.config}/starship/themes/wallpaper.sh`,
    generate: starshipSh,
  },
  {
    id: "tmux",
    executable: "tmux",
    path: (b, c) => `${b.config}/tmux/themes/wallpaper.conf`,
    generate: tmuxConf,
  },
  {
    id: "opencode",
    executable: "opencode",
    path: (b, c) => `${b.config}/opencode/themes/wallpaper.json`,
    generate: opencodeJson,
  },
  {
    id: "nvim",
    executable: "nvim",
    path: (b, c) => `${b.cache}/matugen/nvim-colors.json`,
    generate: (code, palette, variant) => nvimPalette(palette, variant),
  },
  {
    id: "yazi_palette",
    executable: "yazi",
    path: (b, c) => `${b.config}/yazi/flavors/wallpaper.yazi/wallpaper.sh`,
    generate: yaziPalette,
  },
  {
    id: "yazi_tmtheme",
    executable: "yazi",
    path: (b, c) => `${b.config}/yazi/flavors/wallpaper.yazi/tmtheme.xml`,
    generate: yaziTmTheme,
  },
];

const ABSOLUTE_PATH_PATTERN = /^\/(?:[^/]+\/)*[^/]+$/;

export function generateWallpaperExternalTargets(
  palette,
  bases,
  variant = "dark",
) {
  const errors = [];
  if (palette === null || typeof palette !== "object" || Array.isArray(palette))
    return {
      ok: false,
      errors: ["external wallpaper theme: palette must be an object"],
      targets: [],
    };
  if (
    !HEX_PATTERN.test(palette.background) ||
    !HEX_PATTERN.test(palette.on_background)
  )
    return {
      ok: false,
      errors: [
        "external wallpaper theme: palette must contain background and foreground hex colors",
      ],
      targets: [],
    };
  if (
    bases === null ||
    typeof bases !== "object" ||
    typeof bases.home !== "string" ||
    typeof bases.config !== "string" ||
    typeof bases.zshConfig !== "string" ||
    typeof bases.cache !== "string"
  ) {
    return {
      ok: false,
      errors: [
        "external wallpaper theme: bases must include home, config, zshConfig, and cache directories",
      ],
      targets: [],
    };
  }

  const code = buildCode(palette);
  const targets = TARGETS.map((target) => {
    const path = target.path(bases, code);
    const content = target.generate(code, palette, variant);
    return { id: target.id, executable: target.executable, path, content };
  });

  if (
    !targets.every(
      (target) =>
        ABSOLUTE_PATH_PATTERN.test(target.path) &&
        !target.path.split("/").includes(".."),
    )
  ) {
    errors.push(
      "external wallpaper theme: all target paths must be absolute and cannot contain '..'",
    );
  }
  if (!targets.every((target) => /^[a-z0-9_]+$/.test(target.id))) {
    errors.push("external wallpaper theme: target ids must match ^[a-z0-9_]+$");
  }
  for (const target of targets) {
    if (typeof target.content !== "string" || target.content.length === 0)
      errors.push(
        `external wallpaper theme target '${target.id}': generated content must be non-empty`,
      );
  }

  return { ok: errors.length === 0, errors, targets };
}

export function validateExternalTargetContent(target) {
  if (
    target === null ||
    typeof target !== "object" ||
    typeof target.id !== "string" ||
    !ABSOLUTE_PATH_PATTERN.test(target.path) ||
    typeof target.content !== "string"
  )
    return `target '${target.id}': invalid shape`;
  if (target.content.length === 0)
    return `target '${target.id}': generated content is empty`;
  const checks = [
    { id: "kitty", probe: /^color0 #/m },
    { id: "bat", probe: /<\/plist>/ },
    { id: "btop", probe: /theme\[main_bg\]/ },
    { id: "eza", probe: /^colourful: false/m },
    { id: "dunst", probe: /^\[urgency_low\]/m },
    { id: "fzf", probe: /--color=fg:/ },
    { id: "hyprland", probe: /hl\.config\(/ },
    { id: "hyprlock", probe: /^\$background/m },
    { id: "rofi", probe: /@on-background;/ },
    { id: "starship", probe: /^export OS_BG=/m },
    { id: "tmux", probe: /^set -g @default_fg/m },
    { id: "opencode", probe: /"defs"/ },
    { id: "nvim", probe: /"schema":\s*"qe-nvim-palette"/ },
    { id: "yazi_palette", probe: /^export BACKGROUND=/m },
    { id: "yazi_tmtheme", probe: /<\/plist>/ },
  ];
  const check = checks.find((entry) => entry.id === target.id);
  if (
    target.id === "starship" &&
    !STARSHIP_EXPORTS.every((name) =>
      new RegExp(`^export ${name}=`, "m").test(target.content),
    )
  )
    return "target 'starship': generated content is missing a template placeholder export";
  if (check && !check.probe.test(target.content))
    return `target '${target.id}': generated content failed format validation`;
  return null;
}
