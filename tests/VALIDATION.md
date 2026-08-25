# Developer Validation

Run from the project root:

```sh
node tests/js/validation.test.mjs
node tests/js/schema.test.mjs
node tests/js/system-metrics.test.mjs
node tests/js/brightness.test.mjs
node tests/js/external-theme.test.mjs
bash tests/helpers/system-metrics-helper.test.sh
bash tests/helpers/brightness-helper.test.sh
bash tests/helpers/single-instance.test.sh
bash tests/helpers/theme-hot-reload.test.sh
bash tests/helpers/theme-selector-ipc.test.sh
bash tests/helpers/external-theme-adapter.test.sh
qmllint *.qml components/*.qml modules/test_surface/*.qml modules/bar/*.qml modules/theme/*.qml services/*.qml integrations/*.qml tests/fixtures/qml/*.qml
timeout 5 quickshell -p command-runner-test.qml
timeout 5 quickshell -p foundation-service-test.qml
timeout 5 quickshell -p foundation-service-test.qml
timeout 5 quickshell -p phase2-service-test.qml
timeout 5 quickshell -p phase3-service-test.qml
timeout 5 quickshell -p system-metrics-adapter-test.qml
timeout 5 quickshell -p system-metrics-helper-adapter-test.qml
timeout 5 quickshell -p brightness-service-test.qml
timeout 5 quickshell -p brightness-adapter-test.qml
timeout 5 quickshell -p bluetooth-service-test.qml
timeout 5 quickshell -p bluetooth-integration-test.qml
timeout 5 quickshell -p bluetooth-adapter-test.qml
timeout 5 quickshell -p idle-service-test.qml
timeout 5 quickshell -p tray-tint-test.qml
timeout 5 quickshell -p theme-selector-test.qml
timeout 5 quickshell -p external-theme-service-test.qml
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
`THEME_SELECTOR_IPC_TEST_PASSED` after proving the `qe-theme` target and its
`open`, `close`, `toggle`, and `isOpen` methods against that exact PID.
The selector interaction test must print `THEME_SELECTOR_TEST_PASSED` after a
catalog selection becomes the confirmed resolved live theme.
The external theme service test uses a fake adapter and must print
`EXTERNAL_THEME_SERVICE_TEST_PASSED` after QE commits first and retains that
theme through a truthful external partial-failure result.
The external adapter helper must print `EXTERNAL_THEME_ADAPTER_TEST_PASSED`
after sandboxed success, partial, malformed-output, timeout, invalid theme ID,
missing-executable, independent valid/malformed state updates, and
executable-loss cases.

Relocation is checked by copying the project to a temporary directory and
repeating the JavaScript validation and shell smoke test there. QE state created
by a development run is isolated under Quickshell's per-shell XDG state path and
can be removed after QE is stopped.

Catalog degradation is tested only in a disposable relocated copy: replace that
copy's `themes/poimandres.json` with
`tests/fixtures/themes/missing-token.json`, then run:

```sh
timeout 5 quickshell -p theme-degradation-test.qml
```

The test must print `THEME_DEGRADATION_TEST_PASSED`. Never replace an authored
theme in the working project for this test.

The live NetworkManager IPv4 test is opt-in because it requires `nmcli`, a
running NetworkManager daemon, and an IPv4 loopback address:

```sh
timeout 5 quickshell -p network-address-test.qml
```

It must print `NETWORK_ADDRESS_TEST_PASSED`.
