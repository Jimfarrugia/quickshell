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
    readonly property bool present: integration.present
    readonly property int percentage: integration.percentage
    readonly property bool charging: integration.charging
    readonly property string iconName: integration.iconName

    Integrations.UPowerIntegration { id: nativeIntegration }
}
