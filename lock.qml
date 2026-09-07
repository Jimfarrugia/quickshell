import QtQuick
import Quickshell
import Quickshell.Wayland
import "lock" as Lock

ShellRoot {
    id: root

    function beginWhenReady() {
        if (!themeReader.ready || !wallpaperReader.ready || lockController.state !== "idle") return;
        lockController.prerequisitesReady = !themeReader.watchersActive && !wallpaperReader.watchersActive;
        lockController.begin();
    }

    Lock.LockThemeReader {
        id: themeReader
        onReadyChanged: root.beginWhenReady()
    }

    Lock.LockWallpaperReader {
        id: wallpaperReader
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
            wallpaperSource: wallpaperReader.sourceUrl
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
