pragma Singleton

import QtQml
import Quickshell
import "../integrations" as Integrations

Singleton {
    id: root

    property var adapter: nativeAdapter
    property var lifecycleService: ShellLifecycleService
    property string availability: "unknown"
    property string freshness: "unknown"
    property string selectedMode: "extended"
    property string selectedDirection: "up"
    property string confirmedMode: ""
    property string confirmedDirection: ""
    property real selectedPrimaryScale: 1
    property real selectedSecondaryScale: 1
    property real confirmedPrimaryScale: 0
    property real confirmedSecondaryScale: 0
    property real pendingPrimaryScale: 0
    property real pendingSecondaryScale: 0
    property string operation: "idle"
    property string operationError: ""
    property string statusMessage: "Loading monitor layout..."
    property bool secondaryConnected: false
    property var lastUpdated: null
    readonly property var modes: [
        { id: "mirror", name: "Mirrored" },
        { id: "extended", name: "Extended" }
    ]
    readonly property var directions: [
        { id: "left", name: "Left" },
        { id: "up", name: "Up" },
        { id: "right", name: "Right" },
        { id: "down", name: "Down" }
    ]
    readonly property var scaleOptions: [1, 1.2, 1.25, 1.5, 1.6, 2]

    function refresh() {
        if (operation === "pending" || adapter.running) return false;
        availability = "unknown";
        freshness = "unknown";
        statusMessage = "Loading monitor layout...";
        if (!adapter.start("query", "", "", 0, 0)) {
            availability = "unavailable";
            statusMessage = "Could not inspect the monitor layout";
            return false;
        }
        return true;
    }

    function request(nextMode, nextDirection, nextPrimaryScale, nextSecondaryScale) {
        const requestedDirection = nextDirection || selectedDirection;
        if (operation === "pending"
                || (availability !== "available" && availability !== "degraded")) return false;
        if (!scaleOptions.includes(nextPrimaryScale) || !scaleOptions.includes(nextSecondaryScale))
            return false;
        operation = "pending";
        pendingPrimaryScale = nextPrimaryScale;
        pendingSecondaryScale = nextSecondaryScale;
        operationError = "";
        statusMessage = "Applying monitor layout...";
        if (!adapter.start("apply", nextMode, requestedDirection,
                nextPrimaryScale, nextSecondaryScale)) {
            operation = "failed";
            operationError = "Could not start the monitor layout operation";
            statusMessage = operationError;
            return false;
        }
        return true;
    }

    function requestMode(nextMode) {
        return request(nextMode, selectedDirection, selectedPrimaryScale, selectedSecondaryScale);
    }
    function requestDirection(nextDirection) {
        return request("extended", nextDirection, selectedPrimaryScale, selectedSecondaryScale);
    }
    function requestPrimaryScale(nextScale) {
        return request(selectedMode, selectedDirection, nextScale, selectedSecondaryScale);
    }
    function requestSecondaryScale(nextScale) {
        return request(selectedMode, selectedDirection, selectedPrimaryScale, nextScale);
    }

    function complete(action, result) {
        lastUpdated = new Date();
        if (!result.success || !result.parsed || result.parsed.version !== 2) {
            if (action === "query") availability = "unavailable";
            else operation = "failed";
            pendingPrimaryScale = 0;
            pendingSecondaryScale = 0;
            freshness = "unknown";
            operationError = result.timedOut
                ? "Monitor layout operation timed out"
                : (result.stderr && result.stderr.trim().length > 0
                    ? result.stderr.trim().slice(0, 180)
                    : (result.parseError || "Monitor layout operation failed"));
            statusMessage = operationError;
            return;
        }

        const state = result.parsed;
        availability = state.available
            ? (state.stateValid && state.stateMatchesLive ? "available" : "degraded")
            : "unavailable";
        freshness = state.available ? "current" : "unknown";
        selectedMode = state.selectedMode;
        selectedDirection = state.selectedDirection;
        selectedPrimaryScale = state.selectedPrimaryScale;
        selectedSecondaryScale = state.selectedSecondaryScale;
        confirmedMode = state.mode === "mirror" || state.mode === "extended"
            ? state.mode : "";
        confirmedDirection = ["left", "up", "right", "down"].includes(state.direction)
            ? state.direction : "";
        confirmedPrimaryScale = state.primaryScale === null ? 0 : state.primaryScale;
        confirmedSecondaryScale = state.secondaryScale === null ? 0 : state.secondaryScale;
        secondaryConnected = state.secondaryConnected;
        statusMessage = state.message || (state.available ? "Ready" : "Monitor layout unavailable");
        operationError = "";
        pendingPrimaryScale = 0;
        pendingSecondaryScale = 0;
        if (action === "query") {
            operation = "idle";
        } else if (action === "apply") {
            operation = "succeeded";
            if (state.restartRequired) Qt.callLater(() => {
                statusMessage = "Restarting QE for the extended output...";
                if (!lifecycleService.restart()) {
                    operation = "failed";
                    operationError = lifecycleService.restartError || "Could not restart QE";
                    statusMessage = operationError;
                }
            });
        }
    }

    Integrations.MonitorLayoutAdapter {
        id: nativeAdapter
        onFinished: (action, result) => root.complete(action, result)
    }

    Connections {
        target: root.lifecycleService
        function onRestartErrorChanged() {
            if (!root.lifecycleService.restartError) return;
            root.operation = "failed";
            root.operationError = root.lifecycleService.restartError;
            root.statusMessage = root.operationError;
        }
    }

}
