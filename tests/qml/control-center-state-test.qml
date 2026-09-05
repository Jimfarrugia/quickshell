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
        if (control.monitorModeDropdown.model.length !== 2
                || control.monitorDirectionDropdown.model.length !== 4)
            return fail("monitor layout options are incomplete");
        if (control.primaryScaleSlider.from !== 0
                || control.primaryScaleSlider.to !== 5
                || control.primaryScaleSlider.stepSize !== 1
                || control.secondaryScaleSlider.to !== 5)
            return fail("monitor scale sliders are not discrete validated presets");
        if (control.primaryScaleControlItem.scaleAtPosition(0) !== 1
                || control.primaryScaleControlItem.scaleAtPosition(0.2) !== 1.2
                || control.primaryScaleControlItem.scaleAtPosition(1) !== 2)
            return fail("monitor scale slider preview does not track thumb position");
        Services.MonitorLayoutService.confirmedMode = "";
        if (control.secondaryScaleControlItem.visible)
            return fail("HDMI scale was visible before live mode confirmation");
        Services.MonitorLayoutService.confirmedMode = "mirror";
        if (control.secondaryScaleControlItem.visible)
            return fail("HDMI scale remained visible while mirrored");
        Services.MonitorLayoutService.confirmedMode = "extended";
        if (!control.secondaryScaleControlItem.visible)
            return fail("HDMI scale was hidden while extended");
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
