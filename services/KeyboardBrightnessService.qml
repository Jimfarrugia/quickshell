pragma Singleton

import QtQuick
import Quickshell
import "../utils/Brightness.mjs" as Brightness
import "../integrations" as Integrations

// Keyboard LEDs use the same bounded helper contract as the screen backlight,
// but are discovered from the leds class and never assume a device name.
Singleton {
    id: root

    property var integration: nativeIntegration
    readonly property string availability: integration.availability
    readonly property string freshness: integration.freshness
    readonly property var lastUpdated: integration.lastUpdated
    readonly property var lastError: integration.lastError
    readonly property string operation: integration.operation
    readonly property int confirmedPercent: __confirmedPercent
    readonly property int pendingPercent: __pendingPercent

    property int __confirmedPercent: 0
    property int __pendingPercent: -1

    Integrations.BrightnessIntegration {
        id: nativeIntegration
        deviceClass: "leds"
        active: true
    }

    function setBrightness(percent) {
        if (availability !== "available") return false;
        const clamped = Brightness.clampPercent(percent);
        __pendingPercent = clamped;
        if (!integration.setBrightness(clamped)) {
            __pendingPercent = -1;
            return false;
        }
        return true;
    }

    function stepBrightness(delta) {
        const base = pendingPercent >= 0 ? pendingPercent : confirmedPercent;
        return setBrightness(base + delta);
    }

    function applyRead(result) {
        if (!result || !result.ok) return;
        __confirmedPercent = result.percent;
        if (__pendingPercent >= 0 && Math.abs(result.percent - __pendingPercent) <= 1)
            __pendingPercent = -1;
    }

    function applySet(result) {
        if (!result || !result.ok) {
            __pendingPercent = -1;
            return;
        }
        applyRead(result);
        if (__pendingPercent >= 0) __pendingPercent = -1;
    }

    Connections {
        target: root.integration
        function onRead(result) { root.applyRead(result); }
        function onSetFinished(result) { root.applySet(result); }
        function onAvailabilityChanged() {
            if (root.integration.availability !== "available") root.__pendingPercent = -1;
        }
    }
}
