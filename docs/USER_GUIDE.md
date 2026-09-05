# Quickshell Environment User Guide

## Table of Contents

- [1. What Is QE?](#1-what-is-qe)
- [2. Dependencies and Integrations](#2-dependencies-and-integrations)
  - [Software Dependencies](#software-dependencies)
  - [Optional Application Dependencies](#optional-application-dependencies)
  - [Local Integrations](#local-integrations)
  - [Paths and Environment Variables](#paths-and-environment-variables)
  - [Current Limitations](#current-limitations)
- [3. Setting Up](#3-setting-up)
  - [Install Packages](#install-packages)
  - [Clone the Projects](#clone-the-projects)
  - [Stow the Dotfiles](#stow-the-dotfiles)
  - [Restore the QE Defaults](#restore-the-qe-defaults)
  - [Start QE](#start-qe)
- [4. Themes](#4-themes)
  - [Adding a New Theme](#adding-a-new-theme)
  - [Modifying an Existing Theme](#modifying-an-existing-theme)
  - [Modifying the Wallpaper Theme](#modifying-the-wallpaper-theme)
  - [Selecting a Theme](#selecting-a-theme)
- [5. Changing the Default Theme and Wallpaper](#5-changing-the-default-theme-and-wallpaper)
  - [Default Theme](#default-theme)
  - [Default Wallpaper Snapshot](#default-wallpaper-snapshot)
  - [Capture a New Default](#capture-a-new-default)
  - [Restore the Committed Default](#restore-the-committed-default)
- [6. Notifications and OSDs](#6-notifications-and-osds)
  - [Control Center](#control-center)
- [7. Help Entries](#7-help-entries)

## 1. What Is QE?

QE, the Quickshell Environment, is a desktop-shell platform for Hyprland on
Arch Linux. It is implemented as a long-lived Quickshell process rather than a
collection of unrelated widgets.

The current implementation provides:

- A system bar with workspaces, clock, tray, audio, battery, network,
  Bluetooth, brightness, idle-inhibitor, and system metrics modules.
- A validated QE theme catalog and live theme selector.
- A wallpaper selector for the current QE theme.
- Wallpaper processing through ImageMagick and Hyprpaper IPC.
- Matugen-generated wallpaper colors mapped into the QE theme schema.
- Generated wallpaper theme slots for supported external applications.
- IPC entry points for opening, closing, and toggling the theme and wallpaper
  selectors.
- Native desktop notifications with popup and current-session history.
- A notification center with dismiss controls and Do Not Disturb (DND).
- A centered control center opened with `Super+Tab`, with quick toggles for
  network, Bluetooth, audio, DND, and idle inhibition.
- Native hardware feedback OSDs for audio, brightness, media, network, and
  battery state.
- Screenshot notifications with actions to view the image or open its folder.

QE is still under active development. This guide documents supported
user-facing workflows and operational requirements, but it is not authoritative
for project status or remaining implementation phases. See `docs/PLAN.md` for
the current roadmap and status.

## 2. Dependencies and Integrations

### Software Dependencies

The following packages provide the core QE runtime and the current Hyprland
wallpaper pipeline:

```sh
sudo pacman -S --needed \
  git stow bash coreutils findutils procps-ng file jq imagemagick \
  quickshell hyprland hyprpaper hyprlock matugen \
  networkmanager bluez pipewire wireplumber upower brightnessctl \
  inter-font ttf-jetbrains-mono-nerd ttf-material-symbols-variable
```

Some of these are base-system utilities, and some support optional QE modules:

| Package | Purpose |
| --- | --- |
| `quickshell` | Runs the QE shell and provides the `qs` IPC client. |
| `hyprland` | Compositor and Hyprland IPC used by QE. |
| `hyprpaper` | Displays the processed wallpaper and accepts the confirmed wallpaper request. |
| `hyprlock` | Existing lock screen integration and lockscreen image consumer. |
| `matugen` | Generates the wallpaper color palette and `Wallpaper` theme. |
| `imagemagick` | Resizes wallpaper images and creates lockscreen images. |
| `jq` | Processes structured output used by wallpaper and external integrations. |
| `file` | Validates wallpaper input MIME types. |
| `procps-ng` | Provides process utilities used by the launch helpers. |
| `brightnessctl` | Brightness control helper used by the brightness adapter. |
| `inter-font`, `ttf-jetbrains-mono-nerd`, `ttf-material-symbols-variable` | Fonts used by the default QE appearance configuration. |

NetworkManager, BlueZ, PipeWire/WirePlumber, and UPower should be running in
the session for their corresponding modules to show live state. Missing
optional services degrade their modules without preventing the shell from
starting.

### Optional Application Dependencies

QE can generate or apply external themes for these applications when they are
installed and supported by the local theme-switcher configuration:

```text
bat, btop, dunst, eza, fzf, Hyprland, hyprlock, imv, kitty, mpv, Neovim,
OpenCode, rofi, starship, tmux, and Yazi
```

These applications are not all required to run QE. An unavailable application
is reported as an unavailable or skipped external target. Dunst is retired from
the active notification path and retained only in the dotfiles rollback archive;
the theme-switcher still knows about its target but skips it after cutover. GTK
is intentionally excluded from the Matugen wallpaper-theme apply because QE
does not generate a GTK theme.

### Local Integrations

QE expects the following local components when the related functionality is
enabled:

- The `theme-switcher` repository, normally at `~/Projects/theme-switcher`.
  It provides the external application apply scripts and the machine-mode
  interface used by QE.
- The dotfiles-provided `qe-theme-switcher` wrapper, which forwards QE's
  machine-mode requests to `theme-switcher`.
- The project-provided `qe-defaults` helper, which captures and restores the
  complete authored theme and wallpaper default bundle.
- The `qe-action` wrapper for allowlisted hardware and notification actions.
- The `qe-hyprshot` wrapper for screenshot notifications and actions.
- Hyprland configuration that starts Hyprpaper and the guarded QE launcher.
- Hyprpaper and Hyprlock configuration that reads the current image files from
  `$XDG_DATA_HOME`.
- A wallpaper collection arranged as
  `~/Pictures/Wallpaper/themes/<theme-id>/` unless `QE_WALLPAPER_ROOT` is set.

The current development setup uses `~/.local/bin/qe-shell` and
`~/.local/bin/qe-defaults` as helpers linked to scripts in
`~/Projects/quickshell`. These absolute development paths are intentional for
now. If QE is cloned elsewhere, update both helper links, or invoke the project
scripts directly, before using QE.

### Paths and Environment Variables

QE resolves runtime paths through XDG variables:

| Path or variable | Use |
| --- | --- |
| `XDG_DATA_HOME/current_wallpaper.png` | Processed image consumed by Hyprpaper. |
| `XDG_DATA_HOME/current_lockscreen.png` | Derived lockscreen image consumed by Hyprlock. |
| `XDG_DATA_HOME/qe/wallpaper/Wallpaper.json` | Stable generated QE wallpaper theme. |
| `XDG_STATE_HOME/qe/wallpaper/external/` | Runtime external wallpaper theme files. |
| `XDG_CACHE_HOME/matugen/nvim-colors.json` | Runtime Neovim wallpaper palette. |
| `QE_WALLPAPER_ROOT` | Overrides the wallpaper collection root. |
| `QE_MATUGEN` | Explicit Matugen executable; otherwise `run-qe.sh` discovers `matugen`. |
| `QE_WALLPAPER_HELPER` | Overrides the wallpaper apply helper. |
| `QE_THEME_SWITCHER` | Explicit external theme-switcher executable. |
| `QE_THEME_SWITCHER_REPO` | Repository path used by the `qe-theme-switcher` wrapper. |
| `ZSH_CONFIG_HOME` | Overrides the configuration directory used for the FZF theme slot. |

The default values are based on `$HOME` and the standard XDG directories. QE
does not require the current user's home directory to be hard-coded in the QE
source.

### Current Limitations

- QE is currently launched from the development checkout through
  `~/Projects/quickshell`.
- OpenCode loads and caches theme colors at launch. Regenerated wallpaper
  colors require an OpenCode restart.
- External theme application is best effort. QE can commit its own theme while
  an external target reports a partial or unavailable result.

## 3. Setting Up

### Install Packages

Install the core packages listed in [Software Dependencies](#software-dependencies).
Install any optional applications whose themes you want the external
theme-switcher to manage.

Make sure the user services needed by your session are enabled and available,
especially NetworkManager, Bluetooth, PipeWire, and WirePlumber. QE can still
start with an unavailable optional service, but its related module will not
show live state.

### Clone the Projects

The current development layout expects QE at `~/Projects/quickshell`:

```sh
mkdir -p ~/Projects
git clone https://github.com/Jimfarrugia/quickshell.git ~/Projects/quickshell
git clone https://github.com/Jimfarrugia/theme-switcher.git ~/Projects/theme-switcher
git clone https://github.com/Jimfarrugia/dotfiles.git ~/dotfiles
```

If the repositories already exist, update them instead of cloning them again.
The `qe-theme-switcher` wrapper uses `~/Projects/theme-switcher` by default;
set `QE_THEME_SWITCHER_REPO` if the repository is elsewhere.

### Stow the Dotfiles

Use the dotfiles repository's normal Stow procedure. Stow the packages that
provide the Hyprland configuration, application configurations, and QE helpers.
Ensure the wallpaper collection is also available. The relevant installed paths
are:

- `~/.config/hypr`
- `~/.config/hypr/hyprpaper.conf` and `~/.config/hypr/hyprlock.conf`
- `~/.local/bin/qe-shell`
- `~/.local/bin/qe-theme-switcher`
- `~/.local/bin/qe-defaults`
- Your application configuration directories and wallpaper collection.

The project-owned `defaults/` directory is an authored snapshot source and is
not itself a live XDG configuration directory. The QE project checkout must be
present because it owns both this directory and the `qe-defaults` command.
Update the snapshot only through `qe-defaults capture`.

### Restore the QE Defaults

After the QE project checkout exists and Stow has installed the dotfiles, run
the restore helper before starting QE:

```sh
qe-defaults restore
```

If the helper is not yet on `PATH`, invoke it directly:

```sh
~/Projects/quickshell/scripts/qe-defaults restore
```

`restore` validates and restores the committed wallpaper, generated theme, and
external application artifacts. It also repairs the application `wallpaper`
theme slots and applies the manifest theme. The operation is idempotent.

### Start QE

Start QE through the guarded development helper:

```sh
~/.local/bin/qe-shell
```

The helper starts one QE process for the configuration and discovers Matugen
and the external theme switcher. To restart the running instance:

```sh
~/.local/bin/qe-shell --restart
```

To launch or restart QE from a terminal and keep it running after the terminal
closes, use detached mode:

```sh
~/.local/bin/qe-shell --restart --detach
```

Detached mode starts QE in its own session and sends its output to `/dev/null`.

The selector launchers use QE IPC targets named `qe-theme` and `qe-wallpaper`.
If the desktop entries are installed, launch the corresponding QE selector
from the application menu. The project helper can also open one directly while
QE is running:

```sh
~/Projects/quickshell/scripts/qe-launch.sh qe-theme open
~/Projects/quickshell/scripts/qe-launch.sh qe-wallpaper open
```

## 4. Themes

QE themes are authored JSON files in the repository's `themes/` directory. The
catalog watches this directory, validates each file against `themes/schema.json`,
and excludes invalid files without preventing valid themes from loading.

Theme IDs use lowercase letters, digits, and underscores, for example
`poimandres`, `gruvbox`, and `rose_pine`.

### Adding a New Theme

1. Copy an existing theme such as `themes/poimandres.json` to a new file named
   `themes/<theme-id>.json`.
2. Change `id`, `name`, `variant`, and the palette values.
3. Update every required semantic token in the `tokens` object.
4. Check that the file is valid JSON:

   ```sh
   jq empty themes/<theme-id>.json
   ```

5. Run the theme validation tests from the project root:

   ```sh
   node tests/js/validation.test.mjs
   node tests/js/schema.test.mjs
   ```

6. Start or restart QE if necessary, then select the new theme. QE validates
   the catalog and ignores invalid theme files.

Copying an existing valid theme preserves the required token set. Token values
may be literal colors or references such as `{palette.background}`.

Adding a QE theme does not automatically create corresponding external
application themes. If external applications need that theme, their files and
apply behavior must also be supported by the separate `theme-switcher`
repository.

The generated `wallpaper` theme is different: it is derived from Matugen output
and must not be manually added or edited in `themes/`.

### Modifying an Existing Theme

1. Edit `themes/<theme-id>.json`.
2. Change palette values or token references while preserving the existing
   schema and token names.
3. Check the JSON:

   ```sh
   jq empty themes/<theme-id>.json
   ```

4. Run the validation tests from the project root:

   ```sh
   node tests/js/validation.test.mjs
   node tests/js/schema.test.mjs
   ```

5. Select the theme again if it is active. QE watches the catalog and reloads a
   valid change.

Do not edit generated wallpaper files directly. They are replaced by wallpaper
generation or the defaults restore workflow.

### Modifying the Wallpaper Theme

The wallpaper theme is generated from Matugen output. Its QE color mapping is
defined in `utils/Matugen.mjs`.

1. Edit `mapMatugenTheme()` in `utils/Matugen.mjs`.
2. Change which Matugen palette roles are assigned to the QE tokens. Preserve
   the required token names and valid hex colors.
3. Run the mapping tests from the project root:

   ```sh
   node tests/js/matugen.test.mjs
   ```

   The command should print `matugen fixtures passed`. If the intended mapping
   changes an existing assertion, update the corresponding test expectation.
4. Start or restart QE with Matugen available.
5. Select a wallpaper while the `wallpaper` theme is active to regenerate the
   theme.
6. Restart applications that cache their generated theme, such as OpenCode,
   imv, mpv, or Yazi.

Mappings for external application wallpaper themes are separate and are defined
in `utils/ExternalWallpaperTheme.mjs`.

### Selecting a Theme

Selecting a theme through QE persists the active QE theme in QE's XDG state.
QE commits its own theme first and then requests the matching external theme as
a best-effort operation. A failure in the external switcher does not roll back
the confirmed QE theme.

The `wallpaper` theme can be selected immediately after
`qe-defaults restore`, even before a wallpaper is selected in the
current session. Selecting it applies the restored external wallpaper theme
files through the external switcher with GTK excluded.

The generated imv and mpv background settings are loaded by new instances.
Restart already-running imv or mpv processes after selecting or regenerating
the wallpaper theme. Yazi likewise requires a restart because existing Yazi
instances do not reload the generated flavor.

## 5. Changing the Default Theme and Wallpaper

QE has separate concepts for the authored default theme, the currently active
theme, the selected wallpaper, and the authored wallpaper snapshot.

### Default Theme

The QE default theme is recorded in `defaults/manifest.json`:

```json
{
  "schemaVersion": 1,
  "defaultTheme": "poimandres"
}
```

`defaultTheme` is used when QE has no valid persisted active-theme state. A
theme selected through QE takes precedence on that machine because the active
selection is persisted separately.

Change the active theme through QE, finish any pending theme or wallpaper work,
then use `qe-defaults capture` to update the manifest and wallpaper snapshot as
one reviewed change.

To change the active theme immediately, use the QE theme selector. Do not edit
generated theme files to change the active theme.

### Default Wallpaper Snapshot

The committed wallpaper default is stored in the QE repository under:

```text
~/Projects/quickshell/defaults/wallpaper/
```

It contains the authored default snapshot for:

- Processed wallpaper and lockscreen images under `images/`.
- QE's generated `Wallpaper.json` under `generated-theme/qe/`.
- Neovim's generated palette and application `wallpaper` theme slots under
  `generated-theme/applications/`.

Runtime copies are kept in XDG data, state, and cache directories. Normal
wallpaper selection therefore does not modify the committed project snapshot.

### Capture a New Default

Use this only when intentionally changing the default wallpaper/theme set:

1. Put the desired wallpaper in the appropriate
   `QE_WALLPAPER_ROOT/themes/<theme-id>/` directory.
2. Select it through the QE wallpaper selector.
3. Wait for wallpaper application and `Wallpaper` theme generation to finish.
4. Capture the complete runtime set:

   ```sh
   qe-defaults capture
   ```

5. Review the changes in the QE repository:

   ```sh
   git -C ~/Projects/quickshell status
   git -C ~/Projects/quickshell diff -- defaults
   ```

6. Commit the snapshot when it represents the new intended default.

`capture` requires a running QE instance. It obtains the confirmed active theme
through QE IPC and refuses to update the bundle if an operation is pending or a
required runtime artifact is missing. It stages the complete bundle before
replacing the authored default.

### Restore the Committed Default

On a fresh machine, after Stow has installed the dotfiles, run:

```sh
qe-defaults restore
```

Run it again whenever the runtime wallpaper or generated theme files need to be
returned to the committed default. The command restores the files, repairs the
application theme-slot links, and applies the manifest's default theme. A
running QE instance is asked to apply the default wallpaper and theme through
IPC; before QE starts, the external switcher applies the default application
theme directly. External application is best effort: a missing or failed
switcher is reported while restored files remain in place.

## 6. Notifications and OSDs

QE owns desktop notifications after the Dunst cutover. Notifications appear as
popups and are also available in the notification center during the current QE
process. History is cleared when QE restarts.

### Notification Shortcuts

| Shortcut | Action |
| --- | --- |
| `Super+N` | Open or close the notification center. |
| `Super+Tab` | Open or close the control center. |
| `Super+Shift+N` | Dismiss active notification popups. |
| Notification-center DND button | Toggle Do Not Disturb. |

DND suppresses ordinary popups. Critical notifications remain eligible for
popup presentation.

### Control Center

The control center is a centered overlay with the current time and date, quick
settings, and theme actions. Left-click a Wi-Fi or Bluetooth tile to toggle its
radio; right-click it to open the detailed dashboard. Left-click Volume or Mic
to toggle mute, or scroll over it to adjust the level by 5%. Scrolling also
unmutes that channel.

The header opens the notification center and the existing Rofi power menu.
Theme actions open the existing palette and wallpaper surfaces. The
`wallpaper_slideshow` action applies a random readable wallpaper from the active
theme's wallpaper directory. Capture and restore defaults ask for confirmation
because they change authored or live default files. `Super+Escape` continues to
open the Rofi power menu directly.

The Monitors section is available on `jim-x1c` while `HDMI-A-1` is connected.
Choose Mirrored to mirror the built-in `eDP-1` display, or Extended and then
choose whether HDMI is placed left, up, right, or down relative to the built-in
display. Each output has an independent stepped scale slider in Extended mode.
The only available values are `1.00`, `1.20`, `1.25`, `1.50`, `1.60`, and `2.00`,
all of which produce whole logical pixels at the configured 1920x1080 resolution.
The label previews a step while dragging and the change applies when the slider is
released. While mirrored, `eDP-1` controls the mirrored logical layout and the HDMI
slider is hidden; its previous value returns in Extended mode. Unequal logical
monitor sizes are top-aligned, so pointer crossing is possible only where their
virtual edges overlap. The selection persists across Hyprland restarts.
Switching from mirrored to extended restarts QE automatically so per-screen shell
surfaces appear on the newly independent output. With HDMI disconnected, the
controls are disabled; the selected built-in scale remains part of its authored
profile.

### Hardware OSDs

Hardware keys update the underlying service and show confirmed QE feedback:

| Key | Action |
| --- | --- |
| `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` | Adjust volume. |
| `XF86AudioMute` | Toggle output mute. |
| `XF86AudioMicMute` | Toggle microphone mute. |
| `XF86MonBrightnessUp` / `XF86MonBrightnessDown` | Adjust screen brightness. |
| `XF86KbdBrightnessUp` / `XF86KbdBrightnessDown` | Adjust keyboard brightness. |
| `XF86AudioNext` / `XF86AudioPrev` | Change media track. |
| `XF86AudioPlay` / `XF86AudioPause` | Toggle media playback. |

OSDs show the confirmed value when available and report failed operations rather
than presenting an unconfirmed success value. Volume and brightness keys can be
held to repeat.

### Screenshots

`Print` and `Super+S` capture a region through QE. The resulting notification
includes actions to view the image and open the screenshot directory.

## 7. Help Entries

Add custom help entries to `config/help.json`. The file is refreshed whenever
the help surface opens with `Super+/`. Each entry requires an `id`, `category`,
and `title`; `shortcut` and `command` are optional display text. Categories are
`keybindings` or `commands`, and commands shown here are never executed.

```json
{
  "schemaVersion": 1,
  "entries": [
    {
      "id": "my-shortcut",
      "category": "keybindings",
      "title": "Open my application",
      "shortcut": "Super+M"
    }
  ]
}
```

The catalog is authoritative: edit or remove entries directly to control what
appears on the help page. Invalid entries are skipped with a warning.
