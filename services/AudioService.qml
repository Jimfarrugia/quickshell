pragma Singleton

import QtQuick
import Quickshell
import "../integrations" as Integrations

Singleton {
    id: root

    property var integration: nativeIntegration
    readonly property string availability: integration.availability
    readonly property string freshness: integration.freshness
    readonly property var lastUpdated: integration.lastUpdated
    readonly property var lastError: integration.lastError
    readonly property string operation: pendingVolumePercent >= 0 || pendingMuted !== null
        || pendingMicrophoneMuted !== null ? "pending" : integration.operation
    readonly property int volumePercent: integration.volumePercent
    readonly property int pendingVolumePercent: __pendingVolumePercent
    readonly property int displayVolumePercent: pendingVolumePercent >= 0 ? pendingVolumePercent : volumePercent
    readonly property bool muted: integration.muted
    readonly property bool microphoneMuted: integration.microphoneMuted === true
    readonly property string microphoneAvailability: integration.microphoneAvailability || "unavailable"
    readonly property string microphoneDescription: integration.microphoneDescription || "No microphone"
    readonly property var pendingMuted: __pendingMuted
    readonly property var pendingMicrophoneMuted: __pendingMicrophoneMuted
    readonly property string description: integration.description
    readonly property var outputs: integration.outputs || []
    readonly property var inputs: integration.inputs || []
    readonly property var playbackStreams: integration.playbackStreams || []
    readonly property var defaultOutput: integration.sink
    readonly property var defaultInput: integration.source
    property var fallbackIntegration: nativeFallbackIntegration
    readonly property string fallbackError: fallbackIntegration.error
    property int __pendingVolumePercent: -1
    property var __pendingMuted: null
    property var __pendingMicrophoneMuted: null
    property var __pendingNode: null
    property int __pendingNodeVolumePercent: -1
    property var __pendingNodeMuted: null

    function displayNodeVolumePercent(node) {
        if (node === defaultOutput) return displayVolumePercent;
        return node === __pendingNode && __pendingNodeVolumePercent >= 0
            ? __pendingNodeVolumePercent : Math.round((node.audio ? node.audio.volume : 0) * 100);
    }

    function displayNodeMuted(node) {
        return node === __pendingNode && __pendingNodeMuted !== null
            ? __pendingNodeMuted : node.audio && node.audio.muted;
    }

    function setVolume(percent) {
        if (availability !== "available") return false;
        const clamped = Math.max(0, Math.min(200, Math.round(percent)));
        __pendingVolumePercent = clamped;
        if (!integration.setVolume(clamped)) {
            __pendingVolumePercent = -1;
            return false;
        }
        return true;
    }

    function stepVolume(delta) {
        const base = pendingVolumePercent >= 0 ? pendingVolumePercent : volumePercent;
        if (muted && !setMuted(false)) return false;
        const target = Math.max(0, Math.min(200, base + delta));
        if (target === base) {
            __pendingVolumePercent = -1;
            return true;
        }
        return setVolume(target);
    }

    function setMuted(value) {
        if (availability !== "available" || !integration.setMuted) return false;
        __pendingMuted = value === true;
        if (!integration.setMuted(__pendingMuted)) {
            __pendingMuted = null;
            return false;
        }
        return true;
    }

    function toggleMuted() { return setMuted(!muted); }

    function setMicrophoneMuted(value) {
        if (microphoneAvailability !== "available" || !integration.setMicrophoneMuted) return false;
        __pendingMicrophoneMuted = value === true;
        if (!integration.setMicrophoneMuted(__pendingMicrophoneMuted)) {
            __pendingMicrophoneMuted = null;
            return false;
        }
        return true;
    }

    function toggleMicrophoneMuted() { return setMicrophoneMuted(!microphoneMuted); }

    function setDefaultOutput(node) {
        if (availability !== "available" || !integration.setDefaultOutput) return false;
        return integration.setDefaultOutput(node);
    }

    function setDefaultInput(node) {
        if (microphoneAvailability !== "available" || !integration.setDefaultInput) return false;
        return integration.setDefaultInput(node);
    }

    function setNodeVolume(node, percent) {
        if (!node || !node.audio) return false;
        const clamped = Math.max(0, Math.min(200, Math.round(percent)));
        __pendingNode = node;
        __pendingNodeVolumePercent = clamped;
        node.audio.volume = clamped / 100;
        return true;
    }

    function setNodeMuted(node, value) {
        if (!node || !node.audio) return false;
        __pendingNode = node;
        __pendingNodeMuted = value === true;
        node.audio.muted = __pendingNodeMuted;
        return true;
    }

    Connections {
        target: root.__pendingNode && root.__pendingNode.audio
        function onVolumeChanged() {
            if (root.__pendingNodeVolumePercent >= 0
                    && Math.abs(Math.round(target.volume * 100)
                    - root.__pendingNodeVolumePercent) <= 1)
                root.__pendingNodeVolumePercent = -1;
            if (root.__pendingNodeVolumePercent < 0 && root.__pendingNodeMuted === null)
                root.__pendingNode = null;
        }
        function onMutedChanged() {
            if (root.__pendingNodeMuted !== null && target.muted === root.__pendingNodeMuted)
                root.__pendingNodeMuted = null;
            if (root.__pendingNodeVolumePercent < 0 && root.__pendingNodeMuted === null)
                root.__pendingNode = null;
        }
    }

    function launchFallback() {
        return fallbackIntegration.launch();
    }

    function wheelStep(angleDeltaY) {
        if (angleDeltaY > 0) return stepVolume(5);
        if (angleDeltaY < 0) return stepVolume(-5);
        return false;
    }

    Connections {
        target: root.integration
        function onVolumePercentChanged() {
            if (root.__pendingVolumePercent >= 0
                    && Math.abs(root.integration.volumePercent - root.__pendingVolumePercent) <= 1)
                root.__pendingVolumePercent = -1;
        }
        function onMutedChanged() {
            if (root.__pendingMuted !== null && root.integration.muted === root.__pendingMuted)
                root.__pendingMuted = null;
        }
        function onMicrophoneMutedChanged() {
            if (root.__pendingMicrophoneMuted !== null
                    && root.integration.microphoneMuted === root.__pendingMicrophoneMuted)
                root.__pendingMicrophoneMuted = null;
        }
        function onAvailabilityChanged() {
            if (root.integration.availability !== "available")
                root.__pendingVolumePercent = -1;
            if (root.integration.availability !== "available") root.__pendingMuted = null;
        }
        function onMicrophoneAvailabilityChanged() {
            if (root.integration.microphoneAvailability !== "available")
                root.__pendingMicrophoneMuted = null;
        }
    }

    Integrations.PipewireIntegration { id: nativeIntegration }
    Integrations.AudioFallbackIntegration { id: nativeFallbackIntegration }
}
