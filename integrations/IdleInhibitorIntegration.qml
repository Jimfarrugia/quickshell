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
    readonly property bool desiredEnabled: requested && ownerWindow !== null

    function applyRequestedState() {
        inhibitor.enabled = desiredEnabled;
        if (desiredEnabled)
            rearmTimer.restart();
        else
            rearmTimer.stop();
    }

    property IdleInhibitor inhibitor: IdleInhibitor {
        window: root.ownerWindow
        enabled: false
    }

    // Quickshell 0.3.1 needs a settled-surface re-arm for restored startup requests.
    property Timer rearmTimer: Timer {
        id: rearmTimer
        interval: 100
        onTriggered: {
            inhibitor.enabled = false;
            Qt.callLater(() => inhibitor.enabled = root.desiredEnabled);
        }
    }

    onOwnerWindowChanged: lastUpdated = new Date()
    onRequestedChanged: lastUpdated = new Date()
    onDesiredEnabledChanged: applyRequestedState()
}
