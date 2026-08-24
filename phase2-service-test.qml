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
    BarModules.NetworkModule { id: networkModule; visible: false }

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
        if (audioModule.hoverText !== "Fixture sink")
            return fail(`audio hover was '${audioModule.hoverText}'`);
        const audioCases = [
            [0, "volume_mute"], [30, "volume_mute"],
            [31, "volume_down"], [60, "volume_down"],
            [61, "volume_up"], [100, "volume_up"]
        ];
        for (let index = 0; index < audioCases.length; index++) {
            if (audioModule.iconForVolume(audioCases[index][0]) !== audioCases[index][1])
                return fail(`audio icon threshold failed at ${audioCases[index][0]}%`);
        }
        Services.AudioService.wheelStep(120);
        if (Services.AudioService.pendingVolumePercent !== 47
                || Services.AudioService.displayVolumePercent !== 47
                || fakeAudio.lastSetPercent !== 47)
            return fail("volume wheel up did not request a 5% increase");
        Services.AudioService.wheelStep(120);
        if (Services.AudioService.pendingVolumePercent !== 52 || fakeAudio.lastSetPercent !== 52)
            return fail("rapid volume wheel steps did not accumulate from pending state");
        fakeAudio.volumePercent = 47;
        if (Services.AudioService.pendingVolumePercent !== 52)
            return fail("intermediate PipeWire event cleared the latest pending volume");
        fakeAudio.volumePercent = 52;
        if (Services.AudioService.pendingVolumePercent !== -1
                || Services.AudioService.volumePercent !== 52)
            return fail("PipeWire event did not confirm pending volume");
        Services.AudioService.wheelStep(-120);
        if (Services.AudioService.pendingVolumePercent !== 47 || fakeAudio.lastSetPercent !== 47)
            return fail("volume wheel down did not request a 5% decrease");
        fakeAudio.volumePercent = 47;
        fakeAudio.acceptSet = false;
        if (Services.AudioService.setVolume(60)
                || Services.AudioService.pendingVolumePercent !== -1)
            return fail("rejected volume request remained pending");
        fakeAudio.acceptSet = true;
        if (Services.NetworkService.connectivity !== "full" || Services.NetworkService.summary !== "Online")
            return fail("network normalization failed");
        if (Services.NetworkService.connectionType !== "wifi" || Services.NetworkService.ssid !== "Fixture WiFi"
                || Services.NetworkService.signalStrength !== 73)
            return fail("Wi-Fi details were not normalized");
        if (networkModule.hoverText !== "Type: Wi-Fi\nInterface: wlan0\nSSID: Fixture WiFi\nIP: 198.51.100.5\nConnectivity: Full")
            return fail(`Wi-Fi hover was '${networkModule.hoverText}'`);
        fakeNetwork.connectionType = "wired";
        fakeNetwork.ssid = "";
        fakeNetwork.signalStrength = 0;
        fakeNetwork.wiredInterface = "fixture0";
        Services.NetworkService.refreshAddress();
        if (Services.NetworkService.ipv4Address !== "192.0.2.10")
            return fail("wired IPv4 enrichment failed");
        fakeNetwork.connectionType = "disconnected";
        fakeNetwork.wiredInterface = "";
        Services.NetworkService.refreshAddress();
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
        fakePower.percentage = 10;
        fakePower.charging = true;
        fakePower.timeToFullSeconds = 5400;
        if (batteryModule.icon !== "battery_android_frame_bolt")
            return fail("charging battery did not use the bolt icon");
        if (batteryModule.iconColor.toString() !== Services.ThemeService.theme.tokens.accentSecondary
                || batteryModule.textColor.toString() !== Services.ThemeService.theme.tokens.textSecondary)
            return fail("charging battery did not retain normal colors");
        if (batteryModule.hoverText !== "Time to full: 1h 30m")
            return fail(`charging battery hover was '${batteryModule.hoverText}'`);
        fakePower.charging = false;
        fakePower.timeToEmptySeconds = 16200;
        if (batteryModule.hoverText !== "Time to empty: 4h 30m")
            return fail(`discharging battery hover was '${batteryModule.hoverText}'`);
        fakePower.fullyCharged = true;
        if (batteryModule.hoverText !== "Fully charged.")
            return fail(`fully charged battery hover was '${batteryModule.hoverText}'`);
        fakePower.fullyCharged = false;
        fakeAudio.availability = "unavailable";
        const audioCalls = fakeAudio.setCallCount;
        Services.AudioService.wheelStep(120);
        if (fakeAudio.setCallCount !== audioCalls)
            return fail("volume wheel input reached unavailable audio integration");
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
