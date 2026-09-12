# QE Installer Implementation Plan

## Purpose

Implement a repeatable installer that turns the Hyprland environment prepared by
the Arch Setup Script into a working QE desktop.

The primary workflow is:

```text
minimal Arch
  -> Arch Setup Script
  -> Hyprland/base environment
  -> QE installer
  -> completed QE desktop
```

The QE installer must also remain usable independently. Installation is an
opt-in provisioning domain and must not be mixed into QE's runtime ownership.

This plan covers coordinated changes in these repositories:

- QE: `~/Projects/quickshell`
- Arch Setup Script: `~/Projects/arch-setup-script`
- dotfiles: `~/dotfiles`

Do not add general uninstall, transactional rollback, package-management, or
migration frameworks. Implement only the bounded migration and recovery behavior
required by the current deployment.

## Ownership Boundaries

### QE

QE is authoritative for:

- its complete package and host-prerequisite definitions;
- package-to-capability validation;
- generic deployment assets;
- public QE commands;
- installation-safe default bootstrap;
- Dunst cutover;
- installation and activation state;
- live readiness validation;
- installer behavior and failure semantics.

QE must verify every requirement even when Arch Setup normally supplies it. A
future removal from Arch Setup's package set must be detected by QE and either
installed through the authorized package path or reported clearly.

### Arch Setup Script

Arch Setup owns:

- when QE installation runs;
- target-user discovery and caller environment;
- the general Arch and Hyprland base environment;
- root execution of the fixed Pacman transaction requested by QE;
- enablement of the required NetworkManager and Bluetooth system services;
- dotfiles deployment and Stow behavior;
- bounded migration of the current folded dotfiles deployment;
- propagation of installer failures.

Arch Setup must not duplicate QE package lists, capability mappings, deployment
assets, or installation logic.

### Dotfiles

Dotfiles remain authoritative for user and session policy:

- Hyprland/Lua composition;
- keybindings and application choices;
- Hypridle policy and timeout values;
- Hyprpaper policy;
- monitor and machine-specific configuration;
- non-QE session startup.

Dotfiles must relinquish generic QE deployment assets after the coordinated
cutover described below.

## Supported Production Environment

The supported production checkout is fixed at:

```text
$HOME/Projects/quickshell
```

This preserves ADR-045 and Quickshell's configuration-path-scoped state identity.
The installer must not promise transparent checkout relocation or migrate
path-scoped Quickshell state.

Production installation requires conventional XDG roots:

```text
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state
XDG_CACHE_HOME=$HOME/.cache
```

General custom-XDG support is out of scope until runtime and Hyprpaper path
ownership are consistently XDG-aware. Tests may use explicit test-only path
seams.

The supported platform is Arch Linux with Hyprland, systemd user management,
session DBus, PAM, and Wayland session-lock support.

## QE Installer Interface

Add a repository-root `install.sh` backed by a focused installer implementation.
The public command surface is:

```text
./install.sh check
./install.sh protocol-version
./install.sh package-query
./install.sh install [--packages] [--non-interactive]
                     [--authorize-dunst-cutover]
./install.sh activate
```

### Commands

`check`:

- perform non-mutating package, capability, path, ownership, compatibility, and
  host-hook checks;
- distinguish fatal requirements from optional/degraded capabilities;
- do not create persistent or user-owned files, install packages, or change
  services;
- run probes that require writable Quickshell/XDG state only under private
  temporary roots and remove those roots before returning.

`protocol-version`:

- provide the side-effect-free machine handshake used by Arch Setup;
- write exactly `1` followed by a newline to stdout for this protocol version;
- reserve stdout for that token and write diagnostics to stderr;
- perform no package, capability, session, or deployment checks and create no
  persistent or user-owned files;
- return zero only when the installer can honor protocol version `1`.

`package-query`:

- emit missing required official Arch package names, one per line, on stdout;
- reserve stdout exclusively for package names;
- write diagnostics to stderr;
- emit zero bytes and return zero when no required packages are missing;
- return nonzero if the query cannot produce a complete trustworthy result.

`install`:

- perform static user-level deployment;
- seed defaults non-destructively;
- persist the authorized Dunst mask;
- activate only when a real usable user/Hyprland session is present;
- otherwise complete successfully as `activation-deferred`.

`install --packages`:

- support independent installation outside Arch Setup;
- use ordinary `sudo` only for the fixed Pacman transaction;
- use non-interactive sudo only when `--non-interactive` was explicitly passed;
- never create temporary sudoers grants.

`activate`:

- act only as a thin delegate to `qe-shell --service-start`;
- introduce no second activation, Dunst-cutover, readiness, or receipt-writing
  implementation.

### General Rules

- Reject whole-installer execution as root.
- Use the effective user and validated `HOME`; do not use `SUDO_USER` inside QE.
- `--non-interactive` suppresses prompts but authorizes no consequential action.
- Dunst cutover requires `--authorize-dunst-cutover` or explicit confirmation in
  an interactive manual run.
