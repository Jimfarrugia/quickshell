# Developer Validation

## How to use this file

`docs/PLAN.md` owns phase acceptance criteria. This file owns the concrete
developer commands, expected success markers, and special test conditions.

Implementation agents should read the subsection relevant to the changed
subsystem before testing. Run the broader command catalogue when the active
phase or regression scope requires it; do not load unrelated historical phase
records merely to discover test commands.

## Command catalogue

Run from the project root. This file is stored under `docs/`, but all commands
below are intended to be run from the repository root:

```sh
node tests/js/validation.test.mjs
node tests/js/schema.test.mjs
node tests/js/system-metrics.test.mjs
node tests/js/brightness.test.mjs
node tests/js/external-theme.test.mjs
node tests/js/matugen.test.mjs
node tests/js/external-wallpaper-theme.test.mjs
node tests/js/launcher.test.mjs
node tests/js/help.test.mjs
node tests/js/ai-quota.test.mjs
python3 -m unittest tests/python/test_ai_quota.py
bash tests/helpers/system-metrics-helper.test.sh
bash tests/helpers/brightness-helper.test.sh
bash tests/helpers/single-instance.test.sh
bash tests/helpers/theme-hot-reload.test.sh
bash tests/helpers/theme-selector-ipc.test.sh
bash tests/helpers/dashboard-ipc.test.sh
bash tests/helpers/ai-quota-persistence.test.sh
bash tests/helpers/external-theme-adapter.test.sh
bash tests/helpers/wallpaper-cache.test.sh
bash tests/helpers/wallpaper-helper.test.sh
bash tests/helpers/wallpaper-service.test.sh
bash tests/helpers/wallpaper-promotion.test.sh
bash tests/helpers/wallpaper-generation-failure.test.sh
bash tests/helpers/wallpaper-selector-ipc.test.sh
bash tests/helpers/qe-launch.test.sh
bash tests/helpers/qe-defaults.test.sh
bash tests/helpers/external-wallpaper-theme.test.sh
bash tests/helpers/external-wallpaper-theme-service.test.sh
bash tests/helpers/notification-owner.test.sh
bash tests/helpers/notification-service.test.sh
bash tests/helpers/notification-reload.test.sh
bash tests/helpers/notifications.test.sh
YAZI_TEMPLATE="$HOME/.config/yazi/flavors/flavor.template.toml" \
QE_PROJECT_ROOT="$PWD" \
  bash ../theme-switcher/tests/test_yazi.sh
bash ../theme-switcher/tests/test_media_themes.sh
bash tests/helpers/window-opacity.test.sh
bash tests/helpers/repeated-wallpaper-generation.test.sh
bash tests/helpers/generated-theme-hot-reload.test.sh
bash tests/helpers/queued-wallpaper-generation.test.sh
bash tests/helpers/wallpaper-theme-select-external.test.sh
bash tests/helpers/restored-wallpaper-theme.test.sh
qmllint $(find . -maxdepth 1 -name '*.qml') $(find components modules services tests -name '*.qml') $(find integrations -maxdepth 1 -name '*.qml' ! -name 'ThemeSelectorIpc.qml' ! -name 'WallpaperSelectorIpc.qml' ! -name 'PaletteViewerIpc.qml')
timeout 5 quickshell -p tests/qml/command-runner-test.qml
# Run the next command twice without changing XDG_STATE_HOME between runs.
timeout 5 quickshell -p tests/qml/foundation-service-test.qml
timeout 5 quickshell -p tests/qml/foundation-service-test.qml
timeout 5 quickshell -p tests/qml/phase2-service-test.qml
timeout 5 quickshell -p tests/qml/phase3-service-test.qml
timeout 5 quickshell -p tests/qml/system-metrics-adapter-test.qml
timeout 5 quickshell -p tests/qml/system-metrics-helper-adapter-test.qml
timeout 5 quickshell -p tests/qml/brightness-service-test.qml
timeout 5 quickshell -p tests/qml/brightness-adapter-test.qml
timeout 5 quickshell -p tests/qml/bluetooth-service-test.qml
timeout 5 quickshell -p tests/qml/bluetooth-integration-test.qml
timeout 5 quickshell -p tests/qml/bluetooth-adapter-test.qml
timeout 5 quickshell -p tests/qml/bluetooth-dashboard-test.qml
timeout 5 quickshell -p tests/qml/idle-service-test.qml
timeout 5 quickshell -p tests/qml/tray-tint-test.qml
timeout 5 quickshell -p tests/qml/theme-selector-test.qml
timeout 5 quickshell -p tests/qml/wallpaper-selector-test.qml
timeout 5 quickshell -p tests/qml/segmented-toggle-test.qml
timeout 5 quickshell -p tests/qml/palette-viewer-test.qml
timeout 5 quickshell -p tests/qml/dashboard-shell-test.qml
timeout 5 quickshell -p tests/qml/audio-dashboard-test.qml
timeout 7 quickshell -p tests/qml/network-dashboard-test.qml
timeout 5 quickshell -p tests/qml/network-address-test.qml
timeout 5 quickshell -p tests/qml/ai-quota-service-test.qml
timeout 5 quickshell -p tests/qml/ai-quota-adapter-test.qml
timeout 5 quickshell -p tests/qml/ai-quota-bar-test.qml
timeout 5 quickshell -p tests/qml/ai-quota-dashboard-test.qml
timeout 5 quickshell -p tests/qml/ai-quota-multi-consumer-test.qml
timeout 5 quickshell -p tests/qml/launcher-usage-test.qml
timeout 5 quickshell -p tests/qml/launcher-selection-test.qml
timeout 5 quickshell -p tests/qml/launcher-dashboard-action-test.qml
timeout 5 quickshell -p tests/qml/external-theme-service-test.qml
timeout 5 quickshell -p tests/qml/osd-service-test.qml
timeout 5 quickshell -p tests/qml/phase6-action-test.qml
timeout 5 env QE_MATUGEN=<absolute-path-to-fixture> quickshell -p tests/qml/matugen-adapter-test.qml
timeout 5 quickshell -p shell.qml
```

