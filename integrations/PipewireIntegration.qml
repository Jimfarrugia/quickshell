import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var nodes: Pipewire.nodes.values
    readonly property var outputs: nodes.filter(node => node.audio && node.isSink && !node.isStream)
    readonly property var inputs: nodes.filter(node => node.audio && !node.isSink && !node.isStream)
    readonly property var playbackStreams: nodes.filter(node => node.audio && node.isSink && node.isStream)
    readonly property string availability: !Pipewire.ready ? "unknown" : (sink ? "available" : "unavailable")
    readonly property string microphoneAvailability: !Pipewire.ready ? "unknown" : (source ? "available" : "unavailable")
    readonly property string freshness: availability === "available" ? "current" : "unknown"
    readonly property var lastError: null
    readonly property string operation: "idle"
    property var lastUpdated: new Date()
    readonly property int volumePercent: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property bool microphoneMuted: source && source.audio ? source.audio.muted : false
    readonly property int microphoneVolumePercent: source && source.audio
        ? Math.round(source.audio.volume * 100) : 0
    readonly property string description: sink ? (sink.description || sink.name) : "No audio output"
    readonly property string microphoneDescription: source ? (source.description || source.name) : "No microphone"

    function setVolume(percent) {
        if (availability !== "available" || !sink || !sink.audio) return false;
        const clamped = Math.max(0, Math.min(200, Math.round(percent)));
        sink.audio.volume = clamped / 100;
        return true;
    }

    function setMuted(value) {
        if (availability !== "available" || !sink || !sink.audio) return false;
        sink.audio.muted = value === true;
        return true;
    }

    function setMicrophoneMuted(value) {
        if (microphoneAvailability !== "available" || !source || !source.audio) return false;
        source.audio.muted = value === true;
        return true;
    }

    function setMicrophoneVolume(percent) {
        if (microphoneAvailability !== "available" || !source || !source.audio) return false;
        const clamped = Math.max(0, Math.min(200, Math.round(percent)));
        source.audio.volume = clamped / 100;
        return true;
    }

    function setDefaultOutput(node) {
        if (!node || !node.audio) return false;
        Pipewire.preferredDefaultAudioSink = node;
        return true;
    }

    function setDefaultInput(node) {
        if (!node || !node.audio) return false;
        Pipewire.preferredDefaultAudioSource = node;
        return true;
    }

    property PwObjectTracker tracker: PwObjectTracker {
        objects: root.nodes
    }

    onVolumePercentChanged: lastUpdated = new Date()
    onMutedChanged: lastUpdated = new Date()
    onMicrophoneMutedChanged: lastUpdated = new Date()
    onMicrophoneVolumePercentChanged: lastUpdated = new Date()
}