- Do not add `--force`, dry-run, uninstall, rollback, or repository-update
  commands.

### Exit Contract

- `0`: static deployment completed; activation is either ready or legitimately
  deferred.
- `1`: operational installation failure.
- `2`: invalid invocation.

Exit status is the stable Arch Setup caller contract. Human-readable status
markers may be logged, but `config/hyprland/qe.sh` must not parse them. Detailed
activation state is persisted separately and may change after Arch Setup exits.

## Dependency and Capability Model

Keep the complete package inventory in QE. Arch Setup may install overlapping
packages for its general environment but must not carry a second QE list.

### Core Requirements

The core requirement set includes:

- Quickshell and required Qt/QML modules;
- Hyprland and Wayland;
- systemd, DBus, PAM, and GLib;
- shell, process, and file utilities used by QE helpers;
- configured font families.

### Supported Default-Profile Requirements

The checked-in default QE configuration additionally requires software for:

- Hypridle and Hyprpaper;
- Matugen wallpaper theme generation;
- ImageMagick, `file`, and `jq` validation/transforms;
- NetworkManager;
- BlueZ;
- PipeWire and WirePlumber;
- UPower;
- brightness control;
- Python DBus/GObject helpers;
- screenshots and XDG helpers.

The initial package inventory must be reconciled against current Arch package
metadata and the current repository. Known packages include:

```text
quickshell qt6-5compat hyprland hypridle hyprpaper
matugen imagemagick file jq
networkmanager bluez pipewire pipewire-audio pipewire-pulse wireplumber
upower brightnessctl
python python-dbus python-gobject
hyprshot xdg-utils libnotify
inter-font ttf-roboto ttf-jetbrains-mono-nerd
ttf-material-symbols-variable
```

Include all shell/core utility packages directly required by project helpers.
Do not rely on incidental installation by another package without documenting
that dependency relationship in QE's inventory.

### Optional Integrations

These must not block installation:

- Theme Switcher;
- the external wallpaper repository;
- Rofi and `rofi_power_menu`;
- Blueman, `nm-connection-editor`, `pavucontrol`, and Thunar;
- power-profiles-daemon;
- externally themed applications;
- OpenCode credentials and provider connectivity;
- battery, controllable backlight, and monitor-specific hardware.

### Package and Capability Checks

Package state determines what Pacman should install. Successful package
installation does not establish readiness by itself. Final checks must also
verify the usable capability:

- `command -v` for required executables;
- Python imports for DBus/GObject helpers;
- configured font-family resolution;
- minimal isolated Quickshell/QML import probes for required modules;
- readable `/etc/pam.d/login`;
- required base system-service enablement;
- valid authored JSON, images, and default artifacts.

Temporary daemon unavailability and absent hardware are degraded runtime
capabilities rather than readiness failures. Service policy is:

- `NetworkManager.service` and `bluetooth.service` are required enabled system
  services. Arch Setup enables them before invoking QE. Independent QE
  installation reports a disabled unit as a prerequisite failure with the exact
  administrator command; QE does not enable it.
- `pipewire.socket`, `pipewire-pulse.socket`, and `wireplumber.service` are
  required installed user units for the default profile. Their unit files and
  normal package-preset availability are pre-login prerequisites, but an
  unreachable pre-login user manager is not a static-install failure. Activation
  reports disabled units with exact user commands; temporary inactivity or
  daemon loss remains a degraded runtime capability and does not prevent the
  shell from reaching readiness.
- UPower's packaged DBus activation is required, but no separately enabled unit
  is required. Network, Bluetooth, audio, power, and brightness hardware or live
  daemon availability remain degraded capabilities when the corresponding
  package/unit contract is present.

Missing required software or a disabled required base system service is a
prerequisite failure under that policy. QE reports such failures; it does not add
a generic privileged service-action broker.

### Compatibility Policy

Initially record:

```text
minimum supported Quickshell: 0.3.1
newest validated Quickshell: 0.3.1
validated Hyprland baseline: 0.56.2
```

- Reject Quickshell versions below the minimum.
- Warn, rather than block, for newer versions when all capability probes pass.
- Fail a missing/broken required QML module or API capability regardless of
  package version.
- Do not invent a Hyprland minimum without evidence.
- Correct or stop relying on stale hard-coded versions in
  `services/DiagnosticsService.qml`.

## Arch Setup Integration

### New Integration Shim

Add:

```text
~/Projects/arch-setup-script/config/hyprland/qe.sh
```

Source it near the end of Arch Setup's Hyprland branch, after package setup,
repository cloning, dotfiles deployment, and Hyprland configuration.

The shim must remain caller-only. It may know QE's installer protocol, but not
QE's package names, capability mappings, deployment paths, or implementation.

### Target-User Validation

Before any target-home mutation, Arch Setup's main entry point must:

- require `SUDO_USER` to be set and non-root;
- resolve the account UID and home through the passwd database;
- derive `$USER_HOME` from that resolved record rather than `/home/$SUDO_USER`;
- fail clearly before directory creation, cloning, cleanup, Stow, or other
  target-user operations if identity resolution is inconsistent.

