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
    readonly property string description: integration.selectedDescription()

    function next() { return integration.next(); }
    function previous() { return integration.previous(); }
    function togglePlaying() { return integration.togglePlaying(); }

    Integrations.MprisIntegration { id: nativeIntegration }
}
