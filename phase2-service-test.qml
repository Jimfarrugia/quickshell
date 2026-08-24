import QtQuick
import Quickshell
import "services" as Services
import "modules/bar" as BarModules
import "tests/fixtures/qml" as Fixtures

ShellRoot {
    id: root

    Fixtures.FakeCompositorIntegration { id: fakeCompositor }
    Fixtures.FakeAudioIntegration { id: fakeAudio }
    Fixtures.FakeNetworkIntegration { id: fakeNetwork }
    Fixtures.FakeNetworkAddressIntegration { id: fakeNetworkAddress }
    Fixtures.FakePowerIntegration { id: fakePower }
    BarModules.AudioModule { id: audioModule; visible: false }
    BarModules.BatteryModule { id: batteryModule; visible: false }

    function fail(message) {
        console.error(`PHASE2_SERVICE_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    Component.onCompleted: {
        Services.CompositorService.integration = fakeCompositor;
        Services.AudioService.integration = fakeAudio;
        Services.NetworkService.integration = fakeNetwork;
        Services.NetworkService.addressIntegration = fakeNetworkAddress;
        Services.PowerService.integration = fakePower;
        Qt.callLater(runChecks);
    }

    function runChecks() {
        if (!Services.ConfigService.hasLoaded || Services.TimeService.text.length === 0) {
            retryTimer.restart();
            return;
        }
        if (Services.CompositorService.availability !== "degraded" || Services.CompositorService.freshness !== "stale")
            return fail("compositor degraded state was not preserved");
        if (Services.AudioService.volumePercent !== 42 || Services.AudioService.muted)
            return fail("audio normalization failed");
        const audioCases = [
            [0, "volume_mute"], [30, "volume_mute"],
            [31, "volume_down"], [60, "volume_down"],
            [61, "volume_up"], [100, "volume_up"]
        ];
        for (let index = 0; index < audioCases.length; index++) {
            if (audioModule.iconForVolume(audioCases[index][0]) !== audioCases[index][1])
                return fail(`audio icon threshold failed at ${audioCases[index][0]}%`);
        }
        if (Services.NetworkService.connectivity !== "full" || Services.NetworkService.summary !== "Online")
            return fail("network normalization failed");
        if (Services.NetworkService.connectionType !== "wifi" || Services.NetworkService.ssid !== "Fixture WiFi"
                || Services.NetworkService.signalStrength !== 73)
            return fail("Wi-Fi details were not normalized");
        fakeNetwork.connectionType = "wired";
        fakeNetwork.ssid = "";
        fakeNetwork.signalStrength = 0;
        fakeNetwork.wiredInterface = "fixture0";
        Services.NetworkService.refreshWiredAddress();
        if (Services.NetworkService.ipv4Address !== "192.0.2.10")
            return fail("wired IPv4 enrichment failed");
        fakeNetwork.connectionType = "disconnected";
        fakeNetwork.wiredInterface = "";
        Services.NetworkService.refreshWiredAddress();
        if (Services.NetworkService.ipv4Address !== "")
            return fail("disconnected state retained a stale address");
        if (Services.PowerService.availability !== "unavailable" || Services.PowerService.present)
            return fail("desktop battery absence was not isolated");
        const batteryCases = [
            [15, "battery_android_alert"], [16, "battery_android_frame_1"],
            [24, "battery_android_frame_1"], [25, "battery_android_frame_2"],
            [34, "battery_android_frame_2"], [35, "battery_android_frame_3"],
            [49, "battery_android_frame_3"], [50, "battery_android_frame_4"],
            [64, "battery_android_frame_4"], [65, "battery_android_frame_5"],
            [80, "battery_android_frame_5"], [81, "battery_android_frame_6"],
            [95, "battery_android_frame_6"], [96, "battery_android_frame_full"]
        ];
        for (let index = 0; index < batteryCases.length; index++) {
            if (batteryModule.iconForPercentage(batteryCases[index][0]) !== batteryCases[index][1])
                return fail(`battery icon threshold failed at ${batteryCases[index][0]}%`);
        }
        fakePower.availability = "available";
        fakePower.present = true;
        fakePower.percentage = 15;
        if (batteryModule.iconColor.toString() !== Services.ThemeService.theme.tokens.error)
            return fail("critical battery color was not applied");
        fakePower.percentage = 16;
        if (batteryModule.iconColor.toString() !== Services.ThemeService.theme.tokens.warning)
            return fail("warning battery color was not applied");
        fakeAudio.availability = "unavailable";
        if (Services.NetworkService.availability !== "available")
            return fail("audio loss degraded an unrelated service");
        console.log("PHASE2_SERVICE_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        id: retryTimer
        interval: 50
        repeat: false
        onTriggered: root.runChecks()
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail("test timed out")
    }
}
