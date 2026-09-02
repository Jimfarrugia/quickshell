pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking
import QtQml.Models
import "../integrations" as Integrations

Singleton {
    id: root
    property var integration: nativeIntegration
    property var addressIntegration: nativeAddressIntegration
    property var fallbackIntegration: nativeFallbackIntegration
    readonly property string availability: integration.availability !== "available"
        ? integration.availability
        : (connectionType === "wired" && addressIntegration.availability === "degraded" ? "degraded" : "available")
    readonly property string freshness: connectionType === "wired" && addressIntegration.freshness !== "unknown"
        ? addressIntegration.freshness : integration.freshness
    readonly property var lastUpdated: connectionType === "wired" && addressIntegration.lastUpdated
        ? addressIntegration.lastUpdated : integration.lastUpdated
    readonly property var lastError: connectionType === "wired" && addressIntegration.lastError
        ? addressIntegration.lastError : integration.lastError
    readonly property string operation: connectionType === "wired" ? addressIntegration.operation : integration.operation
    readonly property string connectivity: integration.connectivity
    readonly property string summary: integration.summary
    readonly property string connectionType: integration.connectionType
    readonly property string ssid: integration.ssid
    readonly property int signalStrength: integration.signalStrength
    readonly property string wiredInterface: integration.wiredInterface
    readonly property string interfaceName: integration.interfaceName
    readonly property bool wifiEnabled: integration.wifiEnabled === true
    readonly property bool wifiHardwareEnabled: integration.wifiHardwareEnabled !== false
    readonly property bool scanning: integration.scanning === true
    readonly property var wifiDevice: integration.wifiDevice || null
    readonly property var selectedDevice: integration.selectedDevice || null
    readonly property bool selectedDeviceConnected: integration.selectedDeviceConnected === true
    readonly property string selectedDeviceLabel: integration.selectedDeviceLabel || "No network device"
    property var networks: []
    readonly property bool wifiTogglePending: pendingWifiEnabled !== null
    readonly property string operationError: operationErrorText
    readonly property string fallbackError: fallbackIntegration.error
    property var pendingWifiEnabled: null
    property string pendingTargetKey: ""
    property string pendingOperation: ""
    property string operationErrorText: ""
    property string queuedTargetKey: ""
    property string queuedOperation: ""
    property string queuedPsk: ""
    property int operationSerial: 0
    property int activeOperationSerial: 0
    property int operationTimeoutMs: 10000
    property int nativeIdentitySerial: 0
    property var nativeIdentityObjects: []
    readonly property string ipv4Address: addressIntegration.ipv4Address
    readonly property string hoverText: `Type: ${connectionTypeText()}\nInterface: ${interfaceName || "unavailable"}\nSSID: ${ssid || "n/a"}\nIP: ${ipv4Address || "unavailable"}\nConnectivity: ${statusText(connectivity)}`

    function connectionTypeText() {
        if (connectionType === "wifi") return "Wi-Fi";
        if (connectionType === "wired") return "Wired";
        return "Disconnected";
    }

    function statusText(status) {
        return status.length > 0 ? status[0].toUpperCase() + status.slice(1) : "Unknown";
    }

    function refreshAddress() {
        if (interfaceName.length > 0) addressIntegration.refresh(interfaceName);
        else addressIntegration.clear();
    }

    function normalizedNetworks() {
        const device = wifiDevice;
        if (!device || !device.networks) return [];
        const result = [];
        const unprofiledCounts = {};
        device.networks.values.forEach(network => {
            const settings = network.nmSettings || [];
            if (settings.length === 0) {
                const base = `${network.name}:${deviceIdentity(network.device || device)}:${network.security}:${network.signalStrength}:${network.state}`;
                const occurrence = unprofiledCounts[base] || 0;
                unprofiledCounts[base] = occurrence + 1;
                result.push({network: network, settings: null, profiles: [],
                    key: `${network.name}:device:${deviceIdentity(network.device || device)}:native:${nativeIdentity(network)}:${occurrence}`,
                    name: network.name});
            } else {
                const profiles = settings.map(setting => {
                let profile = {};
                try { profile = setting.read() || {}; } catch (error) { profile = {}; }
                const connection = profile.connection || {};
                return {settings: setting,
                    key: `${network.name}:device:${deviceIdentity(network.device || device)}:profile:${connection.uuid || connection.id || nativeIdentity(setting)}`,
                    name: connection.id || network.name};
                });
                result.push({network: network, settings: profiles[0].settings, profiles: profiles,
                    key: `${network.name}:device:${deviceIdentity(network.device || device)}:native:${nativeIdentity(network)}:group`,
                    name: network.name});
            }
        });
        return result;
    }

    function nativeIdentity(object) {
        if (!object) return "unknown";
        for (let index = 0; index < nativeIdentityObjects.length; index++)
            if (nativeIdentityObjects[index].object === object) return nativeIdentityObjects[index].id;
        const entry = {object: object, id: `native-${++nativeIdentitySerial}`};
        nativeIdentityObjects = nativeIdentityObjects.concat([entry]);
        return entry.id;
    }
    function deviceIdentity(device) {
        return device ? String(device.address || device.name || nativeIdentity(device)) : "unknown";
    }
    function isSupportedSecurity(network) {
        if (!network) return false;
        return network.security === WifiSecurityType.Open || network.security === WifiSecurityType.WpaPsk
            || network.security === WifiSecurityType.Wpa2Psk || network.security === WifiSecurityType.Sae;
    }
    function needsFallback(row) { return !!row && !isSupportedSecurity(row.network); }
    function openNetworkFallback(row) {
        if (!row || !needsFallback(row)) return false;
        return openFallback();
    }
    function operationBusy() { return pendingOperation.length > 0 || pendingWifiEnabled !== null; }
    function queueMutation(row, operation, psk) {
        queuedTargetKey = row.key; queuedOperation = operation; queuedPsk = psk || "";
        return true;
    }
    function startNetworkOperation(row, operation, psk) {
        pendingWifiEnabled = null;
        pendingTargetKey = row.key; pendingOperation = operation; activeOperationSerial = ++operationSerial;
        let accepted = false;
        if (operation === "connect") accepted = psk ? integration.connectWithPsk(row.network, String(psk))
            : integration.connect(row.network, row.settings);
        else if (operation === "disconnect") accepted = integration.disconnect(row.network);
        else accepted = integration.forget(row.network, row.settings);
        if (!accepted) { finishOperation("Network operation was rejected"); return false; }
        networkOperationTimer.restart();
        return true;
    }
    function startQueuedOperation() {
        if (!queuedTargetKey) return;
        const row = networkFor(queuedTargetKey), operation = queuedOperation, psk = queuedPsk;
        queuedTargetKey = ""; queuedOperation = ""; queuedPsk = "";
        if (row) startNetworkOperation(row, operation, psk);
    }

    function setWifiEnabled(value) {
        if (availability === "unavailable" || typeof integration.setWifiEnabled !== "function") return false;
        if (pendingOperation.length > 0 && pendingWifiEnabled === null) return false;
        pendingWifiEnabled = value === true;
        pendingTargetKey = "";
        pendingOperation = "wifi";
        operationErrorText = "";
        if (!integration.setWifiEnabled(pendingWifiEnabled)) {
            pendingWifiEnabled = null;
            pendingOperation = "";
            return false;
        }
        if (integration.wifiEnabled === pendingWifiEnabled
                && (!pendingWifiEnabled || connectionType === "wifi")) {
            finishOperation("");
            return true;
        }
        networkOperationTimer.restart();
        return true;
    }

    function setScanning(value) {
        return typeof integration.setScanning === "function" && integration.setScanning(value);
    }
    function refreshScan() {
        if (!scanning) setScanning(true);
        else { setScanning(false); Qt.callLater(() => setScanning(true)); }
    }
    function openFallback() { return fallbackIntegration.launch(); }
    function networkFor(key) {
        for (const row of networks) {
            if (row.key === key) return row;
            const profile = (row.profiles || []).find(candidate => candidate.key === key);
            if (profile) return {network: row.network, settings: profile.settings, profiles: row.profiles,
                key: profile.key, name: profile.name};
        }
        return null;
    }
    function refreshNetworks() { networks = normalizedNetworks(); }
    function connect(row, psk) {
        if (!row || availability !== "available" || needsFallback(row)
                || !wifiDevice) return false;
        operationErrorText = "";
        if (psk && !isValidPsk(String(psk))) {
            operationErrorText = "Wi-Fi password must be 8–63 characters";
            return false;
        }
        if (operationBusy()) {
            if (pendingTargetKey === row.key) return queueMutation(row, "connect", psk);
            return false;
        }
        return startNetworkOperation(row, "connect", psk);
    }
    function isValidPsk(psk) {
        return typeof psk === "string" && psk.length >= 8 && psk.length <= 63
            && psk.trim().length > 0;
    }
    function disconnect(row) { return mutate(row, "disconnect"); }
    function forget(row) { return mutate(row, "forget"); }
    function mutate(row, operation) {
        if (!row || availability !== "available" || needsFallback(row)
                || !wifiDevice) return false;
        operationErrorText = "";
        if (operationBusy()) {
            if (pendingTargetKey === row.key) return queueMutation(row, operation, "");
            return false;
        }
        return startNetworkOperation(row, operation, "");
    }
    function finishOperation(error) {
        networkOperationTimer.stop();
        const wasNetworkOperation = pendingTargetKey.length > 0;
        if (error) operationErrorText = error;
        pendingTargetKey = ""; pendingOperation = ""; pendingWifiEnabled = null;
        if (wasNetworkOperation) Qt.callLater(startQueuedOperation);
    }
    function clearPending() { finishOperation(""); }
    function normalizeFailure(reason) {
        const text = String(reason || "Unknown").replace(/([A-Z])/g, " $1").trim();
        return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
    }

    onConnectionTypeChanged: {
        refreshAddress();
        if (pendingWifiEnabled === true && connectionType === "wifi") finishOperation("");
    }
    onIntegrationChanged: refreshNetworks()
    onWifiDeviceChanged: refreshNetworks()
    onInterfaceNameChanged: refreshAddress()
    onConnectivityChanged: if (interfaceName.length > 0) refreshAddress()
    onAddressIntegrationChanged: refreshAddress()

    Integrations.NetworkIntegration { id: nativeIntegration }
    Integrations.NetworkFallbackIntegration { id: nativeFallbackIntegration }
    Integrations.NetworkAddressIntegration { id: nativeAddressIntegration }

    Component.onCompleted: { refreshAddress(); refreshNetworks(); }

    Connections {
        target: root.wifiDevice && root.wifiDevice.networks ? root.wifiDevice.networks : null
        function onValuesChanged() { root.refreshNetworks(); }
    }

    Connections {
        target: integration
        function onWifiEnabledChanged() {
            if (pendingWifiEnabled === false && pendingWifiEnabled === root.wifiEnabled)
                root.finishOperation("");
            else if (pendingWifiEnabled === true && root.wifiEnabled
                    && root.connectionType === "wifi") root.finishOperation("");
        }
    }
    Connections {
        target: integration
        function onAvailabilityChanged() {
            if (root.availability === "unavailable") {
                root.queuedTargetKey = ""; root.queuedOperation = ""; root.queuedPsk = "";
                root.finishOperation("NetworkManager unavailable; state cleared");
            }
        }
    }
    Connections {
        target: root.pendingTargetKey.length > 0 && root.networkFor(root.pendingTargetKey)
            ? root.networkFor(root.pendingTargetKey).network : null
        function onConnectionFailed(reason) {
            root.operationErrorText = `Connection failed: ${root.normalizeFailure(reason)}`;
            root.finishOperation(`Connection failed: ${root.normalizeFailure(reason)}`);
        }
        function onConnectedChanged() {
            const row = root.networkFor(root.pendingTargetKey);
            if (!row) return;
            if (root.pendingOperation === "connect" && row.network.connected)
                root.clearPending();
            else if (root.pendingOperation === "disconnect" && !row.network.connected)
                root.clearPending();
        }
        function onKnownChanged() {
            const row = root.networkFor(root.pendingTargetKey);
            if (row && root.pendingOperation === "forget" && !row.network.known)
                root.clearPending();
        }
        function onNmSettingsChanged() {
            const row = root.networkFor(root.pendingTargetKey);
            if (row && root.pendingOperation === "forget"
                    && row.settings && row.network.nmSettings.indexOf(row.settings) === -1)
                root.clearPending();
        }
    }

    // nmSettings belongs to each network object, not to the device model.
    // Subscribe to every visible network so saved-profile projections stay fresh.
    Instantiator {
        model: root.wifiDevice && root.wifiDevice.networks ? root.wifiDevice.networks.values : []
        delegate: Connections {
            required property var modelData
            target: modelData
            function onNmSettingsChanged() { root.refreshNetworks(); }
        }
    }
    Timer {
        id: networkOperationTimer
        interval: root.operationTimeoutMs
        repeat: false
        onTriggered: {
            if (root.pendingOperation === "wifi") {
                root.operationErrorText = "Wi-Fi operation timed out";
                root.finishOperation("");
            } else if (root.pendingOperation.length > 0) {
                root.operationErrorText = "Network operation timed out";
                root.finishOperation("");
            }
        }
    }
}