The shim must revalidate the established identity before invoking QE. It must:

- require `SUDO_USER` to be set and non-root;
- resolve the account UID and home through the passwd database;
- require that resolved home to match Arch Setup's `$USER_HOME`;
- execute, never source, the user-owned QE installer;
- fail clearly if the fixed checkout or expected installer protocol is absent.

Do not expand this work into a general refactor of all Arch Setup target-user
handling.

### Deterministic Environment

Invoke QE through the existing `as_user` helper with a clean environment
allowlist. Preserve only explicitly selected harmless process values such as the
locale, and set:

```text
HOME=$TARGET_HOME
USER=$TARGET_USER
LOGNAME=$TARGET_USER
PATH=$TARGET_HOME/.local/bin:/usr/bin
XDG_CONFIG_HOME=$TARGET_HOME/.config
XDG_DATA_HOME=$TARGET_HOME/.local/share
XDG_STATE_HOME=$TARGET_HOME/.local/state
XDG_CACHE_HOME=$TARGET_HOME/.cache
```

Do not fabricate or forward root-owned values for:

```text
XDG_RUNTIME_DIR
DBUS_SESSION_BUS_ADDRESS
WAYLAND_DISPLAY
HYPRLAND_INSTANCE_SIGNATURE
XDG_CURRENT_DESKTOP
```

Use `env -i` or equivalent explicit unsetting so those names are absent even if
sudo policy would otherwise preserve them. Their legitimate absence during
setup produces `activation-deferred`.

### Automated Package Protocol

The Arch-integrated package flow is:

1. Run `protocol-version` as the target user and require exit zero plus exactly
   `1` followed by a newline on stdout, with no additional stdout bytes.
2. Run `package-query` as the target user and capture stdout separately from
   diagnostics.
3. Capture stdout byte-for-byte in a private temporary file while preserving the
   query exit status. Reject malformed nonempty output, blank records, whitespace,
   leading options, or invalid Arch package names.
4. Treat exit-zero zero-byte output as success with nothing to install and skip
   Pacman.
5. Otherwise pass the validated package-name array, without shell evaluation, to fixed
   root-owned Pacman arguments equivalent to:
   ```text
   pacman -S --needed --noconfirm -- <packages>
   ```
6. Run the QE user-level installer with:
   ```text
   install --non-interactive --authorize-dunst-cutover
   ```
7. Let QE recheck every package and capability after Pacman finishes or after an
   empty query.
8. Propagate any nonzero result through existing Arch Setup logging/fatal
   helpers.

Do not use `with_pacman_nopasswd` for QE. Hardening that existing helper is a
separate Arch Setup security task.

Arch Setup must present QE installation as an explicit opt-in choice. An
affirmative answer to that QE-specific choice authorizes the Dunst cutover and
is the sole reason the shim may pass `--authorize-dunst-cutover`; choosing
Hyprland alone is not authorization. Declining the QE choice skips the QE shim.

An `activation-deferred` installation returns zero and must count as successful
deployment in Arch Setup.

## Stow and Cross-Repository Cutover

The current Stow-folded parent directories cause writes under paths such as
`~/.local/bin` and `~/.config/systemd` to modify the dotfiles checkout. QE must
not write through such parents.

Immediately after repository clone discovery and before Arch Setup removes any
target configuration or invokes Stow, validate that the existing QE and dotfiles
directories are the expected repositories and contain the coordinated cutover
structure required by the supported installer protocol. An arbitrary directory,
wrong remote, missing checkout metadata, or incompatible partial cutover must
fail with exact update/recovery instructions. Do not treat “directory exists” as
repository validation. This early preflight runs QE's `protocol-version` through
the same sanitized target-user environment and verifies that dotfiles has
relinquished the transferred assets and carries the required Stow exclusions.
The late shim repeats the cheap protocol handshake immediately before package
query so mutation never relies on a stale earlier result.

Change Arch Setup's user-dotfiles deployment from plain Stow to:

```text
stow --restow --no-folding
```

Validate this change across every remaining user dotfile package discovered
after the retired `systemd` package migration because it changes their link
shape. Root/system Stow behavior should change only if the same ownership need
applies and validation supports it.

Add Stow-specific ignore rules, not only Git ignore rules, for the known mutable
or generated source-tree paths:

- `_hyprland/hypr/.config/hypr/plugins/`;
- the QE-generated wallpaper-theme slot paths currently listed in dotfiles'
  `.gitignore`.

Before restow, scan those exact source-tree paths. Remove only recognized
generated symlinks whose exact source slot and normalized target match the QE
mapping defined under legacy adoption below. Preserve and fail on regular files,
foreign links, stale temporary targets, or other ambiguous content, with an exact
manual recovery instruction. The ignore rules are defense in depth; they must
not hide unresolved foreign content from this preflight.

The existing `split-monitor-workspaces` checkout requires a bounded migration:

