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
  - [Expected Setup-Script Baseline](#expected-setup-script-baseline)
  - [Install Packages](#install-packages)
  - [Clone QE](#clone-qe)
  - [Verify Installed Dotfiles](#verify-installed-dotfiles)
  - [Reload the User Service](#reload-the-user-service)
  - [Restore the QE Defaults](#restore-the-qe-defaults)
  - [Verify Lock Prerequisites](#verify-lock-prerequisites)
  - [Start QE](#start-qe)
  - [Verify QE](#verify-qe)
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
- [8. Production Operations](#8-production-operations)
  - [Diagnostics](#diagnostics)
  - [Logs and Restart](#logs-and-restart)
  - [Recovery](#recovery)

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

The supported manual procedure assumes the Hyprland branch of
`arch-setup-script` has completed first. Its package lists already install
Quickshell, Hyprland, Hypridle, Hyprpaper, Hyprshot, NetworkManager, BlueZ,
PipeWire/PulseAudio compatibility, WirePlumber, brightness control, Rofi,
dashboard escape-hatch applications, ImageMagick, `jq`, Stow, and the configured
Nerd Font and Material Symbols font.

Install the QE-specific packages not currently guaranteed by those authored
lists:

```sh
sudo pacman -S --needed \
  matugen upower inter-font ttf-roboto \
  python python-dbus python-gobject libnotify
```

`python-dbus` and `python-gobject` keep screenshot notification actions alive;
`ttf-roboto` is used by the lock screen. Matugen provides wallpaper palette
generation, UPower provides battery state, and Inter is QE's default UI font.

For a fresh Arch/Hyprland system that did not use `arch-setup-script`, this is
the complete supported QE package set:

```sh
sudo pacman -S --needed \
  git stow bash coreutils diffutils findutils grep sed procps-ng util-linux \
  dbus glib2 systemd pam python python-dbus python-gobject \
  file jq imagemagick libnotify xdg-utils \
  quickshell hyprland hypridle hyprpaper hyprshot matugen \
  networkmanager bluez pipewire pipewire-audio pipewire-pulse wireplumber \
  upower brightnessctl \
  rofi blueman nm-connection-editor pavucontrol thunar \
  inter-font ttf-roboto ttf-jetbrains-mono-nerd \
  ttf-material-symbols-variable
```

Package responsibilities that are easy to miss:

| Packages | Purpose |
| --- | --- |
| `quickshell`, `hyprland`, `systemd`, `dbus`, `glib2`, `pam` | Persistent shell, compositor integration, production supervision, DBus diagnostics, and native lock authentication. |
| `hypridle`, `hyprpaper`, `hyprshot`, `xdg-utils`, `thunar` | Idle/before-sleep locking, wallpaper display, screenshots, and screenshot actions. |
| `python`, `python-dbus`, `python-gobject` | AI quota/metrics helpers and the screenshot notification action daemon. |
| `matugen`, `imagemagick`, `file`, `jq` | Wallpaper validation, processing, generated colors, and structured theme data. |
| `procps-ng`, `util-linux`, `coreutils`, `diffutils`, `findutils`, `grep`, `sed` | Guarded launch, bounded integration helpers, defaults restoration, and diagnostics. |
| `networkmanager`, `bluez`, `pipewire`, `pipewire-pulse`, `wireplumber`, `upower`, `brightnessctl` | Network, Bluetooth, audio, battery, and brightness integrations. |
| `rofi`, `blueman`, `nm-connection-editor`, `pavucontrol` | Current power/specialized Rofi flows and scoped dashboard escape hatches. |
| `inter-font`, `ttf-roboto`, `ttf-jetbrains-mono-nerd`, `ttf-material-symbols-variable` | QE, lock, monospace, and icon typography. |

NetworkManager and Bluetooth are system services. PipeWire and WirePlumber are
user-session services. UPower is normally DBus-activated. Missing an optional
service degrades its related module without preventing the shell from starting.

### Optional Application Dependencies

QE can generate or apply external themes for these applications when they are
installed and supported by the local theme-switcher configuration:

```text
bat, btop, dunst, eza, fzf, Hyprland, imv, kitty, mpv, Neovim,
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
- The `qe-doctor` wrapper for production dependency, ownership, and conflict
  checks.
- Hyprland configuration that starts Hyprpaper and invokes
  `qe-shell --service-start` after the compositor environment exists.
- The `qe-shell.service` systemd user unit supplied by the dotfiles repository.
- Hyprpaper configuration that reads the current wallpaper file from
  `$HOME/.local/share`; QE composes the lock background from the selected source.
- A wallpaper collection arranged as
  `~/Pictures/Wallpaper/themes/<theme-id>/` unless `QE_WALLPAPER_ROOT` is set.

The supported managed production checkout is `~/Projects/quickshell`. Stable
commands under `~/.local/bin` dispatch into that checkout through `qe-project`.
`QE_PROJECT_ROOT` can override the dispatcher for an interactive command, but
the production service does not import that override. Keep the checkout at the
supported default location for a reproducible setup.

### Paths and Environment Variables

QE resolves runtime paths through XDG variables:

| Path or variable | Use |
| --- | --- |
| `$HOME/.local/share/current_wallpaper.png` | Processed image consumed by the current Hyprpaper configuration. |
| `XDG_DATA_HOME/qe/wallpaper/Wallpaper.json` | Stable generated QE wallpaper theme. |
| `XDG_STATE_HOME/qe/wallpaper/external/` | Runtime external wallpaper theme files. |
| `XDG_CACHE_HOME/matugen/nvim-colors.json` | Runtime Neovim wallpaper palette. |
| `QE_WALLPAPER_ROOT` | Overrides the wallpaper collection root. |
| `QE_MATUGEN` | Explicit Matugen executable; otherwise `run-qe.sh` discovers `matugen`. |
| `QE_WALLPAPER_HELPER` | Overrides the QE wallpaper apply helper; defaults to `scripts/qe-wallpaper`. |
| `QE_THEME_SWITCHER` | Explicit external theme-switcher executable. |
| `QE_THEME_SWITCHER_REPO` | Repository path used by the `qe-theme-switcher` wrapper. |
| `ZSH_CONFIG_HOME` | Overrides the configuration directory used for the FZF theme slot. |

The default values are based on `$HOME` and the standard XDG directories. QE
itself honors XDG overrides, but the installed Hyprpaper configuration currently
fixes its data root to `$HOME/.local/share`. Keep
`XDG_DATA_HOME=$HOME/.local/share` for production unless QE and Hyprpaper are
updated together.

### Current Limitations

- QE's managed production deployment remains the checkout at
  `~/Projects/quickshell`; it is not copied into a separate release directory.
- OpenCode loads and caches theme colors at launch. Regenerated wallpaper
  colors require an OpenCode restart.
- External theme application is best effort. QE can commit its own theme while
  an external target reports a partial or unavailable result.

## 3. Setting Up

Complete these steps from the setup TTY or another shell before the first
Hyprland login when possible. The stowed Hyprland configuration already invokes
QE at login; until the checkout exists, that bounded startup attempt will fail.
If Hyprland has already been started, finish the same steps there and use the
documented `qe-shell --service-start` command afterward.

### Expected Setup-Script Baseline

This procedure starts after `arch-setup-script` has completed its Hyprland flow.
That flow installs the general Hyprland packages, clones local integrations, and
stows the dotfiles before QE-specific setup begins. It should already provide:

- `~/dotfiles`, `~/Projects/theme-switcher`, and `~/Pictures/Wallpaper`.
- Git and GitHub CLI; `arch-setup-script` installs Git before cloning and lists
  GitHub CLI in its universal package set.
- The universal `scripts` dotfiles package and Hyprland `applications`, `hypr`,
  `systemd`, and application-configuration packages.
- `~/.local/bin` on the login-shell `PATH`.
- QE entry points, Hyprland startup/keybindings, desktop entries, and
  `~/.config/systemd/user/qe-shell.service` from the dotfiles.

The theme-switcher and wallpaper clones are non-fatal operations in the current
setup script. Verify that they succeeded before continuing:

```sh
test -x ~/Projects/theme-switcher/run.sh
test -d ~/Pictures/Wallpaper/themes/poimandres
```

If a check fails because the destination is absent, run its corresponding clone
command:

```sh
mkdir -p ~/Projects ~/Pictures
git clone https://github.com/Jimfarrugia/theme-switcher.git \
  ~/Projects/theme-switcher
```

```sh
mkdir -p ~/Pictures
git clone https://github.com/Jimfarrugia/wallpaper.git \
  ~/Pictures/Wallpaper
```

### Install Packages

Install the QE-specific package delta listed in
[Software Dependencies](#software-dependencies). Use the complete package list
there only when setting up without the normal `arch-setup-script` baseline.

Enable the system-service owners used by the enabled modules:

```sh
sudo systemctl enable --now NetworkManager.service bluetooth.service
```

PipeWire and WirePlumber are user services. If a user manager is reachable in
the current environment, enable their normal units now:

```sh
systemctl --user enable --now \
  pipewire.socket pipewire-pulse.socket wireplumber.service
```

If that command cannot connect to the user bus before the first graphical
login, run it from a terminal after entering Hyprland. These units are commonly
started by user-session presets already; the command is idempotent.

Confirm the screenshot action imports supplied by the package delta are usable:

```sh
python3 -c 'import dbus; from gi.repository import GLib'
```

### Clone QE

QE is not yet cloned by `arch-setup-script`. Install it at the supported managed
location:

```sh
mkdir -p ~/Projects
git clone https://github.com/Jimfarrugia/quickshell.git ~/Projects/quickshell
```

If the checkout already exists, update and inspect it instead of cloning over
it. The production wrappers default to this exact location.

### Verify Installed Dotfiles

Do not re-stow packages after a successful `arch-setup-script` run. Verify the
QE-facing paths it should have installed:

```sh
test -x ~/.local/bin/qe-project
test -x ~/.local/bin/qe-shell
test -x ~/.local/bin/qe-lock
test -x ~/.local/bin/qe-action
test -x ~/.local/bin/qe-launch
test -x ~/.local/bin/qe-defaults
test -x ~/.local/bin/qe-doctor
test -x ~/.local/bin/qe-hyprshot
test -x ~/.local/bin/qe-theme-switcher
test -r ~/.config/hypr/hyprpaper.conf
test -r ~/.config/systemd/user/qe-shell.service
```

If these checks fail, repair the corresponding dotfiles Stow operation before
continuing. The universal `scripts` package provides the commands; the
Hyprland `hypr`, `systemd`, and `applications` packages provide startup, the
unit, and desktop integration.

The project-owned `defaults/` directory is an authored snapshot source and is
not itself a live XDG configuration directory. The QE project checkout must be
present because it owns both this directory and the `qe-defaults` command.
Update the snapshot only through `qe-defaults capture`.

### Reload the User Service

Make the newly stowed static unit visible to the systemd user manager:

```sh
systemctl --user daemon-reload
systemctl --user show qe-shell.service \
  -p LoadState -p UnitFileState -p FragmentPath
```

`LoadState=loaded` and `UnitFileState=static` are expected. Do not enable
`qe-shell.service`; it intentionally has no `[Install]` section. Hyprland starts
it after importing the compositor environment. If `systemctl --user` is not
available before the first graphical login, skip this reload for now, restore
the defaults, and enter Hyprland. If QE does not start automatically, run the
reload and then `qe-shell --service-start` from that session.

### Restore the QE Defaults

After the QE checkout exists and the dotfiles checks pass, restore the committed
runtime bundle before the first QE/Hyprpaper start:

```sh
qe-defaults restore
```

If the helper is not yet on `PATH`, invoke it directly:

```sh
~/Projects/quickshell/scripts/qe-defaults restore
```

`restore` validates and restores the committed wallpaper, generated theme, and
external application artifacts. It creates required XDG parent directories,
repairs application `wallpaper` theme slots as symlinks, and applies the
manifest theme. Existing regular files at those generated `wallpaper` slots may
be replaced. The operation is idempotent, does not require a running QE shell,
and retains restored files if best-effort external theme application fails.

### Verify Lock Prerequisites

QE uses the existing system `login` PAM stack; it does not install a custom PAM
file. Before relying on the QE lock, verify:

```sh
test -r /etc/pam.d/login
test -x ~/.local/bin/qe-lock
loginctl list-sessions
```

Confirm that you can log in on an alternate TTY before performing the first real
lock test. If the lock process crashes after acquiring the secure Wayland lock,
recovery requires terminating or recovering the graphical session from a TTY;
starting another lock process cannot reclaim it.

### Start QE

For initial setup, log out and enter a fresh Hyprland session after restoring
defaults. Hyprland imports its environment, starts Hyprpaper and Hypridle, and
triggers the static `qe-shell.service`.

To start or replace QE from an already running Hyprland session, run:

```sh
~/.local/bin/qe-shell --service-start
```

From a terminal in the new graphical session, confirm the dispatcher is on the
session path and exercise an installed `.desktop` entry:

```sh
command -v qe-launch
gtk-launch qe-theme-selector
```

The expected command path is `$HOME/.local/bin/qe-launch`, and the theme selector
should open. If either check fails, correct the graphical-session `PATH` or
re-enter the session after verifying the dotfiles-provided login profile. The
theme, wallpaper, and palette desktop entries all use this dispatcher.

The unit invokes the guarded launcher, which starts one QE process for the
configuration and discovers Matugen and the external theme switcher. To restart
the running instance without re-importing the session environment:

```sh
~/.local/bin/qe-shell --restart
```

To launch or restart QE from a terminal and keep it running after the terminal
closes while the supervised service is inactive, use detached mode:

```sh
~/.local/bin/qe-shell --restart --detach
```

Detached mode starts QE in its own session and sends its output to `/dev/null`.
It is a development/recovery fallback and is not the normal supervised launch.
`--restart --detach` is rejected while `qe-shell.service` is active; stop the
unit first when deliberately switching to direct detached recovery.

### Verify QE

Run:

```sh
systemctl --user status qe-shell.service
qs list --all
qe-doctor
```

Expected results are one active `qe-shell.service`, one instance whose config is
`~/Projects/quickshell/shell.qml`, QE ownership of notifications and the status
notifier watcher, no Waybar/Dunst/Hyprlock process, and a `qe-doctor` summary of
zero failures. Optional integrations may produce warnings without blocking the
shell.

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

QE applies the selected source image immediately through Hyprpaper and then
normalizes `current_wallpaper.png` for startup. The QE lock renders the selected
source itself with a subtle blur and transparent-to-black gradient.

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

- Processed wallpaper under `images/`. Any legacy lockscreen image remains
  unmanaged.
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

## 8. Production Operations

### Diagnostics

Run the read-only production diagnostic after deployment, upgrades, or an
unexpected degraded state:

```sh
qe-doctor
```

It checks required and enabled-feature commands, stable QE entry points, the
systemd service and single-instance state, notification and tray DBus ownership,
and conflicting retired processes. `[FAIL]` items produce a nonzero exit status;
missing optional integrations produce `[WARN]` without preventing the shell from
running.

`qe-doctor` complements rather than replaces the setup checks above. It does not
validate the wallpaper checkout, restored default artifacts, Python DBus/GLib
modules, fonts, PAM behavior, external daemon health, custom-XDG alignment, or
secure-lock behavior.

The current enabled configuration additionally uses `python3`, `brightnessctl`,
`df`, `timeout`, `nmcli`, `setpriv`, `gdbus`, and `dbus-monitor`. Wallpaper and
external-theme operations additionally use Matugen, ImageMagick, `file`, `jq`,
Hyprpaper, `hyprctl`, and the project-owned helpers. NetworkManager, BlueZ,
PipeWire/WirePlumber, UPower, and systemd-logind remain external service owners;
their absence degrades only the related feature where the architecture permits.

### Logs and Restart

Inspect supervised startup and runtime output with:

```sh
systemctl --user status qe-shell.service
journalctl --user -u qe-shell.service -b
```

Use `qe-shell --restart` for a normal restart. The command delegates to the
active unit and falls back to the direct guarded launcher only when the unit is
not active. Quickshell 0.3.1 first handles shell-child crashes internally;
systemd restarts a failed launcher after two seconds and limits service starts
to three per 60 seconds. The separate `qe-lock` process is never automatically
restarted.

If the service has reached its start limit after repeated failures, inspect the
journal, correct the cause, and then run:

```sh
systemctl --user reset-failed qe-shell.service
qe-shell --service-start
```

### Recovery

The legacy Waybar/Dunst/Hyprlock restoration profile is no longer maintained
after sustained daily-use acceptance. Rofi remains in use for specialized
launchers and the power menu. `pavucontrol`, Blueman Manager, and
`nm-connection-editor` remain installed escape hatches for functionality outside
the supported dashboard scope; they are not a complete desktop-shell rollback.
Do not start Waybar, Dunst, or Hyprlock alongside the equivalent QE owner.

If QE itself fails while the compositor remains usable, inspect the journal and
try `qe-shell --service-start`. If the lock process crashes after the compositor
has confirmed a secure lock, do not start another lock process: switch to a TTY
and terminate or recover the graphical session as documented by the lock
security procedure.
