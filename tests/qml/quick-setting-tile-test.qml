import QtQuick
import Quickshell
import "components" as Components
import "services" as Services

ShellRoot {
    id: root

    function fail(message) {
        console.error(`QUICK_SETTING_TILE_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function check() {
        if (!Qt.colorEqual(tile.resolvedTitleColor,
                Services.ThemeService.theme.tokens.on_surface_disabled)
                || !Qt.colorEqual(tile.resolvedIconColor,
                    Services.ThemeService.theme.tokens.on_surface_disabled))
            return fail("unavailable tile does not use disabled content styling");

        tile.primaryEnabled = true;
        if (!Qt.colorEqual(tile.resolvedTitleColor,
                Services.ThemeService.theme.tokens.on_surface)
                || !Qt.colorEqual(tile.resolvedValueColor,
                    Services.ThemeService.theme.tokens.on_surface_subdued))
            return fail("enabled tile does not use normal and subdued content roles");

        tile.checked = true;
        if (!Qt.colorEqual(tile.resolvedIconBackgroundColor,
                Services.ThemeService.theme.tokens.primary_container)
                || !Qt.colorEqual(tile.resolvedIconColor,
                    Services.ThemeService.theme.tokens.on_primary_container))
            return fail("checked tile does not use the selection pair");

        tile.checked = false;
        tile.pending = true;
        if (!Qt.colorEqual(tile.resolvedBorderColor,
                Services.ThemeService.theme.tokens.primary)
                || !Qt.colorEqual(tile.resolvedIconBackgroundColor,
                    Services.ThemeService.theme.tokens.primary)
                || !Qt.colorEqual(tile.resolvedIconColor,
                    Services.ThemeService.theme.tokens.on_primary))
            return fail("pending tile does not use the full primary pair");

        console.log("QUICK_SETTING_TILE_TEST_PASSED");
        Qt.quit();
    }

    FloatingWindow {
        visible: true
        implicitWidth: 320
        implicitHeight: 140

        Components.QuickSettingTile {
            id: tile
            anchors.centerIn: parent
            iconName: "wifi"
            title: "Wi-Fi"
            valueText: "Disconnected"
            primaryEnabled: false
            secondaryEnabled: false
        }
    }

    Timer { interval: 50; running: true; onTriggered: root.check() }
    Timer { interval: 5000; running: true; onTriggered: root.fail("test timed out") }
}
