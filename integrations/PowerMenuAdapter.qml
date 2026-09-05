import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property string availability: "available"
    readonly property string freshness: "current"
    readonly property var lastUpdated: null
    property string executable: "rofi_power_menu"
    property string lastError: ""
    readonly property bool running: process.running

    signal finished(bool success, string error)

    function launch() {
        if (process.running) return false;
        lastError = "";
        launchRequested = true;
        process.command = [root.executable];
        process.running = true;
        return true;
    }

    property bool launchRequested: false

    Process {
        id: process
        onExited: (exitCode, exitStatus) => {
            root.launchRequested = false;
            const success = exitCode === 0;
            root.lastError = success ? "" : `Power menu exited with status ${exitCode}`;
            root.finished(success, root.lastError);
        }
        onRunningChanged: {
            if (!running && root.launchRequested)
                Qt.callLater(() => {
                    if (!root.launchRequested) return;
                    root.launchRequested = false;
                    root.lastError = "Could not launch power menu";
                    root.finished(false, root.lastError);
                });
        }
    }
}
