# Theme and Wallpaper Architecture

Authoritative for QE theme scopes, semantic roles, schema and fallback behavior, Matugen generation, wallpaper-theme promotion, and external-theme application contracts.

## Theme Architecture

### Theme scopes

There are two independent theme scopes:

- QE theme: owned and persisted by `ThemeService`
- external desktop theme: owned and persisted by the external theme switcher

Selecting a QE theme automatically requests the same ID externally after QE
succeeds. External failure does not invalidate QE success. The selector shows
QE success and external warning separately. Running the external switcher from
the CLI may change external applications without changing QE.

### Theme schema

Every authored and generated QE theme uses the same versioned strict JSON
contract. The current shape is:

```json
{
  "schemaVersion": 1,
  "id": "poimandres",
  "name": "Poimandres",
  "variant": "dark",
  "palette": {
    "background": "#1b1e28",
    "foreground": "#e4f0fb",
    "muted": "#8290a5",
    "black": "#171922",
    "surfaceContainerLowest": "#171a24",
    "surfaceContainerLow": "#232630",
    "surfaceContainer": "#272a35",
    "surfaceContainerHigh": "#323540",
    "surfaceContainerHighest": "#3e404b",
    "surfaceBright": "#424550",
    "gray": "#303340",
    "grayLight": "#41434F",
    "blueGrayDark": "#506477",
    "blueGray": "#7390aa",
    "blueGrayLight": "#91B4D5",
    "blue": "#add7ff",
    "cyan": "#89DDFF",
    "purple": "#767C9D",
    "purpleLight": "#a6accd",
    "pink": "#fcc5e9",
    "red": "#d0679d",
    "green": "#5fb3a1",
    "greenLight": "#5de4c7",
    "yellow": "#fffac2"
  },
  "tokens": {
    "background": "{palette.background}",
    "on_background": "{palette.foreground}",
    "surface": "{palette.background}",
    "on_surface": "{palette.foreground}",
    "on_surface_subdued": "{palette.muted}",
    "on_surface_indicator": "{palette.blueGray}",
    "surface_container_lowest": "{palette.surfaceContainerLowest}",
    "surface_container_low": "{palette.surfaceContainerLow}",
    "surface_container": "{palette.surfaceContainer}",
    "surface_container_high": "{palette.surfaceContainerHigh}",
    "surface_container_highest": "{palette.surfaceContainerHighest}",
    "surface_variant": "{palette.gray}",
    "on_surface_variant": "{palette.purpleLight}",
    "surface_panel": "#f21b1e28",
    "surface_sidebar": "#171922",
    "surface_low": "#171922",
    "on_surface_panel": "{palette.foreground}",
    "surface_tooltip": "{palette.black}",
    "on_surface_tooltip": "{palette.muted}",
    "surface_hover": "{palette.surfaceBright}",
    "surface_pressed": "{palette.blueGrayDark}",
    "primary": "{palette.green}",
    "on_primary": "{palette.black}",
    "primary_container": "{palette.blueGray}",
    "on_primary_container": "{palette.black}",
    "secondary": "{palette.blueGray}",
    "on_secondary": "{palette.black}",
    "outline": "{palette.purple}",
    "outline_variant": "{palette.blueGrayDark}",
    "focus_ring": "{palette.cyan}",
    "on_surface_disabled": "{palette.blueGrayDark}",
    "on_surface_placeholder": "{palette.muted}",
    "link": "{palette.cyan}",
    "highlight": "{palette.yellow}",
    "on_highlight": "{palette.black}",
    "success": "{palette.greenLight}",
    "warning": "{palette.yellow}",
    "error": "{palette.red}",
    "shadow": "#80000000",
    "scrim": "#99000000",
    "charging": "{palette.yellow}"
  }
}
```

The approved 41-role token names use Matugen-style `snake_case` and paired
`on_*` foregrounds. ADR-015 records the pre-release contract revision
that supersedes the provisional vocabulary and the individual additions in
ADR-012 and ADR-014 while retaining their charging and tooltip semantics.
Any explicit pre-release contract revision is recorded in an ADR and updates all
themes, fixtures, fallbacks, and validators together. Token references are
resolved once by pure validation logic; normal components consume resolved
semantic tokens only.