1. Verify the exact nested checkout, including its repository identity, before
   moving it.
2. Stage it outside the dotfiles source tree without updating or resetting it.
3. Restow so `~/.config/hypr` and its shared parents become real directories.
4. Restore the checkout at
   `~/.config/hypr/plugins/split-monitor-workspaces`, or clone it there only when
   no existing checkout was present.
5. Fail and preserve unexpected plugin content rather than deleting it.

The historical `systemd` Stow package requires a separate bounded migration
because all of its current leaves are transferred to QE and the package may no
longer exist when restow runs. Recognize only the exact folded
`~/.config/systemd` link into
`~/dotfiles/_hyprland/systemd/.config/systemd`, including its dangling form after
an updated dotfiles checkout. Replace that parent with real
`~/.config/systemd/user` directories only after confirming one of these exact
forms: an existing target whose contents are limited to the recognized
`qe-shell.service` and `/dev/null` Dunst mask, or a dangling target where the
coordinated dotfiles revision has removed that entire package. Existing targets
with additional or modified content are preserved and rejected. Do not depend
on enumerating or restowing the removed package.

Coordinate the rollout in this order:

1. Remove transferred QE assets from the coordinated dotfiles revision and add
   the Stow-specific ignore rules.
2. Update Arch Setup with the early validation, bounded migration, and no-folding
   restow behavior.
3. On execution, validate target identity and repository identity/cutover
   compatibility before destructive preparation.
4. Classify and migrate the historical folded `systemd` path, recognized
   generated source-tree links, and nested plugin checkout as specified above.
5. Restow dotfiles to produce real shared XDG parent directories and prune old
   links where Stow can recognize them.
6. Invoke the QE installer.
7. Have QE refuse deployment if a managed parent remains a symlink or the old
   dotfiles source still declares the retired QE asset.

Do not automatically update, pull, reset, or checkout any repository. Fresh
Arch Setup clones current repositories. Existing incompatible or partial
checkouts fail with exact update/recovery instructions. A dirty but structurally
valid QE checkout may proceed with a prominent warning.

## QE Deployment Assets

Add repository-owned assets for:

- the static `qe-shell.service`;
- the three QE desktop entries;
- the optional `qe-theme-switcher` adapter;
- the Dunst user-service mask contract.

Install direct public-command symlinks:

```text
qe-shell     -> scripts/run-qe.sh
qe-lock      -> scripts/run-qe-lock.sh
qe-action    -> scripts/qe-action.sh
qe-launch    -> scripts/qe-launch.sh
qe-defaults  -> scripts/qe-defaults
qe-doctor    -> scripts/qe-doctor
qe-hyprshot  -> scripts/qe-hyprshot.sh
qe-theme-switcher -> scripts/qe-theme-switcher
```

This must preserve the current public CLI, including:

```sh
qe-shell --restart
```

Use absolute links into the fixed production checkout. Verify source executable
modes rather than silently changing checkout files.

Use portable desktop icon names rather than absolute Breeze icon paths. The user
unit must remain static and omit `[Install]`; never enable it against a graphical
target.

## Ownership Classification and Legacy Adoption

Classify each destination before mutation:

1. absent;
2. already correct;
3. stale but unambiguously QE-owned;
4. exact recognized legacy deployment;
5. unknown or user-owned conflict.

Automatically adopt only these exact legacy forms:

- each exact current public wrapper together with the exact current
  `qe-project` dispatcher;
- historical direct links resolving to the expected QE helper;
- the exact current static `qe-shell.service`;
- the exact current QE desktop entries;
- a Dunst service link resolving exactly to `/dev/null`;
- a known generated-theme destination whose normalized link target exactly
  matches its QE state target in the closed mapping below.

The generated-theme legacy mapping is destination plus normalized target, never
basename or suffix alone:

