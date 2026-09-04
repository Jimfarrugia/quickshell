import QtQuick
import Quickshell
import "../services" as Services

Scope {
    id: root

    readonly property string executable: Quickshell.shellPath("scripts/qe-defaults")
    readonly property bool running: runner.running
    property string action: ""

    signal finished(string action, var result)

    function start(nextAction) {
        if (runner.running || (nextAction !== "capture" && nextAction !== "restore")) return false;
        root.action = nextAction;
        runner.command = [root.executable, nextAction];
        runner.workingDirectory = Services.PathsService.shellDirectory;
        runner.timeoutMs = 180000;
        runner.termGraceMs = Services.ConfigService.config.commands.termGraceMs;
        runner.maxStdoutBytes = Services.ConfigService.config.commands.maxOutputBytes;
        runner.maxStderrBytes = Services.ConfigService.config.commands.maxOutputBytes;
        runner.operationId = `defaults-${nextAction}-${Date.now()}`;
        return runner.start();
    }

    CommandRunner {
        id: runner
        onFinished: result => root.finished(root.action, result)
    }
}
