import QtQuick
import QtQml
import Quickshell
import "services" as Services

ShellRoot {
    id: root
    property bool requested: false
    property string activePath: ""

    readonly property var expectedPaths: [
        `${Services.WallpaperService.wallpaperRoot}/themes/${Services.ThemeService.activeThemeId}/first.png`,
        `${Services.WallpaperService.wallpaperRoot}/themes/${Services.ThemeService.activeThemeId}/second.jpg`
    ]

    QtObject {
        id: fakeWallpaperAdapter
        property string availability: "available"
        property string lastPath: ""
        property string activeId: ""
        property int calls: 0
        signal finished(var result)
        function apply(path, operationId) {
            calls++;
            if (activeId) return false;
            lastPath = path;
            activeId = operationId;
            return true;
        }
    }

    Binding {
        target: Services.WallpaperService
        property: "wallpaperAdapter"
        value: fakeWallpaperAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    function fail(message) {
        console.error(`WALLPAPER_RANDOM_TEST_FAILED: ${message}`);
        Qt.exit(1);
    }

    function check() {
        if (requested) {
            if (Services.WallpaperService.operation !== "succeeded") return;
            if (Services.WallpaperService.selectedPath !== activePath)
                return fail("active wallpaper completion was lost after busy requests");
            console.log("WALLPAPER_RANDOM_TEST_PASSED");
            Qt.quit();
            return;
        }
        if (!Services.WallpaperService.initialized
                || !Services.WallpaperService.wallpaperDirectoryReady) return;
        if (Services.WallpaperService.wallpaperDirectoryCount !== 2)
            return fail("active theme wallpaper directory was not catalogued");
        if (!Services.WallpaperService.requestRandomWallpaper())
            return fail("random wallpaper request was rejected");
        if (root.expectedPaths.indexOf(fakeWallpaperAdapter.lastPath) < 0)
            return fail("random wallpaper path was outside the active theme directory");
        requested = true;
        activePath = fakeWallpaperAdapter.lastPath;
        if (Services.WallpaperService.requestWallpaper(expectedPaths[0])
                || Services.WallpaperService.requestWallpaper(expectedPaths[1]))
            return fail("busy wallpaper requests were accepted");
        if (Services.WallpaperService.operation !== "pending" || fakeWallpaperAdapter.calls !== 1
                || Services.WallpaperService.pendingOperationId !== fakeWallpaperAdapter.activeId
                || Services.WallpaperService.pendingPath !== activePath)
            return fail("busy requests changed the active wallpaper operation");
        fakeWallpaperAdapter.finished({ operationId: fakeWallpaperAdapter.activeId, success: true, live: "requested" });
    }

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: root.check()
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("random wallpaper test timed out")
    }
}