```text
$HOME/.config/bat/themes/wallpaper.tmTheme
  -> $XDG_STATE_HOME/qe/wallpaper/external/bat-wallpaper.tmTheme
$HOME/.config/btop/themes/wallpaper.theme
  -> $XDG_STATE_HOME/qe/wallpaper/external/btop-wallpaper.theme
$HOME/.config/eza/themes/wallpaper.yml
  -> $XDG_STATE_HOME/qe/wallpaper/external/eza-wallpaper.yml
${ZSH_CONFIG_HOME:-$HOME/.config/zsh}/fzf_themes/wallpaper.zsh
  -> $XDG_STATE_HOME/qe/wallpaper/external/fzf-wallpaper.zsh
$HOME/.config/hypr/themes/hyprland/wallpaper.lua
  -> $XDG_STATE_HOME/qe/wallpaper/external/hyprland-wallpaper.lua
$HOME/.config/imv/themes/wallpaper.conf
  -> $XDG_STATE_HOME/qe/wallpaper/external/imv-wallpaper.conf
$HOME/.config/kitty/themes/wallpaper.conf
  -> $XDG_STATE_HOME/qe/wallpaper/external/kitty-wallpaper.conf
$HOME/.config/mpv/themes/wallpaper.conf
  -> $XDG_STATE_HOME/qe/wallpaper/external/mpv-wallpaper.conf
$HOME/.config/opencode/themes/wallpaper.json
  -> $XDG_STATE_HOME/qe/wallpaper/external/opencode-wallpaper.json
$HOME/.config/rofi/themes/colorschemes/wallpaper.rasi
  -> $XDG_STATE_HOME/qe/wallpaper/external/rofi-wallpaper.rasi
$HOME/.config/starship/themes/wallpaper.sh
  -> $XDG_STATE_HOME/qe/wallpaper/external/starship-wallpaper.sh
$HOME/.config/tmux/themes/wallpaper.conf
  -> $XDG_STATE_HOME/qe/wallpaper/external/tmux-wallpaper.conf
$HOME/.config/yazi/flavors/wallpaper.yazi/wallpaper.sh
  -> $XDG_STATE_HOME/qe/wallpaper/external/yazi-wallpaper.sh
$HOME/.config/yazi/flavors/wallpaper.yazi/tmtheme.xml
  -> $XDG_STATE_HOME/qe/wallpaper/external/yazi-wallpaper.tmTheme
```

The retired Dunst and Hyprlock wallpaper slots are not members of this adoption
mapping. Exact legacy contents and normalized targets needed after dotfiles
removal must be frozen as QE installer fixtures rather than discovered by
executing or trusting the updated dotfiles checkout.

Adoption is allowed only after shared parents are real directories and dotfiles
no longer declares the asset. Inspect legacy files; never execute them during
classification.

Preserve and fail on modified wrappers, unknown regular files, foreign links, or
ambiguous ownership. Do not adopt old `select_theme`, `select_wallpaper`,
`theme`, or `wallpaper` commands as QE aliases.

The current `wallpaper` and `select_wallpaper` commands bypass
WallpaperService's confirmed state by rewriting the shared wallpaper artifact
and restarting Hyprpaper directly. Remove both commands and the
`select-wallpaper.desktop` launcher during the coordinated dotfiles cutover.
Do not replace them with compatibility aliases. Other unrelated legacy commands
remain outside this migration.

## Non-Destructive Defaults Bootstrap

Extend `scripts/qe-defaults` with:

```text
qe-defaults seed
```

`seed` must:

- share an exclusive lock with other mutating defaults/installation operations
  through the single-owner model below;
- validate all required source artifacts before mutation;
- create missing required artifacts through temporary siblings and atomic
  rename;
- preserve existing wallpaper and active-theme state;
- repair only recognized stale QE-generated links;
- create optional external application links only when their destinations are
  appropriate;
- preserve foreign external slot files and emit specific warnings;
- avoid creating retired Dunst theme slots;
- avoid applying the manifest theme on every rerun;
- avoid fabricating WallpaperService's confirmed selected-wallpaper state.

A fresh seed must provide the files needed for a usable first frame, including:

- a valid current wallpaper for Hyprpaper;
- generated `Wallpaper.json`;
- required generated external artifacts;
- the authored Neovim palette where applicable.

ThemeService may establish default active-theme state during first startup.
WallpaperService must establish confirmed wallpaper selection through its own
service behavior.

Keep `qe-defaults restore` as the explicit reset/recovery operation with its
documented replacement semantics.

The installer is the lock owner for an installation run. It acquires the shared
exclusive lock once before the first mutating leaf and keeps that descriptor
across defaults seeding. The internal seed path recognizes the inherited,
already-held descriptor and must not acquire a second lock. A directly invoked
`qe-defaults seed` acquires and owns the same lock itself. Untrusted callers
cannot assert lock ownership without the inherited descriptor. This is an
internal call convention, not a new public command option.

## Dunst and Competing Components

After explicit authorization, persist:

```text
$XDG_CONFIG_HOME/systemd/user/dunst.service -> /dev/null
```

Creating the persistent mask must not require a live user manager.
In the Arch-integrated flow, authorization is the affirmative QE-specific
installation choice defined above. The shim must never infer authorization from
Hyprland selection or non-interactive execution alone.

When a live user manager exists:

1. stop Dunst only when systemd identifies it as active `dunst.service`;
2. wait boundedly for its notification DBus ownership to be released;
3. fail on an unmanaged/unknown notification owner rather than killing it;
4. start QE and verify ownership belongs to QE's supervised PID.

Never kill arbitrary Dunst, Waybar, or Hyprlock processes. Their live presence
prevents readiness and produces `activation-failed`. Do not restore Dunst when
QE activation fails; ADR-046 retired that fallback.

## Hyprland, Hypridle, and Hyprpaper Verification

QE must verify caller-owned configuration without rewriting it.

For the known dotfiles layout:

