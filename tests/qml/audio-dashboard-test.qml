import QtQuick
import Quickshell
import "services" as Services
import "fixtures/qml" as Fixtures
import "modules/audio" as AudioModules

ShellRoot {
    Fixtures.FakeAudioIntegration { id: fakeAudio }
    Fixtures.FakeAudioFallbackIntegration { id: fakeFallback }
    QtObject {
        id: outputAudio
        property real volume: 0.55
        property bool muted: false
    }
    AudioModules.AudioDashboard { id: dashboard; visible: false }
    QtObject {
        id: inputAudio
        property real volume: 0.80
        property bool muted: false
    }
    QtObject {
        id: output
        property string name: "fixture-output"
        property string description: "Fixture output"
        property string nickname: ""
        property bool isSink: true
        property bool isStream: false
        property QtObject audio: outputAudio
    }
    QtObject {
        id: input
        property string name: "fixture-input"
        property string description: "Fixture input"
        property string nickname: ""
        property bool isSink: false
        property bool isStream: false
        property QtObject audio: inputAudio
    }
    QtObject {
        id: stream
        property string name: "fixture-stream"
        property string description: "Fixture application"
        property string nickname: ""
        property bool isSink: true
        property bool isStream: true
        property QtObject audio: outputAudio
    }

    function fail(message) {
        console.error(`AUDIO_DASHBOARD_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    Component.onCompleted: {
        fakeAudio.outputs = [output];
        fakeAudio.inputs = [input];
        fakeAudio.playbackStreams = [stream];
        fakeAudio.sink = null;
        fakeAudio.sink = output;
        fakeAudio.source = input;
        Services.AudioService.integration = fakeAudio;
        Services.AudioService.fallbackIntegration = fakeFallback;
        Qt.callLater(runChecks);
    }

    function runChecks() {
        if (Services.AudioService.outputs.length !== 1
                || Services.AudioService.inputs.length !== 1
                || Services.AudioService.playbackStreams.length !== 1)
            return fail("audio node groups were not exposed");
        if (dashboard.children.length === 0)
            return fail("audio dashboard did not instantiate content");
        Services.AudioService.setDefaultOutput(output);
        fakeAudio.sink = output;
        fakeAudio.autoConfirmVolume = false;
        Services.AudioService.setVolume(90);
        if (Services.AudioService.pendingVolumePercent !== 90)
            return fail("pending volume was not exposed");
        fakeAudio.volumePercent = 42;
        if (Services.AudioService.pendingVolumePercent !== 90)
            return fail("intermediate volume event cleared pending state");
        fakeAudio.volumePercent = 90;
        if (Services.AudioService.pendingVolumePercent !== -1)
            return fail("confirmed volume did not clear pending state");
        fakeAudio.availability = "unknown";
        if (Services.AudioService.pendingVolumePercent !== -1)
            return fail("service loss did not clear pending state");
        fakeAudio.availability = "available";
        fakeAudio.freshness = "stale";
        fakeAudio.lastError = "WirePlumber unavailable";
        if (Services.AudioService.freshness !== "stale"
                || Services.AudioService.lastError !== "WirePlumber unavailable")
            return fail("stale service state was not preserved");
        fakeAudio.freshness = "current";
        fakeAudio.lastError = null;
        fakeAudio.outputs = [];
        if (Services.AudioService.outputs.length !== 0)
            return fail("output hot-unplug was not reflected");
        fakeAudio.outputs = [output];
        if (Services.AudioService.outputs.length !== 1)
            return fail("output hot-plug was not reflected");
        if (Services.AudioService.launchFallback()
                || Services.AudioService.fallbackError !== "Could not launch pavucontrol")
            return fail("fallback launch failure was not surfaced");
        if (!Services.AudioService.setNodeVolume(output, 125)
                || Math.round(outputAudio.volume * 100) !== 125)
            return fail("output volume was not bounded and applied");
        if (!Services.AudioService.setNodeMuted(input, true) || !inputAudio.muted)
            return fail("input mute was not applied");
        console.log("AUDIO_DASHBOARD_TEST_PASSED");
        Qt.quit();
    }

    Timer { interval: 3000; running: true; onTriggered: fail("test timed out") }
}
