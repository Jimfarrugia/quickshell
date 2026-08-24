pragma Singleton

import Quickshell
import "../integrations" as Integrations

Singleton {
    property var integration: nativeIntegration
    readonly property string availability: integration.availability
    readonly property string freshness: integration.freshness
    readonly property var lastUpdated: integration.lastUpdated
    readonly property var lastError: integration.lastError
    readonly property string operation: integration.operation
    readonly property string adapterName: integration.adapterName
    readonly property string adapterId: integration.adapterId
    readonly property bool enabled: integration.enabled
    readonly property string adapterState: integration.adapterState
    readonly property var devices: integration.devices
    readonly property int knownDeviceCount: integration.knownDeviceCount
    readonly property int connectedCount: integration.connectedCount
    readonly property var connectedDevices: integration.connectedDevices
    readonly property string connectedSummary: integration.connectedSummary
    readonly property string hoverText: bluetoothHoverText()

    function bluetoothHoverText() {
        if (!enabled || availability !== "available") return "Bluetooth disabled";
        if (connectedDevices.length === 0) return "No devices connected";
        return connectedDevices.map(device => device.batteryAvailable
            ? `${device.name}: ${device.batteryPercent}%`
            : device.name).join("\n");
    }

    Integrations.BluetoothIntegration { id: nativeIntegration }
}