## Expected markers and special conditions

### Core, foundation, bar, and theme-selection tests

The AI quota JavaScript test must print `AI_QUOTA_TEST_PASSED`. The quota QML
tests use a fake adapter and must prove shared provider selection, consumer
registration, independent weekly/five-hour/monthly rendering, dashboard routing, and
stale/unavailable states without accessing live credentials. The adapter test
also verifies that the pending indicator remains active across sequential
provider requests. The dashboard shell test verifies the AI quota header
refresh control and its service request.

Of the timeout-wrapped commands, exit code `124` is acceptable when a headless
QML test has already printed its success marker; the `shell.qml` smoke test
must return `124` because it proves the persistent shell remained alive. The
command-runner test must print `COMMAND_TEST_PASSED`. Run the foundation
test twice with the same XDG state root: the first run may print
`FOUNDATION_THEME_SEEDED`; the second must print
`FOUNDATION_PERSISTENCE_TEST_PASSED`.
The live procfs adapter test must print `SYSTEM_METRICS_ADAPTER_TEST_PASSED`.
The live brightness adapter test must print `BRIGHTNESS_ADAPTER_TEST_PASSED` and
does not perform a brightness write.
The live Bluetooth adapter test must print `BLUETOOTH_ADAPTER_TEST_PASSED` and
does not change controller or device state.
The single-instance helper test starts an isolated fixture configuration and
must prove that `--no-duplicate` leaves exactly one process running.
The theme hot-reload helper copies the project to a temporary directory and must
print `THEME_HOT_RELOAD_AND_CATALOG_TEST_PASSED` after valid, invalid, and
recovered active-theme edits plus catalog add, malformed, duplicate-ID, removal,
and active-source loss/recovery cases without restarting the test shell.
The selector IPC helper starts an isolated shell process and must print
`THEME_SELECTOR_IPC_TEST_PASSED` after proving the `qe-theme` and
`qe-wallpaper` targets, selector visibility methods, confirmed theme queries,
and idempotent theme application against that exact PID.
The selector interaction test must print `THEME_SELECTOR_TEST_PASSED` after a
catalog selection becomes the confirmed resolved live theme.
The launcher usage test must print `LAUNCHER_USAGE_TEST_PASSED` after validating
persisted usage with the QML JavaScript runtime used by the shell.
The launcher selection test must print `LAUNCHER_SELECTION_TEST_PASSED` after
provisional startup selection resets to the first result while explicit user
selection survives a catalog refresh.
The launcher dashboard action test must print `LAUNCHER_DASHBOARD_ACTION_TEST_PASSED`
after discovering stable audio metadata and toggling the dashboard through the
surface contract.
The help test must print `HELP_TEST_PASSED` after validating catalog schemas,
stable-ID merging, category ordering, invalid-entry rejection, and global search.
The wallpaper selector test must print `WALLPAPER_SELECTOR_TEST_PASSED` after
verifying responsive breakpoints, exact 16:9 card sizing after grid gaps, and
focused-filename publication.
The external theme service test uses a fake adapter and must print
`EXTERNAL_THEME_SERVICE_TEST_PASSED` after QE commits first and retains that
theme through a truthful external partial-failure result.
The dashboard shell fixture must print `DASHBOARD_SHELL_TEST_PASSED` after
checking production-controller routing, geometry, dismissal, focus request,
and lazy recreation. The dashboard IPC helper must print
`DASHBOARD_IPC_TEST_PASSED` after checking the namespaced open, close, toggle,
and isOpen contract while the shell remains alive.

