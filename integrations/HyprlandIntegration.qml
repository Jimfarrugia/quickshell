import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    id: root

    readonly property string availability: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ? "available" : "unavailable"
    readonly property string freshness: availability === "available" ? "current" : "unknown"
    readonly property var lastError: null
    property var lastUpdated: new Date()
    readonly property string operation: "idle"
    readonly property var monitorModel: Hyprland.monitors
    readonly property var workspaceModel: Hyprland.workspaces
    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property string focusedWindowTitle: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"

    function activateWorkspace(workspace) {
        if (availability !== "available" || !workspace) return false;
        workspace.activate();
        return true;
    }

    function monitorForScreen(screen) { return screen ? Hyprland.monitorFor(screen) : null; }

    function refresh() {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        lastUpdated = new Date();
    }

    property Connections eventConnection: Connections {
        target: Hyprland
        function onRawEvent() { root.lastUpdated = new Date(); }
    }
}
