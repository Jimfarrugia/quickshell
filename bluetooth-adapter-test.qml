import QtQuick
import Quickshell
import "services" as Services

ShellRoot {
    id: root

    function fail(message) {
        console.error(`BLUETOOTH_ADAPTER_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function check() {
        if (!Services.ConfigService.hasLoaded
                || Services.BluetoothService.availability !== "available") {
            retryTimer.restart();
            return;
        }
        if (Services.BluetoothService.adapterId.length === 0
                || Services.BluetoothService.adapterName.length === 0)
            return fail("live adapter identity was not normalized");
        if (Services.BluetoothService.connectedCount < 0
                || Services.BluetoothService.connectedCount > Services.BluetoothService.knownDeviceCount)
            return fail("live device counts were inconsistent");
        console.log("BLUETOOTH_ADAPTER_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        id: retryTimer
        interval: 50
        repeat: false
        onTriggered: root.check()
    }

    Timer {
        interval: 4500
        running: true
        onTriggered: root.fail(`timed out with availability=${Services.BluetoothService.availability}`)
    }

    Component.onCompleted: Qt.callLater(check)
}
