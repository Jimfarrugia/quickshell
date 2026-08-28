# Developer Validation

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
bash tests/helpers/system-metrics-helper.test.sh
bash tests/helpers/brightness-helper.test.sh
bash tests/helpers/single-instance.test.sh
bash tests/helpers/theme-hot-reload.test.sh
bash tests/helpers/theme-selector-ipc.test.sh
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
YAZI_TEMPLATE="$HOME/.config/yazi/flavors/flavor.template.toml" \
QE_PROJECT_ROOT="$PWD" \
  bash ../theme-switcher/tests/test_yazi.sh
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
timeout 5 quickshell -p tests/qml/idle-service-test.qml
timeout 5 quickshell -p tests/qml/tray-tint-test.qml
timeout 5 quickshell -p tests/qml/theme-selector-test.qml
timeout 5 quickshell -p tests/qml/wallpaper-selector-test.qml
timeout 5 quickshell -p tests/qml/segmented-toggle-test.qml
timeout 5 quickshell -p tests/qml/palette-viewer-test.qml
timeout 5 quickshell -p tests/qml/external-theme-service-test.qml
timeout 5 env QE_MATUGEN=<absolute-path-to-fixture> quickshell -p tests/qml/matugen-adapter-test.qml
timeout 5 quickshell -p shell.qml
```

Of the timeout-wrapped commands, exit code `124` is expected only from the
`shell.qml` smoke test because it proves the persistent shell remained alive.
The command-runner test must print `COMMAND_TEST_PASSED`. Run the foundation
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
The wallpaper selector test must print `WALLPAPER_SELECTOR_TEST_PASSED` after
verifying responsive breakpoints, exact 16:9 card sizing after grid gaps, and
focused-filename publication.
The external theme service test uses a fake adapter and must print
`EXTERNAL_THEME_SERVICE_TEST_PASSED` after QE commits first and retains that
theme through a truthful external partial-failure result.
The external adapter helper must print `EXTERNAL_THEME_ADAPTER_TEST_PASSED`
after sandboxed success, partial, malformed-output, timeout, invalid theme ID,
missing-executable, independent valid/malformed state updates, and
executable-loss cases.

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
generation pipeline produces the full 13-target spec, the fake promotion
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

The authored defaults command contract is tested in isolated XDG and HOME
directories:

```sh
tests/helpers/qe-defaults.test.sh
```

It must print `QE_DEFAULTS_TEST_PASSED` after staged capture, pending-operation
rejection, artifact restore, live-slot repair, fixed-theme application, and the
stopped-QE wallpaper `--skip-gtk` fallback pass.

Relocation is checked by copying the project to a temporary directory and
repeating the JavaScript validation and shell smoke test there. QE state created
by a development run is isolated under Quickshell's per-shell XDG state path and
can be removed after QE is stopped.

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
