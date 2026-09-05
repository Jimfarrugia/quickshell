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
    readonly property string focusedMonitorName: integration.focusedWorkspace && integration.focusedWorkspace.monitor
        ? integration.focusedWorkspace.monitor.name : ""
    readonly property string focusedWindowTitle: integration.focusedWindowTitle

    function activateWorkspace(workspace) { return integration.activateWorkspace(workspace); }
    function monitorNameForScreen(screen) {
        if (!screen) return "";
        var monitorModel = integration.monitorModel;
        if (!monitorModel || !monitorModel.values || monitorModel.values.length === 0) return "";
        var monitor = integration.monitorForScreen(screen);
        return monitor ? monitor.name : "";
    }
    function workspaceVisibleOnScreen(workspace, screen) {
        if (!workspace || workspace.id <= 0) return false;
        var monitorName = monitorNameForScreen(screen);
        if (!monitorName || !workspace.monitor || workspace.monitor.name !== monitorName) return false;
        var values = workspace.toplevels && workspace.toplevels.values ? workspace.toplevels.values : [];
        return workspace.active || values.length > 0;
    }
    function refresh() { integration.refresh(); }

    Integrations.HyprlandIntegration { id: nativeIntegration }
}
