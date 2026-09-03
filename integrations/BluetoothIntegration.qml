import QtQuick
import QtQml
import Quickshell.Io
import Quickshell.Bluetooth

QtObject {
    id: root

    property var bluetoothManager: Bluetooth
    property string selectedAdapterId: ""
    readonly property var adapter: selectedAdapter()
    readonly property var adapters: normalizedAdapters()
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
    readonly property bool discovering: adapter ? adapter.discovering === true : false
    readonly property bool discoverable: adapter ? adapter.discoverable === true : false
    readonly property bool pairable: adapter ? adapter.pairable === true : false
    readonly property var devices: normalizedDevices()
    readonly property int knownDeviceCount: devices.length
    readonly property int connectedCount: devices.filter(device => device.connected).length
    readonly property var connectedDevices: devices.filter(device => device.connected)
    readonly property string connectedSummary: summarizeConnectedDevices()

    function selectedAdapter() {
        const all = bluetoothManager.adapters ? bluetoothManager.adapters.values : [];
        if (selectedAdapterId.length > 0) {
            const selected = all.find(item => item.adapterId === selectedAdapterId);
            if (selected) return selected;
        }
        if (bluetoothManager.defaultAdapter) return bluetoothManager.defaultAdapter;
        return all.length > 0 ? all[0] : null;
    }

    function normalizedAdapters() {
        const source = bluetoothManager.adapters ? bluetoothManager.adapters.values : [];
        return source.map(item => ({ id: item.adapterId, name: item.name || item.adapterId }));
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

    function setEnabled(value) {
        if (!adapter) return false;
        adapter.enabled = value === true;
        return true;
    }

    function setDiscovering(value) {
        if (!adapter) return false;
        adapter.discovering = value === true;
        return true;
    }

    function setDiscoverable(value) {
        if (!adapter) return false;
        adapter.discoverable = value === true;
        return true;
    }

    function setPairable(value) {
        if (!adapter) return false;
        adapter.pairable = value === true;
        return true;
    }

    function nativeDeviceFor(address) {
        const source = adapter && adapter.devices ? adapter.devices.values : [];
        return source.find(device => device.address === address) || null;
    }

    function connect(address) {
        const device = nativeDeviceFor(address);
        if (!device) return false;
        device.connect();
        return true;
    }

    function disconnect(address) {
        const device = nativeDeviceFor(address);
        if (!device) return false;
        device.disconnect();
        return true;
    }

    function pair(address) {
        const device = nativeDeviceFor(address);
        if (!device) return false;
        device.pair();
        return true;
    }

    function cancelPair(address) {
        const device = nativeDeviceFor(address);
        if (!device) return false;
        device.cancelPair();
        return true;
    }

    function forget(address) {
        const device = nativeDeviceFor(address);
        if (!device) return false;
        device.forget();
        return true;
    }

    function notifyConnectionFailure(name) {
        notificationProcess.command = ["notify-send", "Bluetooth connection failed",
            `Could not connect to ${name || "Bluetooth device"}`, "-u", "normal"];
        notificationProcess.running = true;
    }

    property Process notificationProcess: Process {}

    onAdapterChanged: lastUpdated = adapter ? new Date() : null
    onEnabledChanged: lastUpdated = new Date()
    onDevicesChanged: lastUpdated = new Date()
}