### Notification tests

The notification service helper must print `NOTIFICATION_SERVICE_TEST_PASSED` after
testing bounded markup, actions, progress, replacement updates, DND urgency rules,
individual history removal, dismissal with history retention, and `lastGeneration` replay without creating
duplicate history or popups. The live notification helper additionally verifies
that low and normal popups expire after five seconds while history remains. The
owner helper must print `NOTIFICATION_OWNER_HELPER_TEST_PASSED` after
validating the structured current-owner record, wrapper signal handling, QE
parent disappearance, and monitor-child cleanup. The reload helper must also
prove repeated soft reload and full shell restart leave exactly one current
owner-watcher tree and no stale descendants. The live notification acceptance
helper must print `NOTIFICATIONS_TEST_PASSED`; it validates QE ownership, sends
the representative notification matrix, and verifies QE releases the DBus name.
Run it only in an isolated or explicitly approved test session because
notification ownership is exclusive. Dunst is normally masked/inactive after
the completed cutover; Dunst restoration applies only to an explicit rollback
test.
The reload helper must print `NOTIFICATION_RELOAD_TEST_PASSED` after real QE-owned
notifications populate the popup host and history, then a soft reload preserves
history without duplicate visible or history entries; replayed prior-generation
notifications are not shown again as new popups. The notification-center
interaction check must confirm that opening at the newest position clears and
blocks all popups, including critical ones; scrolling away restores popups, and
returning to the newest position blocks them again without clearing history.
While scrolled away from the newest position, prepending new history entries
must preserve the visible scroll anchor and must not jump the list to the top.
The screenshot wrapper check must verify that a saved screenshot produces
`View Image` and `Open Folder` actions, and that each action opens the
expected validated path without modifying the packaged `hyprshot` executable.
It must also publish the saved screenshot through the standard `image-path`
hint so the notification displays its thumbnail.
The notification service check must also verify that actionable notifications
retain their persistent sender endpoint after the popup is hidden and after a
first action so history actions remain repeatedly invokable.
The external adapter helper must print `EXTERNAL_THEME_ADAPTER_TEST_PASSED`
after sandboxed success, partial, malformed-output, timeout, invalid theme ID,
missing-executable, independent valid/malformed state updates, and
executable-loss cases.

