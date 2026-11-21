# ADR-019: QE-generated external wallpaper theme slots

Status: Not explicitly stated in source record

Context: the architecture promised Matugen output that includes "configured
external application artifacts", but the external target contracts were not
approved. The accepted model is that QE owns generation and the external
theme-switcher owns external application, so QE must produce theme files the
switcher's existing apply scripts consume without writing any live config.

Decision: while the active QE theme is `wallpaper`, QE maps the captured
Matugen palette into a `wallpaper` theme slot per supported app and promotes
each file atomically into the app-specific slot (kitty, bat, btop, eza, dunst,
 fzf, hyprland, imv, mpv, rofi, starship, tmux, opencode, and Yazi)
plus an nvim palette JSON under XDG cache for the local `colors/wallpaper.vim`
colorscheme. `WallpaperExternalThemeAdapter` materializes a validated spec via
`scripts/promote-external-theme.sh`, skips targets whose executables are
absent, and reports per-target results. QE never writes active application
configuration; after promotion it delegates `--machine --theme wallpaper
--skip-gtk` to the switcher, which performs the documented copy-to-active.
imv and mpv consume generated background slots, while Yazi consumes its
generated semantic palette and syntax file.
GTK is excluded because Matugen has no GTK generator.

Rationale: this preserves standalone switcher function, avoids two owners of
the same live config, and keeps "wallpaper" a normal theme ID from the
switcher's perspective. Applying a wallpaper always regenerates the QE
Wallpaper theme and slot files so the generated theme stays selectable;
external application is delegated only while the wallpaper theme is active,
which prevents a wallpaper change from overwriting fixed external themes.

Alternatives considered: QE writing external live configs directly (creates
file contention with the switcher); Matugen native template output (rejected
in favor of QE-owned generation); installing `matugen.nvim` for nvim
(extra plugin dependency and palette-format coupling; the local colorscheme
avoids both while remaining swappable for the plugin later).

Consequences: external slot files are derived data written into app config
trees by approved contract; failed or skipped targets are reported without
rolling back already-promoted files. Promotion is content-idempotent and
follows restore-managed slot symlinks, so generation never rewrites a tracked
default. The QE repository keeps authored defaults under `defaults/wallpaper`.
The preflighted `qe-defaults restore` command restores the stable XDG QE theme,
  wallpaper image, Neovim palette, and external runtime files before
creating or repairing ignored live slot links; `capture` is the intentional
default-change operation. This makes
the generated QE `wallpaper` theme selectable before the first wallpaper
selection on a fresh installation. The self-contained nvim colorscheme means
neovim follows the wallpaper only while the wallpaper theme is active. The
generated catalog is refreshed after atomic replacement, and wallpaper
external application has one generation-completion dispatch point to avoid
concurrent switcher requests. Generated QE tokens use `#AARRGGBB` alpha to
match authored themes, and the generated `wallpaper` rofi colorscheme defines
the full variable set the main rofi theme references. opencode loads and caches
its theme colors at launch, so a regenerated wallpaper theme requires an
opencode restart even when the switcher live-re-selects the theme name in
tmux-hosted instances. imv, mpv, and Yazi similarly require new instances to
load regenerated configuration.

Affected areas: `ExternalWallpaperTheme.mjs`, `WallpaperExternalThemeAdapter`,
`promote-external-theme.sh`, `WallpaperService`, `ThemeService`,
`ExternalThemeAdapter`, nvim `colors/wallpaper.vim`, and Phase 4 fixtures.

Revisit if: an external app changes its theme slot layout, a target needs
cross-filesystem promotion, or the user selects `matugen.nvim` as the nvim
consumer.
