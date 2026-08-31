# QE Initial System Inventory

Status: Historical reference; non-authoritative for current QE behavior

This file preserves the discovery inventory that previously lived in
`docs/PLAN.md`. It describes the environment and migration starting point before
completed QE cutovers. Current architecture is authoritative in
`docs/ARCHITECTURE.md`; current roadmap/status is authoritative in
`docs/PLAN.md`; accepted decisions are authoritative in `docs/DECISIONS.md`.

Do not load this file by default for implementation work.

## 3. Current-System Inventory

### 3.1 Configuration and session

Verified facts:

- `~/.config/hypr` is a symlink to
  `~/dotfiles/_hyprland/hypr/.config/hypr`.
- The active Hyprland configuration is Lua-based. `hyprland.lua` loads
  environment, monitors, keybindings, autostart, style, current theme, input,
  and window rules.
- Hyprland `0.56.2` is installed and was running during inventory.
- The session desktop file launches `/usr/bin/start-hyprland` directly.
- One internal monitor, `eDP-1`, was active at 1920x1080, scale 1.2, with a
  28-pixel bottom reserved area from Waybar.
- The repository currently runs from `~/Projects/quickshell`; Phase 12 will
  decide whether relocation provides enough benefit to justify migration.

Relevant files:

- `~/.config/hypr/hyprland.lua`
- `~/.config/hypr/autostart.lua`
- `~/.config/hypr/keybinds.lua`
- `~/.config/hypr/config/programs.lua`
- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/hyprlock.conf`
- `~/.config/hypr/hyprpaper.conf`

### 3.2 Current autostart and lifecycle

`~/.config/hypr/autostart.lua` currently starts:

- DBus/systemd environment import
- GNOME keyring secrets component
- Hyprpaper
- Hypridle
- Waybar
- `wl-paste --type text --watch cliphist store`
- `sudo keyd`, despite keyd also being an enabled system service
- Nextcloud
- terminal/tmux sessions

Dunst is DBus-activated through a static systemd user service and is not
explicitly launched by the Hyprland autostart file.

Migration implication: QE must not kill or replace these processes implicitly.
Each cutover changes the owning configuration explicitly and has a documented
revert.

### 3.3 Current bar

Waybar is configured at `~/.config/waybar` and starts on the bottom edge.

Current modules:

- network
- disk
- memory
- CPU
- temperature
- Pomodoro
- Hyprland workspaces
- system tray
- clipboard history
- idle inhibitor
- Bluetooth
- PipeWire/PulseAudio
- backlight
- battery
- clock

Current interactions and dependencies:

- network opens `nm-connection-editor`
- Bluetooth opens `blueman-manager`
- audio opens `pavucontrol`
- clipboard uses `cliphist`, Rofi, and `wl-copy`
- Pomodoro uses the external `waybar-module-pomodoro` executable
- temperature uses a hard-coded `/sys/class/hwmon/hwmon3/temp1_input`
- tray icon configuration contains an absolute `/home/jim` path
- Hyprland window rules assume a 28-pixel bar

Migration implication: a development QE bar must not reserve the same edge
while Waybar is active. Essential parity and reserved-area behavior must be
verified before Waybar autostart changes.

### 3.4 Current launcher and menus

- Super+R launches `rofi -show drun`.
- Super+Shift+R opens clipboard history through Rofi.
- Super+Escape opens a Rofi power menu.
- Theme and wallpaper selection are exposed through desktop entries/scripts.
- The power menu invokes `loginctl` and `systemctl` for lock/logout/power actions.

Rofi can coexist with QE until keybindings are deliberately switched.

### 3.5 Current lock and idle behavior

- Super+Backspace launches Hyprlock.
- Hypridle lowers brightness after 60 seconds and restores it on activity.
- Hypridle calls `loginctl lock-session` after 300 seconds and before sleep.
- Hyprlock uses `~/.local/share/current_lockscreen.png`, a profile image, battery
  helper output, and a periodically refreshed `fortune` quote.
- `/etc/pam.d/hyprlock` includes the system `login` PAM stack.
- Fingerprint packages were not installed during inventory.

Migration implication: the QE lock must cover manual lock, idle lock, and
before-sleep paths before Hyprlock is disabled. The existing visuals are parity
references, not security requirements.

### 3.6 Current notifications

- Dunst `1.13.2` owns `org.freedesktop.Notifications` through DBus activation.
- Super+N invokes `dunstctl history-pop`.
- Super+Shift+N invokes `dunstctl close-all`.
- Existing hardware scripts send replaceable Dunst notifications for volume,
  microphone mute, and brightness.

Only one notification server can own the DBus name. QE and Dunst cannot provide
notifications concurrently in one user bus. The accepted migration is staged.

### 3.7 Current audio, network, Bluetooth, power, and media stack

Verified installed versions during inventory:

| Dependency | Version/condition |
| --- | --- |
| Quickshell | 0.3.1-1 |
| Qt Declarative | 6.11.2-1 |
| PipeWire | 1.6.8 |
| WirePlumber | 0.5.15 |
| NetworkManager | 1.58.0 |
| BlueZ | 5.87 |
| UPower | 1.91.3 |
| `brightnessctl` | 0.5.1 |
| `playerctl` | 2.4.1 |
| Matugen | not installed |

Runtime observations:

- PipeWire exposed one built-in analog sink and source.
- NetworkManager reported connected/full connectivity.
- One powered BlueZ controller was present.
- `pavucontrol`, Blueman, and NetworkManager applet/editor packages were
  installed as fallbacks.

Current keybindings call:

- `~/.local/bin/volume` using `wpctl`
- `~/.local/bin/mic-mute-toggle` using `wpctl`
- `~/.local/bin/brightness` using `brightnessctl`
- `playerctl` for media actions

These scripts parse human command output and send Dunst notifications. QE will
replace their UI feedback only after corresponding domain services and OSDs are
ready.

### 3.8 Current theme workflow

The selector `~/.local/bin/select_theme` enumerates desktop entries under
`~/.local/share/applications/themes`, opens Rofi, and calls:

```text
~/Projects/theme-switcher/run.sh <theme>
```

The switcher:

- runs every `apply/apply_*.sh` in lexical glob order
- is fail-fast because it uses `set -euo pipefail`
- applies themes to bat, btop, Dunst, eza, FZF, GTK, Hyprland, Hyprlock, imv,
  Kitty, mpv, Neovim, OpenCode, Rofi, Starship, tmux, Waybar, and Yazi
- emits human-oriented stdout rather than structured status
- writes `~/.local/share/theme_data` only after all apply scripts succeed
- automatically launches the wallpaper picker outside KDE
- mutates or copies active files in many application configuration directories
- restarts Dunst and Waybar and signals several running applications

Nine currently selected theme IDs were found:

```text
catppuccin
dracula
eldritch
everforest
gruvbox
nord
poimandres
rose_pine
tokyo_night
```

The collections are not complete for every application. FZF and OpenCode have
known gaps or mappings to built-in themes.

Current theme state is effectively split across:

- `~/.local/share/theme_data`
- copied/generated active files
- Neovim's `.current_theme`
- OpenCode's `tui.json`
- live application state

`~/.local/share/theme_data` is a legacy compatibility source, not a suitable QE
state file.

### 3.9 Current wallpaper workflow

The external theme switcher launches `~/Projects/wallpaper-picker`, a separate
Quickshell project. It:

- reads the selected theme from `~/.local/share/theme_data`
- lists wallpapers under `~/Pictures/Wallpaper/themes/<theme>`
- generates cached ImageMagick thumbnails and a manifest
- runs `set_wallpaper.sh` asynchronously after selection

The wallpaper helper:

- queries focused monitor resolution through `hyprctl` and `jq`
- validates and transforms an image with ImageMagick
- writes `~/.local/share/current_wallpaper.png`
- writes a gradient `~/.local/share/current_lockscreen.png`
- kills and restarts Hyprpaper
- records the source wallpaper in `theme_data`

The generated display and lock images are derived artifacts. The source image
path is the selected input. The current helper does not provide structured
confirmation that Hyprpaper displayed the image.

### 3.10 Verified Quickshell 0.3.0 capabilities

Native installed modules include:

- Hyprland IPC and global shortcuts
- Bluetooth/BlueZ
- Networking/NetworkManager
- PipeWire
- MPRIS
- UPower and power profiles
- system tray and DBus menus
- notification server
- PAM
- `WlSessionLock`
- Wayland idle inhibition/monitoring
- desktop entry discovery
- file watching, JSON adapters, processes, IPC, and persistent properties

Important limits:

- no native brightness API
- no general QML DBus binding
- MPRIS playback position needs a bounded timer for continuous display
- notification history must be implemented by QE
- complex NetworkManager profiles are not trivial through the native API
- Bluetooth pairing-agent completeness needs verification
- only the process that owns a secure `WlSessionLock` can release it
- a lock-owner crash leaves the compositor securely locked and unrecoverable by
  a replacement client

The installed Quickshell package is now 0.3.1-1 and the local source reference is
0.3.1. Notification APIs used in Phase 5 are verified against the installed
0.3.1 metadata; future upgrades must repeat this check.
