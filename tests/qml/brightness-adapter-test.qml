import QtQuick
import Quickshell
import "services" as Services

ShellRoot {
    id: root

    function fail(message) {
        console.error(`BRIGHTNESS_ADAPTER_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function check() {
        if (!Services.ConfigService.hasLoaded
                || Services.BrightnessService.availability !== "available") {
            retryTimer.restart();
            return;
        }
        if (Services.BrightnessService.confirmedDeviceName.length === 0
                || Services.BrightnessService.confirmedDeviceMaxBrightness <= 0) {
            retryTimer.restart();
            return;
        }
        if (Services.BrightnessService.confirmedPercent < 0
                || Services.BrightnessService.confirmedPercent > 100)
            return fail("live backlight state was not normalized");
        console.log("BRIGHTNESS_ADAPTER_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        id: retryTimer
        interval: 50
        repeat: false
        onTriggered: root.check()
    }

    Timer {
        interval: 4500
        running: true
        onTriggered: root.fail(`timed out with availability=${Services.BrightnessService.availability}`)
    }

    Component.onCompleted: Qt.callLater(check)
}
