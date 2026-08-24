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
    readonly property int volumePercent: integration.volumePercent
    readonly property bool muted: integration.muted
    readonly property string description: integration.description

    Integrations.PipewireIntegration { id: nativeIntegration }
}
