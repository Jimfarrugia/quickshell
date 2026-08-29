import QtQuick
import Quickshell
import "services" as Services
import "fixtures/qml" as Fixtures
import "integrations" as Integrations

ShellRoot {
    id: root
    Fixtures.FakeAudioIntegration { id: fakeAudio }
    Fixtures.FakeBrightnessIntegration { id: fakeBrightness }
    Integrations.ActionsIpc { id: actions }

    function fail(message) {
        console.error(`PHASE6_ACTION_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function runChecks() {
        if (!Services.ConfigService.hasLoaded) {
            retryTimer.restart();
            return;
        }

        Services.AudioService.integration = fakeAudio;
        Services.OSDService.clear();

        fakeAudio.volumePercent = 195;
        fakeAudio.muted = true;
        if (!actions.volumeUp() || fakeAudio.lastSetPercent !== 200 || fakeAudio.muted)
            return fail("volume step did not preserve unmute and 200% semantics");
        if (!Services.OSDService.activeItem || Services.OSDService.activeItem.replacementKey !== "audio"
                || Services.OSDService.activeItem.state !== "confirmed"
                || Services.AudioService.operation === "pending")
            return fail("volume action did not confirm an OSD above 100 percent");

        Services.OSDService.clear();
        fakeAudio.volumePercent = 200;
        fakeAudio.muted = false;
        fakeAudio.setCallCount = 0;
        if (!actions.volumeUp() || fakeAudio.setCallCount !== 0
                || !Services.OSDService.activeItem
                || Services.OSDService.activeItem.detail !== "200%"
                || Services.OSDService.activeItem.state !== "confirmed")
            return fail("volume ceiling action attempted a set or did not confirm the ceiling OSD");

        if (!actions.toggleVolumeMute() || !fakeAudio.muted)
            return fail("output mute action did not toggle the native state");
        if (!actions.microphoneMute() || !fakeAudio.microphoneMuted)
            return fail("microphone mute action did not toggle the native state");

        Services.BrightnessService.integration = fakeBrightness;
        Services.BrightnessService.__confirmedPercent = 50;
        Services.BrightnessService.__confirmedDeviceName = "intel_backlight";
        Services.OSDService.clear();
        if (!actions.brightnessUp() || Services.OSDService.activeItem !== null
                || !Services.OSDService.pendingOperations["brightness"])
            return fail("brightness action exposed an unexpected pending OSD");
        fakeBrightness.emitSetFinished({ ok: true, name: "intel_backlight", brightness: 583, maxBrightness: 1060, percent: 55 });
        if (!Services.OSDService.activeItem || Services.OSDService.activeItem.state !== "confirmed"
                || Services.OSDService.activeItem.detail !== "55%")
            return fail("brightness confirmation did not publish a confirmed OSD");

        console.log("PHASE6_ACTION_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        id: retryTimer
        interval: 50
        repeat: false
        onTriggered: root.runChecks()
    }

    Component.onCompleted: Qt.callLater(runChecks)
}