- validate the active `hyprland.lua` and authored Lua syntax;
- follow its loaded module graph to the actual `autostart.lua`;
- verify Hyprpaper startup;
- verify Hypridle startup;
- verify `qe-shell --service-start` startup;
- inspect active Hypridle configuration for lock routing through `qe-lock`;
- inspect active Hyprpaper configuration for QE's managed current wallpaper;
- reject active startup paths for Dunst, Waybar, or Hyprlock.

Do not treat a search match in an unloaded/archive file as proof. Do not use
`Hyprland --verify-config` as a hard gate while it crashes against this Lua
configuration. Do not initially build a mock Hyprland Lua framework.

Unknown layouts receive exact actionable hook requirements and fail readiness.
The installer does not insert or rewrite arbitrary Hyprland/Lua content.

## Lock and Security Constraints

The production lock remains an isolated, unsupervised `WlSessionLock` process
using Quickshell PAM with `config: "login"`.

Installation must not:

- enable or supervise the lock as part of the shell service;
- acquire a real session lock unattended;
- modify PAM files;
- create a dedicated QE PAM service;
- expose unlock through IPC;
- log or persist PAM responses.

Unattended validation is limited to:

- readable `/etc/pam.d/login`;
- required Quickshell PAM and Wayland module capability;
- isolated QML import/fixture tests;
- verified Hypridle routing to `qe-lock`.

Real lock acquisition, PAM authentication, crash behavior, and before-sleep
testing require the documented recovery-aware VM/manual path with alternate TTY
access.

## Installation and Activation State

Persist the atomic process-independent installation receipt at:

```text
$XDG_STATE_HOME/qe/installation.json
```

Do not use or reproduce Quickshell's configuration-path-scoped state directory
for this receipt. Installer, activation, and `qe-doctor` must use one shared path
resolver. The canonical outcomes are:

```text
activation-deferred
ready
activation-failed
```

The initial schema is version `1` and contains at least:

```text
schemaVersion
outcome
attemptId
attemptedAt
checkoutPath
errorCode
errorContext
```

`checkoutPath` must identify the supported managed checkout. `errorCode` and
`errorContext` are null on success/defer unless concise context is needed, and
must contain enough information on failure for `qe-doctor` to report the next
action without duplicating full journal logs. Additional timestamp fields and
the atomic temporary-file naming are implementation details. Unknown or
malformed schema versions are preserved, reported, and replaced only by a later
completed installation or activation attempt.

`ready` records the last successfully completed activation attempt; it is not a
claim of current liveness after logout, package changes, or later service
failure. `qe-doctor` combines the receipt with current live checks. Every
activation attempt that reaches the canonical activation entry point atomically
replaces the receipt with `ready` or `activation-failed`, including environment,
user-manager, Dunst-cutover, restart, and readiness failures.

### Pre-Login Installation

When no real user manager/Hyprland session is available:

1. complete package/capability checks that are valid pre-login;
2. deploy commands and assets;
3. seed defaults;
4. persist the authorized Dunst mask;
5. write `activation-deferred` atomically;
6. return success.

Do not fabricate runtime/session variables or enable lingering.

### Live Activation

`qe-shell --service-start` remains the canonical Hyprland activation and retry
entry point. It must:

1. validate that `XDG_RUNTIME_DIR` belongs to the effective UID, the user bus and
   user manager are reachable, the Hyprland instance signature resolves to a
   live current-user socket, and a bounded Hyprland IPC query succeeds;
2. import `WAYLAND_DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE`, and
   `XDG_CURRENT_DESKTOP` into the user manager;
3. run `systemctl --user daemon-reload`;
4. complete live Dunst cutover;
5. restart the static `qe-shell.service`;
6. perform bounded readiness polling;
7. atomically record `ready` or `activation-failed`.

Readiness requires:

- one stable systemd `InvocationID` and valid current service `MainPID` for all
  observations;
- a new `Configuration Loaded` marker correlated to that invocation by
  `InvocationID` or a pre-restart journal cursor;
- exactly one managed `shell.qml` instance for the current graphical session,
  identified through structured Quickshell list output and matching the service
  `MainPID`;
- notification DBus ownership belonging to the supervised QE PID;
- status-notifier watcher ownership belonging to that PID;
- no running Dunst, Waybar, or Hyprlock;
- the service process environment matching the current Hyprland compositor
  environment.

Capture `InvocationID` and `MainPID` before collecting readiness facts and read
them again afterward; accept only if both are unchanged. After the load marker,
the same invocation and PID must survive Quickshell's existing ten-second
immediate-crash guard before `ready` is written. Keep polling bounded, and write
`activation-failed` when the invocation changes, exits, loses required ownership,
or fails to stabilize. Scope singleton and competing-process checks to the
target user and current graphical session rather than unrelated users/sessions.

Do not block graphical login, launch a fallback shell, or depend on desktop
notifications for failure reporting. Every later `qe-shell --service-start`,
including a later login, retries activation and replaces a prior failure receipt
on success.

The sanitized Arch Setup invocation normally produces `activation-deferred`.
When Arch Setup is run after the current Hyprland session's startup hook has
already fired, that session will not retry automatically. Print a prominent,
exact recovery instruction before returning success:

