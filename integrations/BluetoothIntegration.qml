import QtQuick
import Quickshell.Bluetooth

QtObject {
    id: root

    property var bluetoothManager: Bluetooth
    readonly property var adapter: selectedAdapter()
    readonly property string availability: adapter ? "available" : "unavailable"
    readonly property string freshness: adapter ? "current" : "unknown"
    property var lastUpdated: adapter ? new Date() : null
    readonly property var lastError: null
    readonly property string operation: adapterOperation()
    readonly property string adapterName: adapter ? adapter.name : ""
    readonly property string adapterId: adapter ? adapter.adapterId : ""
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property string adapterState: adapter
        ? BluetoothAdapterState.toString(adapter.state).toLowerCase() : "unavailable"
    readonly property var devices: normalizedDevices()
    readonly property int knownDeviceCount: devices.length
    readonly property int connectedCount: devices.filter(device => device.connected).length
    readonly property var connectedDevices: devices.filter(device => device.connected)
    readonly property string connectedSummary: summarizeConnectedDevices()

    function selectedAdapter() {
        if (bluetoothManager.defaultAdapter) return bluetoothManager.defaultAdapter;
        const adapters = bluetoothManager.adapters ? bluetoothManager.adapters.values : [];
        return adapters.length > 0 ? adapters[0] : null;
    }

    function normalizedDevices() {
        const source = adapter && adapter.devices ? adapter.devices.values : [];
        return source.map(device => ({
            address: device.address,
            name: device.name || device.deviceName || device.address,
            deviceName: device.deviceName || "",
            icon: device.icon || "",
            connected: device.connected,
            paired: device.paired,
            bonded: device.bonded,
            trusted: device.trusted,
            blocked: device.blocked,
            pairing: device.pairing,
            state: BluetoothDeviceState.toString(device.state).toLowerCase(),
            batteryAvailable: device.batteryAvailable,
            batteryPercent: device.batteryAvailable ? Math.round(device.battery * 100) : -1
        }));
    }

    function summarizeConnectedDevices() {
        const connected = devices.filter(device => device.connected);
        if (connected.length === 0) return "";
        return connected.length === 1 ? connected[0].name
            : `${connected[0].name} +${connected.length - 1}`;
    }

    function adapterOperation() {
        if (!adapter) return "idle";
        if (adapter.state === BluetoothAdapterState.Enabling
                || adapter.state === BluetoothAdapterState.Disabling)
            return "pending";
        return devices.some(device => device.pairing
            || device.state === "connecting" || device.state === "disconnecting")
                ? "pending" : "idle";
    }

    onAdapterChanged: lastUpdated = adapter ? new Date() : null
    onEnabledChanged: lastUpdated = new Date()
    onDevicesChanged: lastUpdated = new Date()
}
