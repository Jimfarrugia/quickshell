# Developer Validation

Run from the project root:

```sh
node tests/js/validation.test.mjs
node tests/js/schema.test.mjs
node tests/js/system-metrics.test.mjs
node tests/js/brightness.test.mjs
bash tests/helpers/system-metrics-helper.test.sh
bash tests/helpers/brightness-helper.test.sh
bash tests/helpers/single-instance.test.sh
qmllint *.qml components/*.qml modules/test_surface/*.qml modules/bar/*.qml services/*.qml integrations/*.qml tests/fixtures/qml/*.qml
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
