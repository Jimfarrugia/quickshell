import QtQuick
import Quickshell
import "services" as Services

ShellRoot {
    id: root

    Loader {
        id: controlLoader
        active: true
        source: "modules/controlcenter/ControlCenter.qml"
    }

    function fail(message) {
        console.error(`CONTROL_CENTER_STATE_TEST_FAILED: ${message}`);
        Qt.exit(1);
    }

    function check() {
        const control = controlLoader.item;
        if (!control || control.quickSettingTiles.length !== 6) return;

        const titles = control.quickSettingTiles.map(tile => tile.title);
        const expected = ["Wi-Fi", "Bluetooth", "Do Not Disturb", "Idle inhibitor",
            "Volume", "Microphone"];
        if (titles.some((title, index) => title !== expected[index]))
            return fail("quick-setting tile inventory changed");
        if (!control.quickSettingTiles[0].secondaryEnabled
                || !control.quickSettingTiles[1].secondaryEnabled
                || !control.quickSettingTiles[4].secondaryEnabled
                || !control.quickSettingTiles[5].secondaryEnabled)
            return fail("dashboard secondary actions are missing");
        if (String(control.quickSettingTiles[2].activeColor)
                    !== String(Services.ThemeService.theme.tokens.warning)
                || String(control.quickSettingTiles[3].activeColor)
                    !== String(Services.ThemeService.theme.tokens.warning))
            return fail("DND and idle inhibitor do not use warning active styling");
        if (String(control.quickSettingTiles[4].activeColor)
                    !== String(Services.ThemeService.theme.tokens.success)
                || String(control.quickSettingTiles[4].alertColor)
                    !== String(Services.ThemeService.theme.tokens.error)
                || String(control.quickSettingTiles[5].activeColor)
                    !== String(Services.ThemeService.theme.tokens.success)
                || String(control.quickSettingTiles[5].alertColor)
                    !== String(Services.ThemeService.theme.tokens.error))
            return fail("audio tile success/error styling is missing");
        console.log("CONTROL_CENTER_STATE_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: root.check()
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("control center state test timed out")
    }
}