An `on_*` role is foreground content intended for its named surface or accent;
for example, `on_surface_variant` is paired with `surface_variant`, not a
generic lower-emphasis form of `on_surface`. `on_surface_subdued` is enabled,
lower-emphasis text content on QE's ordinary neutral surface family.
`on_surface_indicator` is enabled neutral compact indicator and iconographic
content on that surface family, allowing optical prominence above subdued text
without borrowing the `secondary` accent role.
`on_surface_disabled` is reserved for genuinely unavailable controls, and
`on_surface_placeholder` remains specific to editable hints. Boundaries use
`outline` or `outline_variant` rather than a content role. A theme may map
different semantic roles to the same color; semantic independence and required
contrast, not unique color count, define conformance.

Raw palette names describe source colors. Semantic tokens describe UI roles.
Normal components never consume palette entries directly, which allows Matugen
and manually authored palettes to map different raw vocabularies to the same UI.
The palette viewer is an explicit inspection surface and may display any validated
catalog theme's raw palette and resolved tokens without applying that theme.
Its selected theme is view-local and its viewer chrome remains styled by the
active QE theme.

Authored and generated `on_*` pairs target at least 4.5:1 contrast for normal
text. Meaningful icons, focus indicators, and strong boundaries target at least
3:1 against their intended surface. `surface_panel` and `surface_sidebar` may
contain alpha, so static validation composites them over the theme background;
live acceptance also checks
representative wallpapers because no fixed foreground can guarantee contrast
over every external image.
`on_surface_subdued` targets 4.5:1 against background, surface, low, sidebar,
and the panel composited over the theme background. Normal action foregrounds
also target 4.5:1 on hover and pressed surfaces so text-bearing controls remain
readable.
`on_surface_indicator` has the same 4.5:1 neutral-surface targets; themes may map
it to the same color as another role when their authored palette has no useful
intermediate value.

The five `surface_container*` roles form an ordered Material neutral-surface
hierarchy. Generated Wallpaper themes map them directly from Matugen's
same-named palette roles. Authored themes store static derived colors: generation
converts the authored `surface` to Material HCT, retains its requested hue and
chroma, adds the standard-contrast tone delta, clamps tone to `[0, 100]`, and
uses Material's sRGB gamut solver. The dark deltas for lowest, low, container,
high, and highest are respectively `-2`, `+4`, `+6`, `+11`, and `+16`; the
light deltas are `+2`, `-2`, `-4`, `-6`, and `-8`. Gamut conversion may reduce
realized chroma. Ordinary content on these surfaces uses `on_surface` and keeps
the normal 4.5:1 text target.

`surface_hover` remains an interaction-state role rather than a container alias.
Wallpaper themes map it from Matugen `surface_bright`. Authored dark themes
derive it from `surface` with the corresponding `+18` HCT tone delta; the light
delta is zero. This does not change `surface_pressed`, `surface_sidebar`, or
`surface_low`.

Typography, spacing, radii, border widths, shadows parameters, opacity policy,
and animation durations belong to user configuration initially, not individual
color themes. Color-valued shadow, scrim, panel-alpha, and interaction-state
tokens remain in themes.
This prevents theme changes from unexpectedly altering layout and motion. A
future theme schema may add explicit style profiles through a migration.

### Validation and fallback

- Reject unknown schema versions.
- Require unique normalized IDs and all mandatory semantic tokens.
- Accept only validated color strings and supported variants.
- Resolve references with cycle detection.
- Exclude invalid catalog entries and report their path and validation errors.
- Never partially publish a theme.
- Keep the current last-known-good theme if its source becomes invalid.
- At cold start, use the persisted active ID, then configured default, then a
  built-in minimal emergency palette embedded in `ThemeService`.

The emergency palette is fallback code, not an independently editable theme.
The isolated lock reader has a separate fail-safe opaque-black palette for the
case where no validated persisted theme can be loaded. That lock-only safety
fallback is not the active QE theme and is intentionally independent of the
main `ThemeService` module graph.

### Reactive propagation

`ThemeService` publishes one resolved theme object/property set. All windows and
components bind to semantic properties from that service. Existing windows
update without recreation. No component copies theme colors into local mutable
properties unless the copy is temporary animation state.

### Matugen

Matugen is an external generator, not a runtime source of live state.

