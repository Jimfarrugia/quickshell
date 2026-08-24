import QtQuick
import Quickshell.Wayland

QtObject {
    id: root

    property var ownerWindow: null
    property bool requested: false
    readonly property string availability: ownerWindow ? "available" : "unavailable"
    readonly property string freshness: ownerWindow ? "current" : "unknown"
    property var lastUpdated: null
    readonly property var lastError: null
    readonly property string operation: "idle"

    property IdleInhibitor inhibitor: IdleInhibitor {
        window: root.ownerWindow
        enabled: root.requested && root.ownerWindow !== null
    }

    onOwnerWindowChanged: lastUpdated = new Date()
    onRequestedChanged: lastUpdated = new Date()
}
