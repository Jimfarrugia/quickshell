import QtQuick
import Quickshell
import Quickshell.Wayland
import "lock" as Lock

ShellRoot {
    id: root

    function beginWhenReady() {
        if (!themeReader.ready || lockController.state !== "idle") return;
        lockController.prerequisitesReady = !themeReader.watchersActive;
        lockController.begin();
    }

    Lock.LockThemeReader {
        id: themeReader
        onReadyChanged: root.beginWhenReady()
    }

    Lock.LockPamAdapter {
        id: pamAdapter
    }

    WlSessionLock {
        id: sessionLock

        Lock.LockSurface {
            controller: lockController
            lockTheme: themeReader.theme
            appearance: themeReader.appearance
        }
    }

    Lock.LockController {
        id: lockController
        sessionLock: sessionLock
        authenticator: pamAdapter
        onStateChanged: {
            if (state === "acquisitionFailed") Qt.quit();
            else if (state === "unlocked") exitTimer.start();
        }
    }

    Timer {
        id: exitTimer
        interval: 100
        repeat: false
        onTriggered: Qt.quit()
    }

    Component.onCompleted: beginWhenReady()
}
