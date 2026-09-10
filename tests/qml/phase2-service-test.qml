import QtQuick
import Quickshell
import "services" as Services
import "fixtures/qml" as Fixtures

ShellRoot {
    id: root

    Fixtures.FakeCompositorIntegration { id: fakeCompositor }
    Fixtures.FakeAudioIntegration { id: fakeAudio }
    Fixtures.FakeNetworkIntegration { id: fakeNetwork }
    Fixtures.FakeNetworkAddressIntegration { id: fakeNetworkAddress }
    Fixtures.FakePowerIntegration { id: fakePower }

    function fail(message) {
        console.error(`PHASE2_SERVICE_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    Component.onCompleted: {
        Services.CompositorService.integration = fakeCompositor;
        Services.AudioService.integration = fakeAudio;
        fakeAudio.autoConfirmVolume = false;
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
        fakeAudio.microphoneMuted = true;
        Services.AudioService.microphoneWheelStep(120);
        if (fakeAudio.lastMicrophoneSetPercent !== 40 || fakeAudio.microphoneMuted
                || Services.AudioService.pendingMicrophoneVolumePercent !== -1)
            return fail("microphone wheel did not raise, confirm, and unmute");
        if (Services.NetworkService.connectivity !== "full" || Services.NetworkService.summary !== "Online")
            return fail("network normalization failed");
        if (Services.NetworkService.connectionType !== "wifi" || Services.NetworkService.ssid !== "Fixture WiFi"
                || Services.NetworkService.signalStrength !== 73)
            return fail("Wi-Fi details were not normalized");
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
