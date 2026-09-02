import QtQuick
import Quickshell
import Quickshell.Networking
import "services" as Services
import "fixtures/qml" as Fixtures
import "integrations" as Integrations

ShellRoot {
    id: root
    property var testKeys: []
    Fixtures.FakeNetworkDashboardIntegration { id: fake }
    Integrations.NetworkIntegration { id: selector }
    QtObject {
        id: fallback
        property int launches: 0
        property string error: ""
        function launch() { launches++; return true; }
    }
    Loader { source: "modules/network/NetworkDashboard.qml"; onLoaded: root.runChecks(item) }
    function fail(message) { console.error(`NETWORK_DASHBOARD_TEST_FAILED: ${message}`); Qt.quit(); }
    function runChecks(dashboard) {
        const wifi = {type: DeviceType.Wifi, connected: true, name: "wifi-z"};
        const wired = {type: DeviceType.Wired, connected: true, name: "wired-a"};
        const disconnected = {type: DeviceType.Wifi, connected: false, name: "wifi-a"};
        if (selector.selectDeviceFrom([wired, disconnected, wifi]) !== wifi
                || selector.selectDeviceFrom([wired, disconnected]) !== wired
                || selector.selectDeviceFrom([wired, disconnected]).name !== "wired-a")
            return fail("selected-device priority was not deterministic");
        Services.NetworkService.integration = fake;
        Services.NetworkService.fallbackIntegration = fallback;
        Services.NetworkService.setScanning(true);
        Services.NetworkService.setScanning(false);
        Qt.callLater(() => {
            if (Services.NetworkService.networks.length !== 8
                    || Services.NetworkService.networks[0].profiles.length !== 2)
                return fail("saved profiles were not grouped under one SSID");
            root.testKeys = Services.NetworkService.networks.map(row => row.key);
            if (new Set(root.testKeys).size !== root.testKeys.length || root.testKeys[0] === root.testKeys[1])
                return fail("duplicate SSID identities were not stable and distinct");
            if (Services.NetworkService.networks[0].profiles[0].key === Services.NetworkService.networks[0].profiles[1].key)
                return fail("saved profile identities were conflated");
            for (let index = 1; index < Services.NetworkService.networks.length; index++) {
                if (Services.NetworkService.networks[index - 1].network.signalStrength
                        < Services.NetworkService.networks[index].network.signalStrength)
                    return fail("visible networks were not sorted by signal strength");
            }
            if (Services.NetworkService.selectedDeviceLabel !== "wlan0"
                    || Services.NetworkService.interfaceName !== "wlan0")
                return fail(`status and visible networks did not use the selected device (${Services.NetworkService.selectedDeviceLabel}/${Services.NetworkService.interfaceName})`);
            if (!dashboard || !dashboard.visible)
                return fail("dashboard did not render");
            if (!Services.NetworkService.setWifiEnabled(false) || fake.wifiEnabled)
                return fail("Wi-Fi toggle was not requested");
            if (Services.NetworkService.networks[0].network.security === undefined)
                return fail("security metadata was lost");
            if (!Services.NetworkService.isSupportedSecurity(Services.NetworkService.networks[0].network))
                return fail(`fixture security was unexpectedly unsupported: ${Services.NetworkService.networks[0].network.security}`);
            if (Services.NetworkService.connect(Services.NetworkService.networks[0], "short"))
                return fail("short PSK was accepted");
            if (Services.NetworkService.connect(Services.NetworkService.networks[0], "        ")
                    || Services.NetworkService.connect(Services.NetworkService.networks[0], "x".repeat(64)))
                return fail("whitespace-only or overlong PSK was accepted");
            const validPsk = "xxxxxxxx";
            if (!Services.NetworkService.connect(Services.NetworkService.networks[0], validPsk))
                return fail(`approved native connection was rejected (availability=${Services.NetworkService.availability}, busy=${Services.NetworkService.pendingWifiEnabled}, key=${Services.NetworkService.networks[0].key})`);
            if (Services.NetworkService.disconnect(Services.NetworkService.networks[1])
                    || !Services.NetworkService.connect(Services.NetworkService.networks[0], validPsk))
                return fail("mutation serialization did not reject/queue correctly");
            if (fake.recordedPsks.length !== 0)
                return fail("fixture recorded a PSK");
            Qt.callLater(() => {
                fake.wifiDevice.networks.values[0].failAuthentication();
                if (fake.wifiDevice.networks.values[0].connected
                        || Services.NetworkService.operationError.indexOf("Connection failed") !== 0)
                    return fail(`authentication failure was presented as connected (wifiPending=${Services.NetworkService.pendingWifiEnabled}, pending=${Services.NetworkService.pendingTargetKey}, op=${Services.NetworkService.pendingOperation}, error=${Services.NetworkService.operationError}, calls=${fake.calls})`);
                Qt.callLater(() => {
                    fake.wifiDevice.networks.values[0].failAuthentication();
                    continueChecks();
                });
            });
        });
    }
    function continueChecks() {
            const unsupportedNames = ["Enterprise", "EAP", "OWE", "WEP", "Unknown"];
            for (const name of unsupportedNames) {
                const row = Services.NetworkService.networks.find(candidate => candidate.name === name);
                if (!row || !Services.NetworkService.needsFallback(row)
                        || Services.NetworkService.connect(row, "xxxxxxxx")
                        || !Services.NetworkService.openNetworkFallback(row))
                    return root.fail(`${name} did not use the editor fallback`);
            }
            if (fallback.launches !== unsupportedNames.length)
                return root.fail("fallback invocation count was incomplete");
            const malformed = Services.NetworkService.networks.find(row => row.name === "Malformed");
            if (!malformed || malformed.profiles.length !== 1 || malformed.profiles[0].name !== "Malformed")
                return root.fail("malformed profile escaped or broke normalization");
            fake.wifiDevice.networks.values[0].nmSettings = [];
            Qt.callLater(root.checkSettingsRefresh);
        }
    function checkSettingsRefresh() {
            if (Services.NetworkService.networks[0].profiles.length !== 0)
                return fail("saved-profile rows did not refresh after nmSettings changed");
            if (fake.scanCalls.indexOf("start") === -1 || fake.scanCalls.indexOf("stop") === -1)
                return fail("scan start/stop lifecycle was not exercised");
            Services.NetworkService.setScanning(true);
            Services.NetworkService.setScanning(false);
            fake.selectedDevice = {type: DeviceType.Wired};
            fake.connectionType = "wired";
            if (Services.NetworkService.networks.length === 0)
                return fail("wired status removed the visible Wi-Fi list");
            fake.selectedDevice = fake.fixtureWifiDevice;
            fake.wifiDevice = fake.fixtureWifiDevice;
            fake.connectionType = "wifi";
            fake.loseDaemon();
            if (Services.NetworkService.availability !== "unavailable"
                    || Services.NetworkService.pendingTargetKey !== "")
                return fail("daemon loss did not clear state");
            fake.recoverDaemon();
            if (Services.NetworkService.availability !== "available")
                return fail("daemon recovery did not restore availability");
            Services.NetworkService.operationTimeoutMs = 20;
            if (!Services.NetworkService.connect(Services.NetworkService.networks[0], "xxxxxxxx"))
                return fail("timeout operation was not accepted");
            timeoutCheck.running = true;
    }
    Timer { id: timeoutCheck; interval: 100; repeat: false; onTriggered: {
        if (Services.NetworkService.pendingOperation !== ""
                || Services.NetworkService.operationError !== "Network operation timed out")
            return root.fail("network timeout did not clear pending state");
        console.log("NETWORK_DASHBOARD_TEST_PASSED"); Qt.quit();
    } }
    Timer { interval: 4000; running: true; onTriggered: root.fail("test timed out") }
}
