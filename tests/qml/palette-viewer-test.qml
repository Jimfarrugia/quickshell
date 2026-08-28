import QtQuick
import Quickshell
import "modules/palette"
import "services" as Services

ShellRoot {
    id: root

    property bool checked: false

    PaletteViewer {
        id: viewer
        visible: false
    }

    function fail(message) {
        console.error(`PALETTE_VIEWER_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function check() {
        if (checked || !Services.ThemeService.initialized || Services.ThemeService.theme.palette === undefined)
            return;
        checked = true;
        if (viewer.entries.length !== Object.keys(Services.ThemeService.theme.tokens).length)
            return fail("token entry count is incorrect");
        if (viewer.focusTarget !== "grid")
            return fail("viewer did not start with the grid focus target");
        if (viewer.entries[viewer.entries.length - 1] !== "charging")
            return fail("charging is not the final token");
        const emergencyTokens = Object.keys(Services.ThemeService.emergencyTheme.tokens);
        if (emergencyTokens[emergencyTokens.length - 1] !== "charging")
            return fail("charging is not the final emergency token");
        if (viewer.viewedThemeId !== Services.ThemeService.activeThemeId)
            return fail("viewer did not start on the active theme");
        if (!viewer.availableThemes.some(theme => theme.id === Services.ThemeService.activeThemeId))
            return fail("active theme is missing from viewer choices");
        if (viewer.availableThemes.filter(theme =>
                theme.id === Services.ThemeService.activeThemeId).length !== 1)
            return fail("active theme is duplicated in viewer choices");
        if (Services.ThemeService.catalog.length < 2)
            return fail("catalog does not contain an alternate theme");
        const alternate = Services.ThemeService.catalog.find(theme =>
            theme.id !== Services.ThemeService.activeThemeId);
        const activeThemeId = Services.ThemeService.activeThemeId;
        viewer.viewedThemeId = alternate.id;
        if (Services.ThemeService.activeThemeId !== activeThemeId)
            return fail("preview selection changed the active theme");
        if (viewer.viewedTheme.tokens.primary !== alternate.tokens.primary)
            return fail("viewer did not select the alternate theme");
        if (viewer.hexValue("#ff123456") !== "#123456")
            return fail("opaque alpha was not removed");
        if (viewer.hexValue("#80123456") !== "#80123456")
            return fail("transparent alpha was removed");
        viewer.viewMode = "palette";
        if (viewer.entries.length !== Object.keys(alternate.palette).length)
            return fail("palette entry count is incorrect");
        console.log("PALETTE_VIEWER_TEST_PASSED");
        Qt.quit();
    }

    Connections {
        target: Services.ThemeService
        function onInitializedChanged() { root.check(); }
        function onThemeChanged() { root.check(); }
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("palette viewer test timed out")
    }

    Component.onCompleted: root.check()
}
