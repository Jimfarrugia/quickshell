import QtQuick

QtObject {
    property string availability: "degraded"
    property string freshness: "stale"
    property var lastUpdated: null
    property var lastError: ({ code: "FIXTURE_DISCONNECTED" })
    property string operation: "idle"
    property var monitorModel: ({ values: [] })
    property var workspaceModel: []
    property var focusedWorkspace: null
    property string focusedWindowTitle: "Fixture window"
    property var lastActivatedWorkspace: null
    property bool monitorLookupAvailable: true
    function activateWorkspace(workspace) {
        lastActivatedWorkspace = workspace;
        return workspace !== null;
    }
    function monitorForScreen(screen) {
        return monitorLookupAvailable && screen ? ({ name: screen.name || String(screen) }) : null;
    }
    function refresh() {}
}
