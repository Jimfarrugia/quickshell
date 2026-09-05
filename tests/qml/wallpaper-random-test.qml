import QtQuick
import QtQml
import Quickshell
import "services" as Services

ShellRoot {
    id: root

    readonly property var expectedPaths: [
        `${Services.WallpaperService.wallpaperRoot}/themes/${Services.ThemeService.activeThemeId}/first.png`,
        `${Services.WallpaperService.wallpaperRoot}/themes/${Services.ThemeService.activeThemeId}/second.jpg`
    ]

    QtObject {
        id: fakeWallpaperAdapter
        property string availability: "available"
        property string lastPath: ""
        function apply(path, operationId) {
            lastPath = path;
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
        Qt.quit();
    }

    function check() {
        if (!Services.WallpaperService.initialized
                || !Services.WallpaperService.wallpaperDirectoryReady) return;
        if (Services.WallpaperService.wallpaperDirectoryCount !== 2)
            return fail("active theme wallpaper directory was not catalogued");
        if (!Services.WallpaperService.requestRandomWallpaper())
            return fail("random wallpaper request was rejected");
        if (root.expectedPaths.indexOf(fakeWallpaperAdapter.lastPath) < 0)
            return fail("random wallpaper path was outside the active theme directory");
        console.log("WALLPAPER_RANDOM_TEST_PASSED");
        Qt.quit();
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
