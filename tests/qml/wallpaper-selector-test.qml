import QtQuick
import Quickshell
import "modules/wallpaper"
import "services" as Services

ShellRoot {
    id: root

    function fail(message) {
        console.error(`WALLPAPER_SELECTOR_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function fuzzyEqual(left, right) {
        return Math.abs(left - right) < 0.01;
    }

    function check() {
        if (selector.columnsForWidth(400, 1920) !== 1
                || selector.columnsForWidth(600, 1920) !== 2
                || selector.columnsForWidth(900, 1920) !== 3
                || selector.columnsForWidth(1200, 1920) !== 4)
            return fail("responsive column breakpoints are incorrect");

        const gap = 6;
        const cardWidth = selector.cardWidthForGrid(1000, 4, gap);
        if (!fuzzyEqual(cardWidth * 4 + gap * 3, 1000))
            return fail("card widths and grid gaps do not fill the grid");
        const cellWidth = 1000 / 4;
        for (let column = 0; column < 4; ++column) {
            const start = column * cellWidth + selector.cardOffsetForColumn(column, 4, gap);
            if (column === 0 && !fuzzyEqual(start, 0))
                return fail("first card does not align with the left grid edge");
            if (column === 3 && !fuzzyEqual(start + cardWidth, 1000))
                return fail("last card does not align with the right grid edge");
            if (column > 0) {
                const previousStart = (column - 1) * cellWidth
                    + selector.cardOffsetForColumn(column - 1, 4, gap);
                if (!fuzzyEqual(start - (previousStart + cardWidth), gap))
                    return fail("card gap is incorrect");
            }
        }
        if (!fuzzyEqual(cardWidth / (cardWidth * 9 / 16), 16 / 9))
            return fail("card dimensions are not 16:9");

        if (selector.wallpaperCount !== 1)
            return fail("theme filter did not limit the wallpaper model");
        if (selector.focusedIndex !== 0 || selector.focusedWallpaperFileName !== "first.jpg")
            return fail("initial focused filename is incorrect");
        selector.selectedWallpaperThemeId = "*";
        Qt.callLater(root.checkSecondItem);
    }

    function checkSecondItem() {
        if (selector.wallpaperCount !== 2)
            return fail("Show All did not include every theme's wallpapers");
        selector.focusedIndex = 1;
        Qt.callLater(root.finish);
    }

    function finish() {
        if (selector.focusedWallpaperFileName !== "second.jpg")
            return fail("focused filename did not follow the grid index");
        console.log("WALLPAPER_SELECTOR_TEST_PASSED");
        Qt.quit();
    }

    QtObject {
        id: fixtureModel
        readonly property int count: 2
        function get(index) {
            return index === 0
                ? { thumbnailUrl: "", sourcePath: "/fixture/first.jpg", fileName: "first.jpg",
                    themeId: Services.ThemeService.activeThemeId }
                : { thumbnailUrl: "", sourcePath: "/fixture/second.jpg", fileName: "second.jpg",
                    themeId: "fixture-alternate" };
        }
    }

    WallpaperSelector {
        id: selector
        visible: false
        wallpaperModel: fixtureModel
    }

    Timer {
        interval: 50
        running: true
        onTriggered: root.check()
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("wallpaper selector test timed out")
    }
}
