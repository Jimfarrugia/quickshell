import QtQuick
import Quickshell
import "lock" as Lock

ShellRoot {
    id: root

    Lock.LockWallpaperReader {
        id: defaultReader
        statePath: Quickshell.shellPath("fixtures/lock/missing-wallpaper-state.json")
        defaultWallpaperPath: Quickshell.shellPath("../../defaults/wallpaper/images/current-wallpaper.png")
    }

    Lock.LockWallpaperReader {
        id: invalidReader
        statePath: Quickshell.shellPath("fixtures/lock/invalid-wallpaper-state.json")
        defaultWallpaperPath: Quickshell.shellPath("../../defaults/wallpaper/images/current-wallpaper.png")
    }

    function fail(message) {
        console.error(`LOCK_WALLPAPER_READER_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function check() {
        if (!defaultReader.ready || !invalidReader.ready) return;
        if (defaultReader.usingFallback || defaultReader.sourceUrl.length === 0
                || defaultReader.watchersActive)
            return fail("authored default wallpaper was not loaded and frozen");
        if (!invalidReader.usingFallback || invalidReader.sourceUrl.length !== 0
                || invalidReader.watchersActive)
            return fail("invalid wallpaper state did not settle to opaque fallback");
        console.log("LOCK_WALLPAPER_READER_TEST_PASSED");
        Qt.quit();
    }

    Connections {
        target: defaultReader
        function onReadyChanged() { root.check(); }
    }

    Connections {
        target: invalidReader
        function onReadyChanged() { root.check(); }
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail(`test timed out: default=${defaultReader.ready}/${defaultReader.usingFallback}/${defaultReader.watchersActive}, invalid=${invalidReader.ready}/${invalidReader.usingFallback}/${invalidReader.watchersActive}`)
    }
}
