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
    property bool discovering: false
    property bool discoverable: false
    property bool pairable: false
    property var adapters: [{ id: "hci0", name: "Fixture Bluetooth" }]
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

    function setEnabled(value) { enabled = value === true; return true; }
    function setDiscovering(value) { discovering = value === true; return true; }
    function setDiscoverable(value) { discoverable = value === true; return true; }
    function setPairable(value) { pairable = value === true; return true; }
    function connect(address) { operation = "pending"; return true; }
    function disconnect(address) { operation = "pending"; return true; }
    function pair(address) { operation = "pending"; return true; }
    function cancelPair(address) { operation = "idle"; return true; }
    function forget(address) { operation = "pending"; return true; }
    function notifyConnectionFailure(name) {}
}
