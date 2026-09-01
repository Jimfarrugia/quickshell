import QtQuick

QtObject {
    property string availability: "available"
    property string freshness: "current"
    property var lastUpdated: new Date()
    property var lastError: null
    property string operation: "idle"
    property int volumePercent: 42
    property bool muted: false
    property bool microphoneMuted: false
    property string microphoneAvailability: "available"
    property string microphoneDescription: "Fixture microphone"
    property string description: "Fixture sink"
    property var sink: null
    property var source: null
    property int setCallCount: 0
    property int lastSetPercent: -1
    property bool acceptSet: true
    property bool autoConfirmVolume: true
    property bool acceptMute: true
    property bool acceptMicrophoneMute: true
    property var outputs: []
    property var inputs: []
    property var playbackStreams: []

    function setVolume(percent) {
        setCallCount++;
        lastSetPercent = percent;
        if (acceptSet && autoConfirmVolume) volumePercent = percent;
        return acceptSet;
    }

    function setMuted(value) {
        if (!acceptMute) return false;
        muted = value;
        return true;
    }

    function setMicrophoneMuted(value) {
        if (!acceptMicrophoneMute) return false;
        microphoneMuted = value;
        return true;
    }

    function setDefaultOutput(node) { return true; }
    function setDefaultInput(node) { return true; }
}