```sh
qe-shell --service-start
```

Running that command from the current Hyprland session performs the canonical
activation and receipt transition. A later Hyprland login remains the automatic
retry path.

Extend `qe-doctor` to read and explain the activation receipt. Recovery guidance
must retain the existing public commands:

```sh
qe-doctor
journalctl --user -u qe-shell.service
qe-shell --service-start
```

Do not add another public status command, daemon, or service.

## Interruption, Concurrency, and Reruns

- Perform complete preflight before mutation.
- Acquire the shared installer/defaults lock through the single-owner inherited
  descriptor model; never recursively reacquire it.
- Install individual leaves atomically.
- Complete commands, unit, desktop entries, defaults, and Dunst mask before live
  activation.
- Make every completed leaf independently recognizable.
- On interruption, rerun to repair missing or stale QE-owned leaves.
- Preserve unknown destinations.
- Ensure repeated QE installation is a no-op except for repairing recognized
  QE-owned state and revalidating requirements.
- Ensure repeated Arch Setup plus QE installation remains safe after the
  coordinated Stow transition.
- Never update or reset dirty repositories automatically.

Do not add an installation ownership database, transaction journal, global
backup system, or rollback engine. The activation receipt is the only new
durable installation state; file ownership remains inferable from exact targets,
bundled content, and narrowly recognized legacy forms.

## Repository-Specific Changes

### QE Repository

Implement:

- repository-root `install.sh` entry point and focused installer implementation;
- package inventory, package query, and capability checks;
- repository-owned service, desktop, and optional `qe-theme-switcher` adapter
  assets;
- direct public-command deployment;
- legacy classification/adoption logic;
- Dunst mask and live cutover logic;
- `qe-defaults seed`;
- installation/defaults locking and atomic leaves;
- activation receipt handling;
- bounded first-login/live activation checks;
- `qe-doctor` receipt reporting;
- Quickshell compatibility diagnostics;
- focused tests and documentation listed below.

### Arch Setup Script Repository

Implement:

- early target-user/passwd validation before every target-home mutation;
- repository identity and coordinated-cutover compatibility checks before
  destructive dotfiles preparation;
- `config/hyprland/qe.sh`;
- sourcing of that file near the end of the Hyprland branch;
- focused target-user/passwd validation in the shim;
- an explicitly sanitized allowlisted target-user environment;
- protocol-version `1` handshake and package query invocation;
- strict package-token validation and fixed root Pacman execution;
- zero-package query handling without a Pacman invocation;
- required `NetworkManager.service` and `bluetooth.service` enablement;
- propagation of QE installation failure;
- acceptance of exit-zero `activation-deferred` deployment;
- prominent same-session activation recovery guidance;
- QE-specific opt-in as Dunst-cutover authorization;
- user-dotfiles deployment through `stow --restow --no-folding`;
- Stow-specific exclusions and bounded folded-parent/generated-link/plugin
  migrations;
- validation of the changed Stow behavior.

Do not use `with_pacman_nopasswd` for QE and do not add QE package knowledge to
Arch Setup.

### Dotfiles Repository

Remove ownership of:

- the seven public QE wrappers;
- `qe-project` after direct-link deployment is available;
- `qe-theme-switcher` after the QE-owned adapter is available;
- `qe-shell.service`;
- QE desktop entries;
- the Dunst mask;
- the legacy `wallpaper` and `select_wallpaper` commands;
- the legacy `select-wallpaper.desktop` launcher.

Retain:

- Hyprland startup composition;
- QE-facing keybindings;
- Hypridle and Hyprpaper policy;
- machine-specific configuration;
- optional non-QE and legacy user commands unless separately retired.

Ensure required QE startup and secure-lock hooks match the installer verifier.

## Validation Plan

Follow `docs/VALIDATION.md` and risk-based testing. Do not add tests that merely
mirror package arrays or output formatting.

### QE Static and Focused Tests

- Run `shellcheck` for every new or changed shell file.
- Run affected QML lint and required-module import probes.
- Validate JSON and default artifacts.
- Verify the static unit with `systemd-analyze --user verify`.
- Test the exact protocol-version `1` stdout/stderr, exit, and no-persistent-state
  contract.
- Test package-query stdout/stderr and failure contracts.
- Test clean installation in isolated standard XDG fixtures.
- Test an unchanged second run.
- Test interrupted-run repair.
- Test folded-parent and old-dotfiles-owner refusal.
- Test exact legacy adoption and unknown-file preservation.
- Test Dunst authorization behavior.
- Test no-session installation producing `activation-deferred`.
- Test required versus optional dependency handling.
- Test Quickshell older/newer/capability outcomes.
- Test `qe-defaults seed` missing-only behavior, preservation, stale-link repair,
  foreign-slot warnings, direct lock ownership, and inherited-lock operation
  without recursive acquisition.
- Test receipt schema/version/path handling, malformed receipt preservation,
  atomic replacement, and last-success-versus-live-state reporting.