### OSD and hardware-action tests

The OSD service fixture must print `OSD_SERVICE_TEST_PASSED` after validating
immediate active-item replacement without stale replay, expiry, operation
resolution, network-state presentation, and non-full charging/discharging
battery state normalization. The Phase 6 action fixture must print
`PHASE6_ACTION_TEST_PASSED` after validating native output mute, microphone mute,
OSD publication, volume unmute-on-step behavior, confirmation above 100 percent,
and the 200 percent upper bound.
The active Hyprland binding check must confirm that volume and screen/keyboard
brightness bindings have press and release handlers controlling one shared
250ms repeat timer; the global keyboard repeat settings must remain unchanged.
Manual hold and rapid opposite-direction tests must produce bounded QE actions,
stop immediately on release, and preserve mute behavior.

### Matugen, wallpaper, and generated-theme tests

The Matugen adapter fixture must print `MATUGEN_ADAPTER_TEST_PASSED` after
mapping a schema-compatible JSON response into a validated QE `Wallpaper`
theme. The wallpaper service fixture must print
`WALLPAPER_SERVICE_TEST_PASSED` after synchronizing a thumbnail manifest and
persisting a generated theme through the service boundary. Use
`tests/helpers/wallpaper-service.test.sh`, which creates a temporary valid image
fixture and supplies `QE_MATUGEN` and `QE_WALLPAPER_ROOT`. Live Matugen execution
additionally requires `QE_MATUGEN` to point to its executable.
The promotion fixture must print `WALLPAPER_PROMOTION_TEST_PASSED` after a
successful staged rename and a failed promotion retains the prior artifact. The
generation-failure fixture must print
`WALLPAPER_GENERATION_FAILURE_HELPER_TEST_PASSED` after malformed Matugen output
leaves the valid last-known-good generated theme unchanged.
The wallpaper helper fixture also verifies that Hyprpaper IPC accepts the
request and that a rejected request restores the prior derived images.
The external-wallpaper helper fixture must print
`EXTERNAL_WALLPAPER_THEME_HELPER_TEST_PASSED` after promoting generated slot
files (success plus absent-executable skip), preserving unchanged files and
Stow-style symlink slots, rejecting invalid specs and paths, and proving
partial promotion. The external wallpaper theme service
fixture must print `EXTERNAL_WALLPAPER_THEME_TEST_PASSED` after the wallpaper
generation pipeline produces the full 17-target spec, including imv, mpv, and
Yazi artifacts, the fake promotion
adapter promotes it, and `externalThemeStatus` reaches `succeeded`.
The repeated wallpaper generation fixture must print
`REPEATED_WALLPAPER_GENERATION_TEST_PASSED` after two successive Matugen
generations in one QE process promote distinct second-generation artifacts.
The generated theme hot-reload fixture must print
`GENERATED_THEME_HOT_RELOAD_TEST_PASSED` after the live catalog is refreshed
twice from atomically replaced `Wallpaper.json` files without a restart.
The queued generation fixture must print
`QUEUED_WALLPAPER_GENERATION_TEST_PASSED` after a wallpaper change requested
while a generation is pending is not dropped: both complete and the published
theme reflects the latest request. The wallpaper theme select external fixture
must print `WALLPAPER_THEME_SELECT_EXTERNAL_TEST_PASSED` after an initial
generation makes `wallpaper` selectable and selecting it dispatches exactly one
external `wallpaper` apply with `--skip-gtk`.
The generated-theme hot-reload fixture must print
`GENERATED_THEME_HOT_RELOAD_TEST_PASSED` after two atomic generated-theme
replacements update the catalog without restarting QE. The repeated wallpaper
generation fixture must print
`REPEATED_WALLPAPER_GENERATION_TEST_PASSED` after two successive Matugen
generations complete in one QE process.
The restored wallpaper fixture must print
`RESTORED_WALLPAPER_THEME_HELPER_TEST_PASSED` after a default generated theme
seeded at the stable XDG data path is catalogued, selected without a persisted
wallpaper source, and delegated to the external switcher with GTK skipped.

