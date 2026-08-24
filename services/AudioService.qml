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
    readonly property string operation: pendingVolumePercent >= 0 ? "pending" : integration.operation
    readonly property int volumePercent: integration.volumePercent
    readonly property int pendingVolumePercent: __pendingVolumePercent
    readonly property int displayVolumePercent: pendingVolumePercent >= 0 ? pendingVolumePercent : volumePercent
    readonly property bool muted: integration.muted
    readonly property string description: integration.description
    property int __pendingVolumePercent: -1

    function setVolume(percent) {
        if (availability !== "available") return false;
        const clamped = Math.max(0, Math.min(100, Math.round(percent)));
        __pendingVolumePercent = clamped;
        if (!integration.setVolume(clamped)) {
            __pendingVolumePercent = -1;
            return false;
        }
        return true;
    }

    function stepVolume(delta) {
        const base = pendingVolumePercent >= 0 ? pendingVolumePercent : volumePercent;
        return setVolume(base + delta);
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
        function onAvailabilityChanged() {
            if (root.integration.availability !== "available")
                root.__pendingVolumePercent = -1;
        }
    }

    Integrations.PipewireIntegration { id: nativeIntegration }
}
