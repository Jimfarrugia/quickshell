pragma Singleton

import QtQuick
import Quickshell
import "../integrations" as Integrations

Singleton {
    id: root
    property var integration: nativeIntegration
    property var addressIntegration: nativeAddressIntegration
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

    onConnectionTypeChanged: refreshAddress()
    onInterfaceNameChanged: refreshAddress()
    onConnectivityChanged: if (interfaceName.length > 0) refreshAddress()
    onAddressIntegrationChanged: refreshAddress()

    Integrations.NetworkIntegration { id: nativeIntegration }
    Integrations.NetworkAddressIntegration { id: nativeAddressIntegration }

    Component.onCompleted: refreshAddress()
}
