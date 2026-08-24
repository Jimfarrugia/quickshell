import QtQuick
import Quickshell.Networking

QtObject {
    id: root

    readonly property string availability: Networking.backend === NetworkBackendType.None ? "unavailable" : "available"
    readonly property string freshness: availability === "available" ? "current" : "unknown"
    readonly property var lastError: null
    readonly property string operation: "idle"
    property var lastUpdated: new Date()
    readonly property var wifiDevice: connectedDevice(DeviceType.Wifi)
    readonly property var wifiNetwork: connectedNetwork(wifiDevice)
    readonly property var wiredDevice: wifiDevice ? null : connectedDevice(DeviceType.Wired)
    readonly property string connectionType: wifiNetwork ? "wifi" : (wiredDevice ? "wired" : "disconnected")
    readonly property string ssid: wifiNetwork ? wifiNetwork.name : ""
    readonly property int signalStrength: wifiNetwork ? Math.round(wifiNetwork.signalStrength * 100) : 0
    readonly property string wiredInterface: wiredDevice ? wiredDevice.name : ""
    readonly property string interfaceName: wifiDevice ? wifiDevice.name : wiredInterface
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

    function connectedDevice(type) {
        const devices = Networking.devices.values;
        for (let index = 0; index < devices.length; index++) {
            if (devices[index].type === type && devices[index].connected) return devices[index];
        }
        return null;
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
}