- Input: validated selected wallpaper path and explicit dark/light mode.
- Command: array arguments; no shell interpolation.
- Output: staging directory containing QE `Wallpaper` JSON and configured
  external application artifacts.
- Validation: QE schema plus target-specific validators before promotion.
- Promotion: atomic replace per artifact where supported.
- Failure: preserve the complete previous last-known-good generated set.
- Hooks: not used for opaque application orchestration; QE and the external
  switcher control apply order and observe results.

Matugen's JSON output or templates are mapped into QE semantic tokens by a
versioned template. The generated `Wallpaper` file is derived data and is never
edited by users. User overrides, if later needed, must be a separate authored
input layered before generation rather than edits to generated output.

Wallpaper generation also captures the focused Kitty appearance at apply time.
`scripts/qe-window-opacity.sh` reads Kitty's effective `background_opacity`,
including nested includes, and queries Hyprland's live
`decoration:active_opacity` through `hyprctl`. Missing, unavailable, malformed,
or out-of-range upstream values fall back to `1.0`; the snapshot is not watched
at runtime. The generated wallpaper `surface_panel` uses the palette background
with the product of those opacities as its alpha. `surface_sidebar` applies the
same alpha to a hue-preserving HSL darkening of the palette background by 9/255
lightness units, matching the measured difference between `#282828` and
`#1d2021`. Later upstream config changes take effect on the next wallpaper-theme
generation or application.

The current adapter boundary requires `QE_MATUGEN` to name the executable; an
unset or missing executable is an isolated unavailable state. `MatugenAdapter`
requests noninteractive JSON output with an explicit mode and source-color
preference, bounds the process, and validates the mapped 41-role theme before
the service stages it. `WallpaperPromotionAdapter` then promotes the staged QE
`Wallpaper.json` into its stable XDG data path, preserving the previous artifact
when staging or promotion fails. External Matugen artifacts use the separate
validated promotion contract described below.

The compatibility wallpaper boundary requires `QE_WALLPAPER_HELPER` and passes
the selected path as a discrete argument. The QE `qe-wallpaper` helper first
asks Hyprpaper to display the original source, then normalizes only the
`current_wallpaper.png` last-known-good artifact with an atomic promotion. It
does not kill or restart a healthy Hyprpaper process. A successful helper result confirms
Hyprpaper IPC acceptance and LKG promotion, not pixel display;
`WallpaperService` therefore keeps requested, applied, and generation state
separate. The legacy `wallpaper` and `select_wallpaper` commands are retired
because they bypassed confirmed WallpaperService state; no compatibility aliases
replace them.

The lock process reads the validated active QE theme from the shared
process-independent state file and reads the validated selected wallpaper before acquiring
`WlSessionLock`, preloads a bounded image, and detaches its state reader. Each
lock surface synchronously loads that warmed source cache with
`Image.PreserveAspectCrop` and
`autoTransform`, followed by a transparent-to-black vertical gradient; the
complete composition is then blurred with a cached Gaussian blur (radius 12,
25 samples). Invalid, missing, or undecodable wallpaper input leaves the lock
on its opaque fallback.

Lock presentation follows the retired Hyprlock composition without retaining
its command-backed status reads: bold Roboto at 149px renders the 12-hour time
in the bottom-left, with bold 36px weekday and ordinal date above it. The clock
uses its tight glyph bounds and the section uses font descent compensation so
the visible clock aligns at 60px without shifting the weekday/date. A centered
password field remains the only interactive element. A lock-local
native UPower reader exposes confirmed display-battery percentage to a
bottom-right bold 54px label and Material Symbols icon; the entire battery block
is hidden when UPower has no laptop battery.

QE also owns a localized wallpaper selector
(`modules/wallpaper/WallpaperSelector.qml`) opened through the `qe-wallpaper`
  IPC target. It uses QE-owned thumbnail cache and apply state, remains open after
  a successful apply, and reuses the same apply/generation pipeline as the helper.
The Hyprpaper configuration resolves its image path through `$XDG_DATA_HOME`
with a `$HOME/.local/share` fallback so the Hyprpaper config and QE helper stay
aligned. Temporary `.desktop` entries launch the theme
and wallpaper selectors through `scripts/qe-launch.sh`, which resolves the
managed checkout and calls the corresponding IPC target through Quickshell's
path-scoped lookup; these launchers remain available for direct access alongside
the control-center entry points.

