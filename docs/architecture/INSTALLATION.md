# Installation

Authoritative for QE package requirements, static deployment, ownership
classification, defaults bootstrap, Dunst cutover, activation, and installation
receipts. Installation is an opt-in provisioning domain and is not runtime
configuration ownership.

## Ownership

QE owns its complete package inventory, capability checks, generic deployment
assets, public commands, default bootstrap, Dunst mask, and installation and
activation outcomes. Arch Setup owns target-user discovery, base Arch/Hyprland
preparation, the privileged Pacman transaction requested by QE, system-service
enablement, dotfiles deployment, and invocation timing. Dotfiles owns user and
session policy, including Hyprland composition, keybindings, Hypridle,
Hyprpaper, monitor policy, and non-QE startup. QE verifies that policy and never
rewrites it.

The supported production checkout is `$HOME/Projects/quickshell`; production
uses the conventional XDG roots. This preserves Quickshell's configuration-path
state identity. Explicit fixture variables may relocate paths in tests but are
not production interfaces.

## Public Interface

`install.sh` rejects root execution and exposes:

```text
./install.sh check
./install.sh protocol-version
./install.sh package-query
./install.sh install [--packages] [--non-interactive]
                     [--authorize-dunst-cutover]
./install.sh activate
```

`protocol-version` prints exactly `1` plus a newline and performs no checks or
writes. `package-query` prints only missing official package names and fails
without partial output when package state cannot be trusted. `check` is
non-mutating; writable Quickshell probes use private temporary XDG roots.
`install --packages` uses ordinary `sudo` only for fixed
`pacman -S --needed --noconfirm -- ...` arguments; `-n` is added only with
`--non-interactive`. `activate` delegates directly to
`qe-shell --service-start`. Exit statuses are 0 for complete static deployment
with ready or legitimately deferred activation, 1 for operational failure, and
2 for invalid invocation.

The package inventory is `scripts/install/packages.txt`. Package state chooses
the Pacman delta, while executable, Python import, font, QML import/API, PAM,
unit, authored-artifact, and caller-hook checks establish capability. Quickshell
0.3.1 is the minimum and newest validated release; newer releases warn after
passing probes. Hyprland 0.56.2 is the validated baseline, not an invented
minimum. Missing optional applications, repositories, credentials, daemons, or
hardware degrade only their integrations.

## Deployment And Adoption

QE installs direct absolute links under `$HOME/.local/bin`, its static unit
without `[Install]`, three desktop entries with portable icon names, and the
optional theme-switcher adapter. Shared managed parents must be real
directories. The installer refuses a dotfiles checkout that still declares
transferred leaves.

Each leaf is classified before mutation. Absent and already-correct leaves are
safe. Exact legacy dispatcher wrappers, direct links to the expected helper,
the frozen unit/desktop content, `/dev/null` Dunst mask, and the closed generated
wallpaper target mapping may be adopted. Unknown regular files, modified
wrappers, foreign links, folded parents, and ambiguous generated slots are
preserved and fail or warn as appropriate. No ownership database, rollback
engine, or broad migration framework exists.

The installer and `qe-defaults` share
`$XDG_STATE_HOME/qe/install.lock`. An installer owns one exclusive descriptor
across all leaves and `qe-defaults seed`; seed accepts inheritance only when the
open descriptor and declared path resolve to that lock. Direct seed owns the
same lock itself. Seed validates the authored bundle first, atomically creates
only missing required runtime artifacts, preserves wallpaper and active-theme
state, repairs only recognized links, warns and preserves foreign optional
slots, omits retired Dunst/Hyprlock slots, and never fabricates confirmed
WallpaperService selection. `qe-defaults restore` remains the explicit
replacement/recovery operation.

## Dunst And Activation

Dunst cutover requires `--authorize-dunst-cutover` or explicit interactive
confirmation; non-interactive mode alone grants nothing. Authorization persists
`$XDG_CONFIG_HOME/systemd/user/dunst.service -> /dev/null` before activation and
does not require a user manager. QE does not restore Dunst after failure.

Without a real user manager and Hyprland session, installation atomically writes
`activation-deferred`, returns zero, and tells an already logged-in user to run
`qe-shell --service-start`. The canonical activation validates runtime-directory
ownership, user bus/manager reachability, the current-user Hyprland socket and
IPC, imports compositor environment, reloads systemd, stops only a
systemd-confirmed Dunst owner, restarts the static service, and polls boundedly.
It never kills an arbitrary notification owner or competing process.

Readiness requires one stable `InvocationID` and `MainPID`, a load marker for
that invocation, exactly one matching `shell.qml` object from
`qs list --all --json`, QE ownership of notification and status-notifier DBus
names, no current-session Dunst/Waybar/Hyprlock, matching compositor environment,
and survival through Quickshell's ten-second immediate-crash guard. Any
activation attempt atomically records `ready` or `activation-failed`.

## Receipt

The process-independent schema-v1 receipt is
`$XDG_STATE_HOME/qe/installation.json` and contains `schemaVersion`, `outcome`,
`attemptId`, `attemptedAt`, `checkoutPath`, `errorCode`, and `errorContext`.
Canonical outcomes are `activation-deferred`, `ready`, and
`activation-failed`. Ready describes the last completed activation, not current
liveness. Unknown/malformed receipts are preserved and reported by `qe-doctor`;
only a later completed installation or activation attempt replaces one.
