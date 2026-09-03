import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "integrations" as Integrations

ShellRoot {
    id: root

    QtObject {
        id: fakeDevice
        property string address: "00:11:22:33:44:55"
        property string name: "Fixture Mouse"
        property string deviceName: "Mouse"
        property string icon: "input-mouse"
        property bool connected: false
        property bool paired: true
        property bool bonded: true
        property bool trusted: true
        property bool blocked: false
        property bool pairing: false
        property int state: BluetoothDeviceState.Disconnected
        property bool batteryAvailable: true
        property real battery: 0.731
        property bool forgot: false
        function forget() {
            forgot = true;
            paired = false;
            bonded = false;
        }
    }

    QtObject {
        id: fakeDevices
        property var values: [fakeDevice]
    }

    QtObject {
        id: fakeAdapter
        property string name: "Fixture Bluetooth"
        property string adapterId: "hci0"
        property bool enabled: true
        property int state: BluetoothAdapterState.Enabled
        property var devices: fakeDevices
    }

    QtObject {
        id: fakeManager
        property var defaultAdapter: fakeAdapter
        property var adapters: fakeAdapters
    }

    QtObject {
        id: fakeAdapters
        property var values: [fakeAdapter]
    }

    Integrations.BluetoothIntegration {
        id: integration
        bluetoothManager: fakeManager
    }

    function fail(message) {
        console.error(`BLUETOOTH_INTEGRATION_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function checkInitial() {
        if (integration.knownDeviceCount !== 1
                || integration.devices[0].name !== "Fixture Mouse"
                || integration.devices[0].batteryPercent !== 73)
            return fail("real integration normalizer did not map fixture device fields");
        integration.forget(fakeDevice.address);
        if (!fakeDevice.forgot)
            return fail("forget did not invoke the native device operation");
        fakeDevice.connected = true;
        fakeDevice.state = BluetoothDeviceState.Connected;
        fakeDevice.battery = 0.42;
        Qt.callLater(checkConnected);
    }

    function checkConnected() {
        if (integration.connectedCount !== 1
                || integration.connectedSummary !== "Fixture Mouse"
                || integration.devices[0].batteryPercent !== 42)
            return fail("in-place device signals did not refresh normalized state");
        fakeDevice.connected = false;
        fakeDevice.state = BluetoothDeviceState.Connecting;
        Qt.callLater(checkPending);
    }

    function checkPending() {
        if (integration.operation !== "pending")
            return fail("connecting device did not expose a pending operation");
        fakeDevice.state = BluetoothDeviceState.Disconnected;
        fakeAdapter.state = BluetoothAdapterState.Enabling;
        Qt.callLater(checkAdapterPending);
    }

    function checkAdapterPending() {
        if (integration.operation !== "pending")
            return fail("transitioning adapter did not expose a pending operation");
        fakeManager.defaultAdapter = null;
        fakeAdapters.values = [];
        Qt.callLater(checkLoss);
    }

    function checkLoss() {
        if (integration.availability !== "unavailable"
                || integration.knownDeviceCount !== 0
                || integration.connectedCount !== 0)
            return fail("controller loss retained stale normalized devices");
        console.log("BLUETOOTH_INTEGRATION_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail("test timed out")
    }

    Component.onCompleted: Qt.callLater(checkInitial)
}
