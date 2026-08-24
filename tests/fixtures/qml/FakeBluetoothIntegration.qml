import QtQuick

QtObject {
    property string availability: "available"
    property string freshness: "current"
    property var lastUpdated: new Date()
    property var lastError: null
    property string operation: "idle"
    property string adapterName: "Fixture Bluetooth"
    property string adapterId: "hci0"
    property bool enabled: true
    property string adapterState: "enabled"
    property var devices: []
    readonly property int knownDeviceCount: devices.length
    readonly property int connectedCount: devices.filter(device => device.connected).length
    readonly property var connectedDevices: devices.filter(device => device.connected)
    readonly property string connectedSummary: summarizeConnectedDevices()

    function summarizeConnectedDevices() {
        const connected = devices.filter(device => device.connected);
        if (connected.length === 0) return "";
        return connected.length === 1 ? connected[0].name
            : `${connected[0].name} +${connected.length - 1}`;
    }
}
