import QtQuick
import Quickshell.Io
import Quickshell.Networking

QtObject {
    id: root

    readonly property string availability: Networking.backend === NetworkBackendType.None
        || (nativeDeviceSeen && Networking.devices.values.length === 0) ? "unavailable" : "available"
    property bool nativeDeviceSeen: false
    property int nativeIdentitySerial: 0
    property var nativeIdentities: []
    readonly property string freshness: availability === "available" ? "current" : "unknown"
    readonly property var lastError: availability === "unavailable" ? {
        code: "NETWORKMANAGER_UNAVAILABLE", boundary: "network", summary: "NetworkManager is unavailable",
        detail: "The native NetworkManager device model is empty", retryable: true
    } : null
    readonly property string operation: "idle"
    property var lastUpdated: new Date()
    // This is the single device projection used by status, scanning, and the
    // visible-network list.  Never show networks from an inactive adapter.
    readonly property var selectedDevice: chooseDevice()
    readonly property bool selectedDeviceConnected: selectedDevice ? selectedDevice.connected : false
    readonly property string selectedDeviceLabel: selectedDevice
        ? String(selectedDevice.name || selectedDevice.address || "unknown") : "No network device"
    readonly property var wifiDevice: selectedDevice && selectedDevice.type === DeviceType.Wifi ? selectedDevice : null
    readonly property var activeWifiDevice: selectedDevice && selectedDevice.type === DeviceType.Wifi
        && selectedDevice.connected ? selectedDevice : null
    readonly property var wifiNetwork: connectedNetwork(activeWifiDevice)
    readonly property var wiredDevice: selectedDevice && selectedDevice.type === DeviceType.Wired
        && selectedDevice.connected ? selectedDevice : null
    readonly property string connectionType: wifiNetwork ? "wifi" : (wiredDevice ? "wired" : "disconnected")
    readonly property string ssid: wifiNetwork ? wifiNetwork.name : ""
    readonly property int signalStrength: wifiNetwork ? Math.round(wifiNetwork.signalStrength * 100) : 0
    readonly property string wiredInterface: wiredDevice ? wiredDevice.name : ""
    readonly property string interfaceName: wifiNetwork && activeWifiDevice ? activeWifiDevice.name : wiredInterface
    readonly property string connectivity: {
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full: return "full";
        case NetworkConnectivity.Limited: return "limited";
        case NetworkConnectivity.Portal: return "portal";
        case NetworkConnectivity.None: return "none";
        default: return "unknown";
        }
    }
    readonly property string summary: {
        switch (connectivity) {
        case "full": return "Online";
        case "limited": return "Limited";
        case "portal": return "Sign in";
        case "none": return "Offline";
        default: return "Network";
        }
    }
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property bool scanning: wifiDevice ? wifiDevice.scannerEnabled : false

    function connectedDevice(type) {
        const devices = Networking.devices.values.slice().sort((a, b) =>
            String(a.name || a.address).localeCompare(String(b.name || b.address)));
        for (let index = 0; index < devices.length; index++) {
            if (devices[index].type === type && devices[index].connected) return devices[index];
        }
        return null;
    }

    function chooseDevice() {
        return selectDeviceFrom(Networking.devices.values);
    }

    function selectDeviceFrom(sourceDevices) {
        const devices = sourceDevices.slice().filter(device =>
            device.type === DeviceType.Wifi || device.type === DeviceType.Wired)
            .sort((a, b) => String(a.name || a.address).localeCompare(String(b.name || b.address)));
        const wifi = devices.find(device => device.type === DeviceType.Wifi && device.connected);
        if (wifi) return wifi;
        const wired = devices.find(device => device.type === DeviceType.Wired && device.connected);
        if (wired) return wired;
        return devices.length > 0 ? devices[0] : null;
    }

    function updateNativeAvailability() {
        if (Networking.backend === NetworkBackendType.None) {
            nativeDeviceSeen = false;
            return;
        }
        if (Networking.devices.values.length > 0) nativeDeviceSeen = true;
    }

    function nativeIdentity(object) {
        if (!object) return "unknown";
        for (let index = 0; index < nativeIdentities.length; index++)
            if (nativeIdentities[index].object === object) return nativeIdentities[index].id;
        const entry = {object: object, id: `native-${++nativeIdentitySerial}`};
        nativeIdentities = nativeIdentities.concat([entry]);
        return entry.id;
    }

    function deviceOfType(type) {
        const devices = Networking.devices.values.slice().sort((a, b) =>
            String(a.name || a.address).localeCompare(String(b.name || b.address)));
        return devices.find(device => device.type === type) || null;
    }

    function setWifiEnabled(value) {
        if (availability !== "available" || !wifiHardwareEnabled) return false;
        Networking.wifiEnabled = value === true;
        return true;
    }

    function setScanning(value) {
        if (!wifiDevice || availability !== "available") return false;
        wifiDevice.scannerEnabled = value === true;
        return true;
    }

    function connect(network, settings) {
        if (!network) return false;
        if (settings) network.connectWithSettings(settings);
        else network.connect();
        return true;
    }

    function connectWithPsk(network, psk) {
        if (!network || typeof network.connectWithPsk !== "function"
                || typeof psk !== "string" || psk.length < 8 || psk.length > 63
                || psk.trim().length === 0) return false;
        network.connectWithPsk(psk);
        return true;
    }

    function disconnect(network) { if (!network) return false; network.disconnect(); return true; }
    function forget(network, settings) {
        if (!network) return false;
        if (settings && typeof settings.forget === "function") settings.forget();
        else network.forget();
        return true;
    }

    function connectedNetwork(device) {
        if (!device) return null;
        const networks = device.networks.values;
        for (let index = 0; index < networks.length; index++) {
            if (networks[index].connected) return networks[index];
        }
        return null;
    }

    onConnectivityChanged: lastUpdated = new Date()

    property Connections deviceConnections: Connections {
        target: Networking.devices
        function onValuesChanged() { root.updateNativeAvailability(); root.lastUpdated = new Date(); }
    }

    Component.onCompleted: updateNativeAvailability()
}
