pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var activeItem: null
    property var queue: []
    property var pendingOperations: ({})
    property bool primed: false
    property string lastNetworkState: ""
    property string lastBluetoothState: ""
    property string lastBatteryState: ""

    function duration() {
        return ConfigService.config.osd.durationMs;
    }

    function maxQueue() {
        return ConfigService.config.osd.maxQueue;
    }

    function showItem(item) {
        if (!item || typeof item !== "object") return false;
        const normalized = {
            title: typeof item.title === "string" ? item.title.slice(0, 128) : "QE",
            detail: typeof item.detail === "string" ? item.detail.slice(0, 512) : "",
            value: Number.isFinite(Number(item.value)) ? Math.max(0, Math.min(200, Number(item.value))) : -1,
            icon: typeof item.icon === "string" ? item.icon.slice(0, 64) : "info",
            state: ["pending", "confirmed", "failed"].indexOf(item.state) >= 0 ? item.state : "confirmed",
            replacementKey: typeof item.replacementKey === "string" ? item.replacementKey : "",
            priority: Number.isFinite(Number(item.priority)) ? Number(item.priority) : 0,
            duration: Number.isFinite(Number(item.duration)) ? Math.max(500, Math.min(10000, Number(item.duration))) : root.duration()
        };

        if (normalized.replacementKey.length > 0 && root.activeItem
                && root.activeItem.replacementKey === normalized.replacementKey) {
            root.activeItem = normalized;
            expiry.restart();
            return true;
        }

        let next = root.queue.slice();
        if (normalized.replacementKey.length > 0) {
            const index = next.findIndex(entry => entry.replacementKey === normalized.replacementKey);
            if (index >= 0) next[index] = normalized;
            else next.push(normalized);
        } else {
            next.push(normalized);
        }
        next.sort((left, right) => right.priority - left.priority);
        root.queue = next.slice(0, root.maxQueue());
        if (root.activeItem === null) root.advance();
        return true;
    }

    function advance() {
        if (root.queue.length === 0) {
            root.activeItem = null;
            expiry.stop();
            return;
        }
        root.activeItem = root.queue[0];
        root.queue = root.queue.slice(1);
        expiry.interval = root.activeItem.duration;
        expiry.restart();
    }

    function clear() {
        root.queue = [];
        root.activeItem = null;
        root.pendingOperations = {};
        expiry.stop();
    }

    function trackOperation(key) {
        const next = Object.assign({}, root.pendingOperations);
        next[key] = true;
        root.pendingOperations = next;
    }

    function resolveOperation(key, item) {
        if (!root.pendingOperations[key]) return;
        const next = Object.assign({}, root.pendingOperations);
        delete next[key];
        root.pendingOperations = next;
        root.showItem(item);
    }

    function networkChanged() {
        if (!root.primed) return;
        const state = `${NetworkService.connectionType}:${NetworkService.connectivity}:${NetworkService.ssid}`;
        if (state === root.lastNetworkState) return;
        root.lastNetworkState = state;
        root.showItem({ title: "Network", detail: NetworkService.summary, icon: "network_check", priority: 1, replacementKey: "network" });
    }

    function bluetoothChanged() {
        if (!root.primed) return;
        const state = `${BluetoothService.enabled}:${BluetoothService.connectedSummary}`;
        if (state === root.lastBluetoothState) return;
        root.lastBluetoothState = state;
        root.showItem({ title: "Bluetooth", detail: BluetoothService.connectedSummary || (BluetoothService.enabled ? "No devices connected" : "Disabled"), icon: "bluetooth", priority: 1, replacementKey: "bluetooth" });
    }

    function batteryChanged() {
        if (!root.primed || !PowerService.present) return;
        const level = PowerService.percentage <= 15 ? "critical" : (PowerService.percentage <= 24 ? "low" : "normal");
        const fullyCharged = PowerService.fullyCharged && PowerService.percentage >= 99;
        const state = `${PowerService.charging}:${fullyCharged}:${level}`;
        if (state === root.lastBatteryState) return;
        root.lastBatteryState = state;
        root.showItem({
            title: "Battery",
            detail: fullyCharged ? "Fully charged" : (PowerService.charging ? "Charging" : `${PowerService.percentage}% remaining`),
            value: PowerService.percentage,
            icon: PowerService.charging ? "battery_charging_full" : "battery_std",
            priority: level === "critical" ? 3 : 1,
            replacementKey: "battery",
            state: "confirmed"
        });
    }

    function prime() {
        root.lastNetworkState = `${NetworkService.connectionType}:${NetworkService.connectivity}:${NetworkService.ssid}`;
        root.lastBluetoothState = `${BluetoothService.enabled}:${BluetoothService.connectedSummary}`;
        root.lastBatteryState = `${PowerService.charging}:${PowerService.fullyCharged}:${PowerService.percentage <= 15 ? "critical" : (PowerService.percentage <= 24 ? "low" : "normal")}`;
        root.primed = true;
    }

    Timer {
        id: expiry
        repeat: false
        onTriggered: root.advance()
    }

    Connections {
        target: AudioService
        function onOperationChanged() {
            if (AudioService.operation === "failed")
                root.resolveOperation("audio", { title: "Audio", detail: "Volume operation failed", icon: "volume_off", state: "failed", replacementKey: "audio" });
            else if (AudioService.operation === "idle")
                root.resolveOperation("audio", { title: "Volume", detail: AudioService.muted ? "Muted" : `${AudioService.volumePercent}%`, value: AudioService.volumePercent, icon: AudioService.muted ? "volume_off" : "volume_up", state: "confirmed", replacementKey: "audio" });
        }
    }

    Connections {
        target: BrightnessService
        function onOperationChanged() {
            if (BrightnessService.operation === "failed")
                root.resolveOperation("brightness", { title: "Brightness", detail: "Brightness operation failed", icon: "brightness_low", state: "failed", replacementKey: "brightness" });
            else if (BrightnessService.operation === "idle")
                root.resolveOperation("brightness", { title: "Brightness", detail: `${BrightnessService.confirmedPercent}%`, value: BrightnessService.confirmedPercent, icon: "brightness_medium", state: "confirmed", replacementKey: "brightness" });
        }
    }

    Connections {
        target: KeyboardBrightnessService
        function onOperationChanged() {
            if (KeyboardBrightnessService.operation === "failed")
                root.resolveOperation("keyboard-brightness", { title: "Keyboard brightness", detail: "Operation failed", icon: "keyboard", state: "failed", replacementKey: "keyboard-brightness" });
            else if (KeyboardBrightnessService.operation === "idle")
                root.resolveOperation("keyboard-brightness", { title: "Keyboard brightness", detail: `${KeyboardBrightnessService.confirmedPercent}%`, value: KeyboardBrightnessService.confirmedPercent, icon: "keyboard", state: "confirmed", replacementKey: "keyboard-brightness" });
        }
    }

    Connections {
        target: NetworkService
        function onConnectivityChanged() { root.networkChanged(); }
        function onConnectionTypeChanged() { root.networkChanged(); }
        function onSsidChanged() { root.networkChanged(); }
    }

    Connections {
        target: BluetoothService
        function onEnabledChanged() { root.bluetoothChanged(); }
        function onConnectedSummaryChanged() { root.bluetoothChanged(); }
    }

    Connections {
        target: PowerService
        function onPercentageChanged() { root.batteryChanged(); }
        function onChargingChanged() { root.batteryChanged(); }
        function onFullyChargedChanged() { root.batteryChanged(); }
    }

    Connections {
        target: ConfigService
        function onConfigChanged() {
            if (!ConfigService.config.osd.enabled) root.clear();
        }
    }

    Component.onCompleted: Qt.callLater(root.prime)
}
