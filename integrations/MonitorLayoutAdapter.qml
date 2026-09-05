import QtQuick
import Quickshell
import "../services" as Services

Scope {
    id: root

    property string executable: Quickshell.shellPath("scripts/qe-monitor-layout")
    readonly property bool running: runner.running
    property string action: ""

    signal finished(string action, var result)

    function validateResult(result) {
        if (!result.success) return result;
        const state = result.parsed;
        const validMode = state && ["mirror", "extended", "unknown"].includes(state.mode);
        const validDirection = state && ["left", "up", "right", "down", "unknown"].includes(state.direction);
        const validSelectedMode = state && ["mirror", "extended"].includes(state.selectedMode);
        const validSelectedDirection = state && ["left", "up", "right", "down"].includes(state.selectedDirection);
        const allowedScales = [1, 1.2, 1.25, 1.5, 1.6, 2];
        const validLiveScales = state
            && (state.primaryScale === null || allowedScales.includes(state.primaryScale))
            && (state.secondaryScale === null || allowedScales.includes(state.secondaryScale));
        const validSelectedScales = state
            && allowedScales.includes(state.selectedPrimaryScale)
            && allowedScales.includes(state.selectedSecondaryScale);
        const valid = state && state.version === 2
            && typeof state.available === "boolean"
            && typeof state.message === "string"
            && validMode && validDirection && validSelectedMode && validSelectedDirection
            && validLiveScales && validSelectedScales
            && typeof state.secondaryConnected === "boolean"
            && typeof state.restartRequired === "boolean"
            && typeof state.stateValid === "boolean"
            && typeof state.migrationNeeded === "boolean"
            && typeof state.stateMatchesLive === "boolean";
        if (valid) return result;
        return Object.assign({}, result, {
            success: false,
            parseError: "monitor layout helper returned an invalid document"
        });
    }

    function start(nextAction, mode, direction, primaryScale, secondaryScale) {
        if (runner.running || (nextAction !== "query" && nextAction !== "apply")) return false;
        if (nextAction === "apply" && mode !== "mirror" && mode !== "extended") return false;
        if (nextAction === "apply" && !["left", "up", "right", "down"].includes(direction)) return false;
        if (nextAction === "apply" && ![1, 1.2, 1.25, 1.5, 1.6, 2].includes(primaryScale)) return false;
        if (nextAction === "apply" && ![1, 1.2, 1.25, 1.5, 1.6, 2].includes(secondaryScale)) return false;

        root.action = nextAction;
        runner.command = nextAction === "query"
            ? [root.executable, "query"]
            : [root.executable, "apply", mode, direction,
                primaryScale.toString(), secondaryScale.toString()];
        runner.workingDirectory = Services.PathsService.shellDirectory;
        runner.timeoutMs = 5000;
        runner.termGraceMs = Services.ConfigService.config.commands.termGraceMs;
        runner.maxStdoutBytes = Services.ConfigService.config.commands.maxOutputBytes;
        runner.maxStderrBytes = Services.ConfigService.config.commands.maxOutputBytes;
        runner.expectJson = true;
        runner.operationId = `monitor-layout-${nextAction}-${Date.now()}`;
        return runner.start();
    }

    CommandRunner {
        id: runner
        onFinished: result => root.finished(root.action, root.validateResult(result))
    }
}
