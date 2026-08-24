pragma Singleton

import Quickshell

Singleton {
    property var integration: null
    readonly property string availability: integration ? integration.availability : "unavailable"
    readonly property string freshness: integration ? integration.freshness : "unknown"
    readonly property var lastUpdated: integration ? integration.lastUpdated : null
    readonly property var lastError: integration ? integration.lastError : null
    readonly property string operation: integration ? integration.operation : "idle"
    readonly property var items: integration ? integration.items : []
}
