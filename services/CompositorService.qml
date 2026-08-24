pragma Singleton

import Quickshell
import "../integrations" as Integrations

Singleton {
    id: root
    property var integration: nativeIntegration
    readonly property string availability: integration.availability
    readonly property string freshness: integration.freshness
    readonly property var lastUpdated: integration.lastUpdated
    readonly property var lastError: integration.lastError
    readonly property string operation: integration.operation
    readonly property var workspaceModel: integration.workspaceModel
    readonly property var focusedWorkspace: integration.focusedWorkspace
    readonly property string focusedWindowTitle: integration.focusedWindowTitle

    function activateWorkspace(workspace) { return integration.activateWorkspace(workspace); }
    function refresh() { integration.refresh(); }

    Integrations.HyprlandIntegration { id: nativeIntegration }
}
