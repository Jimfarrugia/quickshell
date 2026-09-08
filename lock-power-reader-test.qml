import QtQuick
import Quickshell
import "lock" as Lock

ShellRoot {
    id: root

    QtObject {
        id: availableDevice
        property bool ready: true
        property bool isPresent: true
        property bool isLaptopBattery: true
        property real percentage: 0.73
    }

    QtObject {
        id: unavailableDevice
        property bool ready: true
        property bool isPresent: false
        property bool isLaptopBattery: false
        property real percentage: 0
    }

    QtObject {
        id: notReadyDevice
        property bool ready: false
        property bool isPresent: true
        property bool isLaptopBattery: true
        property real percentage: 0.5
    }

    QtObject {
        id: overfullDevice
        property bool ready: true
        property bool isPresent: true
        property bool isLaptopBattery: true
        property real percentage: 1.2
    }

    Lock.LockPowerReader {
        id: availableReader
        device: availableDevice
    }

    Lock.LockPowerReader {
        id: unavailableReader
        device: unavailableDevice
    }

    Lock.LockPowerReader {
        id: notReadyReader
        device: notReadyDevice
    }

    Lock.LockPowerReader {
        id: overfullReader
        device: overfullDevice
    }

    Timer {
        interval: 0
        running: true
        onTriggered: {
            if (!availableReader.available || availableReader.percentage !== 73
                    || unavailableReader.available || unavailableReader.percentage !== 0
                    || notReadyReader.available || notReadyReader.percentage !== 0
                    || overfullReader.percentage !== 100) {
                console.error("LOCK_POWER_READER_TEST_FAILED");
                Qt.quit();
                return;
            }
            console.log("LOCK_POWER_READER_TEST_PASSED");
            Qt.quit();
        }
    }
}
