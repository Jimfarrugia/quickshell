import QtQuick
import Quickshell.Services.UPower

QtObject {
    id: root

    property var device: UPower.displayDevice
    readonly property bool available: device.ready
        && device.isPresent
        && device.isLaptopBattery
    readonly property int percentage: available
        ? Math.max(0, Math.min(100, Math.round(device.percentage * 100)))
        : 0
}
