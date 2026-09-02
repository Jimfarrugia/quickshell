import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string error: ""
    property bool pending: false

    function launch() {
        error = ""
        pending = true
        process.command = ["blueman-manager"]
        process.running = true
        return process.running
    }

    Process {
        id: process
        onExited: (exitCode, exitStatus) => {
            root.pending = false
            if (exitCode !== 0) root.error = "Could not launch blueman-manager"
        }
        onRunningChanged: if (!running && root.pending)
            Qt.callLater(() => {
                if (root.pending) {
                    root.pending = false
                    root.error = "Could not launch blueman-manager"
                }
            })
    }
}
