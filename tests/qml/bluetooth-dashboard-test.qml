import QtQuick
import Quickshell
import "services" as Services
import "fixtures/qml" as Fixtures
import "modules/bluetooth" as BluetoothModules

ShellRoot {
    id: root
    Fixtures.FakeBluetoothIntegration { id: fakeBluetooth }
    // Loaded like the dashboard shell loads content, so teardown can be exercised.
    Loader {
        id: dashboardLoader
        sourceComponent: Component { BluetoothModules.BluetoothDashboard { width: 600 } }
    }

    function fail(message) {
        console.error(`BLUETOOTH_DASHBOARD_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function check() {
        Services.BluetoothService.integration = fakeBluetooth;
        fakeBluetooth.devices = [{
            address: "00:11:22:33:44:55", name: "Known Mouse", connected: true,
            paired: true, bonded: true, pairing: false, state: "connected",
            batteryAvailable: true, batteryPercent: 73
        }, {
            address: "AA:BB:CC:DD:EE:FF", name: "Nearby Headphones", connected: false,
            paired: false, bonded: false, pairing: false, state: "disconnected",
            batteryAvailable: false, batteryPercent: -1
        }];
        const dashboard = dashboardLoader.item;
        if (Services.BluetoothService.devices.length !== 2
                || !dashboard || dashboard.children.length === 0)
            return fail("dashboard did not expose Bluetooth devices");
        if (!Services.BluetoothService.devices[0].paired
                || Services.BluetoothService.devices[1].paired)
            return fail("known/discovered state was not preserved");
        if (!dashboard.headerActions || dashboard.fallbackTooltip !== "Open Blueman")
            return fail("dashboard did not declare its header actions and fallback tool");

        Services.BluetoothService.setDiscovering(true);
        Services.BluetoothService.operationError = "stale failure";
        if (!fakeBluetooth.discovering) return fail("fake discovery did not start");
        dashboardLoader.active = false;
        if (fakeBluetooth.discovering)
            return fail("closing the dashboard did not stop discovery");
        if (Services.BluetoothService.operationError !== "")
            return fail("closing the dashboard did not clear the operation error");
        console.log("BLUETOOTH_DASHBOARD_TEST_PASSED");
        Qt.quit();
    }

    Timer { interval: 100; running: true; onTriggered: root.check() }
    Timer { interval: 3000; running: true; onTriggered: root.fail("test timed out") }
}
