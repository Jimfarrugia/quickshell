import QtQuick

QtObject {
    property string availability: "degraded"
    property string freshness: "stale"
    property var lastUpdated: null
    property var lastError: ({ code: "FIXTURE_DISCONNECTED" })
    property string operation: "idle"
    property var workspaceModel: []
    property var focusedWorkspace: null
    property string focusedWindowTitle: "Fixture window"
    function activateWorkspace(workspace) { return workspace !== null; }
    function refresh() {}
}