- Test activation environment rejection, one-invocation readiness correlation,
  and immediate-crash-window failure.
- Run affected existing entrypoint, defaults, doctor, singleton, notification,
  wallpaper, and lock fixture tests.

### Arch Setup Tests

- Test `stow --restow --no-folding` against representative user-dotfile packages.
- Test migration of the exact historical folded `~/.config/systemd` link,
  including its dangling post-update form and unexpected-content refusal.
- Test generated source-link classification, stale temporary/foreign-link
  refusal, Stow-specific ignores, and preservation of unknown content.
- Test migration of the nested plugin checkout out of the Stow source tree.
- Verify transferred QE links are pruned or left in an adoptable exact form.
- Test target-user identity mismatch and nonstandard passwd-home handling.
- Test that target-user validation occurs before any target-home mutation.
- Test repository identity/cutover compatibility failure before destructive Stow
  preparation.
- Test the sanitized allowlisted user environment, including inherited forbidden
  session variables.
- Test protocol-version mismatch and package-query failure.
- Test a successful empty package query and confirm Pacman is not invoked.
- Test malformed and option-like package-token rejection.
- Test Pacman failure propagation.
- Test successful handling of an exit-zero `activation-deferred` result.

### VM and Integration Acceptance

Use a clean Arch/Hyprland VM snapshot:

1. run Arch Setup before the first Hyprland login;
2. verify static deployment records `activation-deferred`;
3. reboot or log into Hyprland;
4. verify transition to `ready`;
5. verify exactly one current-environment QE instance;
6. verify QE notification and tray ownership;
7. verify Dunst remains masked and inactive;
8. verify Hypridle and Hyprpaper are singular and operational;
9. repeat logout/login and compositor restart;
10. rerun Arch Setup and the QE installer;
11. run Arch Setup inside an already-running Hyprland session, verify the
    prominent `qe-shell --service-start` guidance, invoke it, and verify the
    receipt transition;
12. exercise a partially configured legacy deployment;
13. inject missing checkout/module/default, disabled required service, immediate
    QML failure, stale links, and live Dunst/unknown-owner conflicts;
14. verify durable, actionable activation failures and successful retry;
15. verify readiness never succeeds across an `InvocationID`/`MainPID` change or
    before the immediate-crash window has passed.

Run real lock/PAM/before-sleep tests only with alternate-TTY recovery. Use
physical validation only for hardware behavior a VM cannot prove, such as
brightness, battery, suspend, or monitor hotplug.

## Documentation Changes

Add:

- `docs/architecture/INSTALLATION.md` as the durable installation contract;
- one narrow installation routing row in `AGENTS.md`;
- one installation route in `docs/ARCHITECTURE.md`;
- one ADR in `docs/DECISIONS.md` covering the durable ownership boundary:
  - QE owns requirements and generic deployment;
  - Arch Setup owns orchestration and base preparation;
  - dotfiles owns user/session policy;
  - QE verifies rather than rewrites caller-owned policy;
  - the authorized installer persists the Dunst mask before first live
    activation and does not restore it after activation failure;
  - this installation policy explicitly supersedes ADR-008's acceptance-before-
    disablement ordering and ADR-025's reversible dotfiles-owned mask consequence,
    while preserving their notification-owner safety rationale;
  - retirement of the legacy `wallpaper` and `select_wallpaper` entry points
    supersedes ADR-042's consequence that the legacy `wallpaper` script remains
    untouched, without changing ADR-042's QE/Hyprpaper ownership model.

Update only affected sections of:

- `docs/architecture/PROJECT_MODEL.md`;
- `docs/architecture/RUNTIME.md`;
- `docs/architecture/THEMING.md` for retirement of the legacy wallpaper bypass;
- `docs/VALIDATION.md`;
- `docs/STATUS.md` when installation becomes supported production behavior;
- `docs/USER_GUIDE.md` with concise user-facing installation and recovery steps.

Add `activation deferred`, `ready installation`, and `activation failure` to
`CONTEXT.md` only if those terms remain part of the implemented external domain
contract. Keep implementation detail and status out of the glossary.

Do not add phase documents, a second ADR, or a separate design-history document.

## Completion Criteria

Implementation is complete when:

- a fresh Arch Setup Hyprland run can invoke QE without duplicated dependency
  knowledge;
- the pre-login installer safely reaches `activation-deferred`;
- first Hyprland login transitions that installation to `ready` or records an
  actionable `activation-failed` result;
- all public QE commands, including `qe-shell --restart`, work through QE-owned
  direct links;
- QE owns its unit, desktop entries, defaults bootstrap, and Dunst mask;
- dotfiles retains only session/user policy;
- missing requirements are installed only through explicit authorization or
  reported clearly;
- optional integrations do not block installation;
- unknown user configuration is never overwritten;
- repeated Arch Setup and QE installer runs are safe and idempotent;
- focused automated and VM acceptance checks pass;
- installation architecture, validation, status, and user documentation match
  the implemented behavior.
