pragma Singleton

import Quickshell
import QtQml
import "../integrations" as Integrations

Singleton {
    id: root
    property var integration: nativeIntegration
    readonly property string availability: integration.availability
    readonly property string freshness: integration.freshness
    readonly property var lastUpdated: integration.lastUpdated
    readonly property var lastError: integration.lastError
    readonly property string operation: integration.operation
    readonly property string adapterName: integration.adapterName
    readonly property string adapterId: integration.adapterId
    readonly property var adapters: integration.adapters || []
    readonly property bool enabled: integration.enabled
    readonly property string adapterState: integration.adapterState
    readonly property var devices: integration.devices
    readonly property int knownDeviceCount: integration.knownDeviceCount
    readonly property int connectedCount: integration.connectedCount
    readonly property var connectedDevices: integration.connectedDevices
    readonly property string connectedSummary: integration.connectedSummary
    readonly property string hoverText: bluetoothHoverText()
    readonly property bool discovering: integration.discovering === true
    readonly property bool discoverable: integration.discoverable === true
    readonly property bool pairable: integration.pairable === true
    property var fallbackIntegration: nativeFallbackIntegration
    readonly property string fallbackError: fallbackIntegration.error
    property string pendingDeviceAddress: ""
    property string pendingOperation: ""
    property string operationError: ""

    function bluetoothHoverText() {
        if (!enabled || availability !== "available") return "Bluetooth disabled";
        if (connectedDevices.length === 0) return "No devices connected";
        return connectedDevices.map(device => device.batteryAvailable
            ? `${device.name}: ${device.batteryPercent}%`
            : device.name).join("\n");
    }

    function setEnabled(value) { return integration.setEnabled(value); }
    function setDiscovering(value) { return integration.setDiscovering(value); }
    function setDiscoverable(value) { return integration.setDiscoverable(value); }
    function setPairable(value) { return integration.setPairable(value); }
    function selectAdapter(id) { integration.selectedAdapterId = String(id || ""); }
    function launchFallback() { return fallbackIntegration.launch(); }
    function device(address) { return devices.find(item => item.address === address) || null; }

    function begin(address, operation) {
        if (availability !== "available") return false;
        pendingDeviceAddress = address;
        pendingOperation = operation;
        operationError = "";
        const ok = operation === "pair" ? integration.pair(address)
            : operation === "connect" ? integration.connect(address)
            : operation === "disconnect" ? integration.disconnect(address)
            : operation === "cancel" ? integration.cancelPair(address)
            : operation === "forget" ? integration.forget(address) : false;
        if (!ok) {
            pendingDeviceAddress = "";
            pendingOperation = "";
            return false;
        }
        operationTimer.restart();
        return ok;
    }

    function forget(address) { return begin(address, "forget"); }

    function reconcile() {
        const current = device(pendingDeviceAddress);
        if (!current) return;
        if (pendingOperation === "pair" && (current.paired || current.bonded)) {
            pendingOperation = "connect";
            integration.connect(current.address);
            operationTimer.restart();
        } else if (pendingOperation === "connect" && current.connected) {
            clearPending();
        } else if (pendingOperation === "disconnect" && !current.connected) {
            clearPending();
        } else if (pendingOperation === "forget" && !current.paired && !current.bonded) {
            clearPending();
        }
    }

    function clearPending() {
        operationTimer.stop();
        pendingDeviceAddress = "";
        pendingOperation = "";
    }

    function failPending() {
        const current = device(pendingDeviceAddress);
        const name = current ? current.name : pendingDeviceAddress;
        if (pendingOperation === "connect") {
            operationError = `Could not connect to ${name || "Bluetooth device"}`;
            integration.notifyConnectionFailure(name || pendingDeviceAddress);
        } else if (pendingOperation === "pair") {
            operationError = `Could not pair with ${name || "Bluetooth device"}`;
        }
        clearPending();
    }

    Integrations.BluetoothIntegration { id: nativeIntegration }
    Integrations.BluetoothFallbackIntegration { id: nativeFallbackIntegration }

    Connections {
        target: root.integration
        function onDevicesChanged() { root.reconcile(); }
        function onDiscoveringChanged() {
            if (target.discovering) discoveryTimer.restart();
            else discoveryTimer.stop();
        }
    }

    Timer {
        id: operationTimer
        interval: 10000
        repeat: false
        onTriggered: root.failPending()
    }

    Timer {
        id: discoveryTimer
        interval: 30000
        repeat: false
        onTriggered: if (root.integration.discovering) root.setDiscovering(false)
    }
}