### Authored-defaults tests

The authored defaults command contract is tested in isolated XDG and HOME
directories:

```sh
tests/helpers/qe-defaults.test.sh
```

It must print `QE_DEFAULTS_TEST_PASSED` after staged capture, pending-operation
rejection, artifact restore, live-slot repair, fixed-theme application, and the
stopped-QE wallpaper `--skip-gtk` fallback pass.

### Relocation, lint exceptions, degradation, and opt-in live checks

Relocation is checked by copying the project to a temporary directory and
repeating the JavaScript validation and shell smoke test there. QE state created
by a development run is isolated under Quickshell's per-shell XDG state path and
can be removed after QE is stopped.

Headless QML test configurations are validated by their success markers. With
the installed Quickshell build, `Qt.quit()` may emit a warning and leave the
process for the timeout to reap, so exit code `124` is acceptable for these
test configurations as well as for the persistent `shell.qml` smoke test.

`integrations/ThemeSelectorIpc.qml` and `integrations/WallpaperSelectorIpc.qml`
use Quickshell typed IPC functions that `qmllint 1.0` cannot parse (the process
exits 255 without diagnostics), so the lint command above excludes them; both
files are instead verified by the theme-selector and wallpaper-selector IPC
runtime tests.

Catalog degradation is tested only in a disposable relocated copy: replace that
copy's `themes/poimandres.json` with
`tests/fixtures/themes/missing-token.json`, then run:

```sh
timeout 5 quickshell -p tests/qml/theme-degradation-test.qml
```

The test must print `THEME_DEGRADATION_TEST_PASSED`. Never replace an authored
theme in the working project for this test.

The live NetworkManager IPv4 test is opt-in because it requires `nmcli`, a
running NetworkManager daemon, and an IPv4 loopback address:

```sh
timeout 5 quickshell -p tests/qml/network-address-test.qml
```

It must print `NETWORK_ADDRESS_TEST_PASSED`.

### Phase 10 network dashboard

The fixture dashboard test exercises native-shaped Wi-Fi state, active-device
selection, stable duplicate saved/unprofiled identities, security gating and
fallback, serialized operations, scan lifecycle, daemon loss/recovery,
authentication failure, timeout/error paths, wired read-only behavior, and
dashboard rendering without touching a real connection or exposing a credential:

```sh
timeout 7 quickshell -p tests/qml/network-dashboard-test.qml
```

It must print `NETWORK_DASHBOARD_TEST_PASSED`. Also run the existing dashboard
and service tests after network changes:

```sh
timeout 7 quickshell -p tests/qml/dashboard-shell-test.qml
timeout 7 quickshell -p tests/qml/phase2-service-test.qml
```

The fixture must also prove that unrelated mutations are rejected while one is
pending, same-target newer intent is queued as the only successor, each
operation has an independent timeout, NetworkManager loss clears pending state
and recovered native models become current again, and unsupported EAP/WEP/OWE or
unknown security opens the editor without calling `connectWithSettings`.

The NetworkManager editor fallback is launched only through the native
`Process` adapter with the argument array `["nm-connection-editor"]`; no PSK is
included in that command, logs, or QE persistence.

The approved-network live check was performed against the currently connected
saved Wi-Fi profile: QE requested disconnect, observed the native disconnected
state, requested reconnect without a credential, and observed the connection
return. A live NetworkManager restart also produced the expected unavailable
transition, but Quickshell 0.3.1 did not repopulate the Wi-Fi device afterward;
the temporary dashboard `Restart QE` recovery action was verified separately.
