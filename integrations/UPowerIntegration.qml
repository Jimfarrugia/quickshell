import QtQuick
import Quickshell.Services.UPower

QtObject {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: device.ready && device.isPresent && device.isLaptopBattery
    readonly property string availability: !device.ready ? "unknown" : (present ? "available" : "unavailable")
    readonly property string freshness: availability === "available" ? "current" : "unknown"
    readonly property var lastError: null
    readonly property string operation: "idle"
    property var lastUpdated: new Date()
    readonly property int percentage: present ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: present && device.state === UPowerDeviceState.Charging
    readonly property string iconName: present ? device.iconName : ""

    onPercentageChanged: lastUpdated = new Date()
    onChargingChanged: lastUpdated = new Date()
}
