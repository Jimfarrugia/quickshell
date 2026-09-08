import QtQuick
import Quickshell
import Quickshell.Wayland
import "lock" as Lock

ShellRoot {
    id: root
    property date now: new Date()

    function scheduleClockUpdate() {
        const millisecondsIntoMinute = Date.now() % 60000;
        clockTimer.interval = Math.max(1, 60000 - millisecondsIntoMinute);
        clockTimer.restart();
    }

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

    Lock.LockPowerReader {
        id: powerReader
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
            power: powerReader
            now: root.now
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

    Timer {
        id: clockTimer
        repeat: false
        onTriggered: {
            root.now = new Date();
            root.scheduleClockUpdate();
        }
    }

    Component.onCompleted: {
        beginWhenReady();
        scheduleClockUpdate();
    }
}
