pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool restartPending: false
    property string restartError: ""

    function restart() {
        if (restartPending) return false;
        restartError = ""
        restartPending = true;
        restartProcess.command = [Quickshell.shellPath("scripts/run-qe.sh"), "--restart"];
        restartProcess.startDetached();
        return true;
    }

    Process {
        id: restartProcess
        onRunningChanged: if (!running && root.restartPending) {
            root.restartPending = false;
            root.restartError = "Could not restart QE";
        }
    }
}
