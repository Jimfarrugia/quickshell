import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property string availability: !Pipewire.ready ? "unknown" : (sink ? "available" : "unavailable")
    readonly property string freshness: availability === "available" ? "current" : "unknown"
    readonly property var lastError: null
    readonly property string operation: "idle"
    property var lastUpdated: new Date()
    readonly property int volumePercent: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property string description: sink ? (sink.description || sink.name) : "No audio output"

    function setVolume(percent) {
        if (availability !== "available" || !sink || !sink.audio) return false;
        const clamped = Math.max(0, Math.min(100, Math.round(percent)));
        sink.audio.volume = clamped / 100;
        return true;
    }

    property PwObjectTracker tracker: PwObjectTracker {
        objects: [root.sink]
    }

    onVolumePercentChanged: lastUpdated = new Date()
    onMutedChanged: lastUpdated = new Date()
}