When the active QE theme is the generated `wallpaper` theme, QE also generates
standalone "wallpaper" theme slot files for external applications and the
external switcher applies them. `ExternalWallpaperTheme` maps the same Matugen
Material palette into per-application formats (kitty, bat, btop, eza, dunst,
fzf, hyprland, imv, mpv, rofi, starship, tmux, opencode, and Yazi's
semantic palette plus TextMate syntax file, and a Palette JSON for Neovim), and
`WallpaperExternalThemeAdapter` materializes them through
`scripts/promote-external-theme.sh`, which writes each file into the
app-specific `wallpaper` slot with staging and atomic same-filesystem
replacement, skipping targets whose executables are absent, preserving unchanged
files, and reporting per-target results. Stow-managed installations keep these
live slots as ignored, restore-managed symlinks to XDG state; promotion resolves
the link before replacing the runtime target so the QE repository's authored
defaults remain separate from runtime state. The explicit `qe-defaults restore`
operation preflights and restores the generated QE theme, wallpaper image,
Neovim palette, and external slots before creating or repairing the live links.
It applies the manifest's default theme through running QE or, when QE is
absent, directly through the external switcher. A missing or failed switcher
leaves restored files in place and reports the failure. `capture` is the only
operation that updates the authored default bundle. Installation uses
`qe-defaults seed`, which creates only missing first-frame runtime artifacts and
recognized links, excludes the retired Dunst theme slot, and neither applies the
manifest theme nor writes confirmed wallpaper selection.
QE never writes an app's active configuration; the external switcher owns that
copy. After promotion succeeds, QE delegates external application to the
switcher with `--machine --theme wallpaper --skip-gtk` (GTK is excluded because
Matugen does not generate GTK themes). Applying a wallpaper always regenerates
QE's validated `Wallpaper` theme and the external slot files so the generated
"wallpaper" theme becomes selectable, but QE delegates external application
only while the wallpaper theme is active, so a wallpaper change never overwrites
fixed external themes. Neovim consumes the generated palette through a local
`colors/wallpaper.vim` colorscheme that reloads the palette on every
`:colorscheme wallpaper`, so the switcher's existing name-based Neovim apply
path works without an extra plugin. The generated catalog entry is re-read
after atomic replacement so repeated wallpaper generations update the live
catalog without a QE restart. Selecting `wallpaper` defers external switcher
dispatch until its generation/promotion phase completes, preventing duplicate
external requests from racing one another. A wallpaper change issued while a
generation is in flight is queued as the latest requested path instead of being
dropped, and regenerating the already-published theme skips the redundant
promotion while still running the external dispatch phase.

### External theme switcher contract

The switcher remains usable independently and exposes this stable
machine-facing interface:

```text
run.sh --machine --theme <id> [--skip-gtk]
```

Required contract:

- validate IDs against a catalog; reject path traversal and arbitrary names
- accept arguments as discrete values
- never require QE to parse human log lines
- emit one versioned JSON result with per-target status
- reserve stdout for structured output in machine mode and stderr for logs
- return distinct codes for success, partial failure, invalid request, and
  orchestrator failure
- support bounded execution and TERM handling
- persist external active theme only according to documented external policy
- skip targets retired by QE without deleting their source themes
- avoid automatically opening a wallpaper picker for QE-issued requests

Machine mode exits 0 for success, 3 for partial application, 4 for failed
application or orchestration, and 2 for usage. It atomically writes the same
successful persistence document to
`${XDG_STATE_HOME:-$HOME/.local/state}/theme-switcher/active-theme.json`; this
switcher-owned document contains no QE operation identity. Per ADR-017, QE
assigns operation IDs at its adapter boundary, serializes requests through the
bounded process phase, and uses those IDs only to associate direct command
results. Independent state-file updates report external state but never complete
a QE operation or overwrite the active QE theme.

`ExternalThemeAdapter` resolves the executable from `QE_THEME_SWITCHER`. An
unset, missing, or removed executable is an isolated unavailable state rather
than a startup failure; QE does not assume an external repository location.

External application is best effort. Partial application is retained and
reported; global rollback is not attempted because many targets cannot be
reverted atomically and rollback can also fail.
