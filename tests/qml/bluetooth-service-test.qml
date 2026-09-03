import QtQuick
import Quickshell
import "services" as Services
import "modules/bar" as Bar
import "fixtures/qml" as Fixtures

ShellRoot {
    id: root

    Fixtures.FakeBluetoothIntegration { id: fakeBluetooth }
    Bar.BluetoothModule { id: bluetoothModule }

    function fail(message) {
        console.error(`BLUETOOTH_SERVICE_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function runChecks() {
        if (!Services.ConfigService.hasLoaded) {
            retryTimer.restart();
            return;
        }
        Services.BluetoothService.integration = fakeBluetooth;

        if (bluetoothModule.icon !== "bluetooth")
            return fail("powered adapter did not use the bluetooth icon");
        fakeBluetooth.enabled = false;
        fakeBluetooth.adapterState = "disabled";
        if (bluetoothModule.icon !== "bluetooth_disabled")
            return fail("disabled adapter did not use the disabled icon");
        if (!bluetoothModule.shouldShow)
            return fail(`disabled adapter was hidden: availability=${Services.BluetoothService.availability}`);
        if (bluetoothModule.iconColor.toString() !== Services.ThemeService.theme.tokens.error.toString())
            return fail(`disabled adapter color was ${bluetoothModule.iconColor}`);

        fakeBluetooth.enabled = true;
        fakeBluetooth.adapterState = "enabled";
        fakeBluetooth.devices = [{
            address: "00:11:22:33:44:55", name: "Fixture Mouse", deviceName: "Mouse",
            icon: "input-mouse", connected: true, paired: true, bonded: true,
            trusted: true, blocked: false, pairing: false, state: "connected",
            batteryAvailable: true, batteryPercent: 73
        }];
        if (Services.BluetoothService.connectedCount !== 1
                || Services.BluetoothService.connectedSummary !== "Fixture Mouse"
                || Services.BluetoothService.connectedDevices[0].batteryPercent !== 73)
            return fail("connected device summary was not normalized");
        if (bluetoothModule.icon !== "bluetooth_connected")
            return fail("connected device did not use the connected icon");
        if (bluetoothModule.iconColor.toString() !== Services.ThemeService.theme.tokens.success.toString())
            return fail("connected device did not use the success color");
        if (bluetoothModule.hoverText !== "Fixture Mouse: 73%")
            return fail(`single-device Bluetooth hover was '${bluetoothModule.hoverText}'`);
        const pairingDevice = {
            address: "11:22:33:44:55:66", name: "Pairing Mouse", connected: false,
            paired: false, bonded: false, pairing: true, state: "connecting",
            batteryAvailable: false, batteryPercent: -1
        };
        fakeBluetooth.devices = [pairingDevice];
        if (!Services.BluetoothService.begin(pairingDevice.address, "pair"))
            return fail("pair did not enter the pending state");
        pairingDevice.pairing = false;
        pairingDevice.connected = true;
        pairingDevice.state = "connected";
        Services.BluetoothService.reconcile();
        if (Services.BluetoothService.pendingOperation !== ""
                || Services.BluetoothService.operationError !== "Could not pair with Pairing Mouse")
            return fail("transient pairing connection did not fail cleanly");
        fakeBluetooth.devices = [{
            address: "00:11:22:33:44:55", name: "Fixture Mouse", deviceName: "Mouse",
            icon: "input-mouse", connected: true, paired: true, bonded: true,
            trusted: true, blocked: false, pairing: false, state: "connected",
            batteryAvailable: true, batteryPercent: 73
        }];
        if (!Services.BluetoothService.forget("00:11:22:33:44:55")
                || Services.BluetoothService.pendingOperation !== "forget")
            return fail("forget did not enter the pending state");
        fakeBluetooth.devices = [];
        Qt.callLater(checkForgetCleared);
    }

    function checkForgetCleared() {
        if (Services.BluetoothService.pendingOperation !== ""
                || Services.BluetoothService.pendingDeviceAddress !== "")
            return fail("forget remained pending after the device disappeared");
        fakeBluetooth.devices = [{
            address: "00:11:22:33:44:55", name: "Fixture Mouse", deviceName: "Mouse",
            icon: "input-mouse", connected: true, paired: true, bonded: true,
            trusted: true, blocked: false, pairing: false, state: "connected",
            batteryAvailable: true, batteryPercent: 73
        }, {
            address: "AA:BB:CC:DD:EE:FF", name: "Fixture Headphones", deviceName: "Headphones",
            icon: "audio-headphones", connected: true, paired: true, bonded: true,
            trusted: true, blocked: false, pairing: false, state: "connected",
            batteryAvailable: false, batteryPercent: -1
        }];
        if (Services.BluetoothService.connectedCount !== 2
                || Services.BluetoothService.connectedSummary !== "Fixture Mouse +1")
            return fail("multiple connected devices were not summarized deterministically");
        if (bluetoothModule.hoverText !== "Fixture Mouse: 73%\nFixture Headphones")
            return fail(`multiple-device Bluetooth hover was '${bluetoothModule.hoverText}'`);

        fakeBluetooth.operation = "pending";
        if (!bluetoothModule.warning)
            return fail("pending Bluetooth operation did not show warning state");
        fakeBluetooth.operation = "idle";
        fakeBluetooth.availability = "unavailable";
        fakeBluetooth.freshness = "unknown";
        fakeBluetooth.enabled = false;
        fakeBluetooth.devices = [];
        if (Services.BluetoothService.availability !== "unavailable"
                || !bluetoothModule.shouldShow
                || bluetoothModule.icon !== "bluetooth_disabled"
                || bluetoothModule.iconColor.toString() !== Services.ThemeService.theme.tokens.error.toString())
            return fail("controller loss did not retain the disabled error-state summary");

        console.log("BLUETOOTH_SERVICE_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        id: retryTimer
        interval: 50
        repeat: false
        onTriggered: root.runChecks()
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail("test timed out")
    }

    Component.onCompleted: Qt.callLater(runChecks)
}
