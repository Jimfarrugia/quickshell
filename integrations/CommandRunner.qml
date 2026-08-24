import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Validation.mjs" as Validation

Scope {
    id: root

    property list<string> command
    property string workingDirectory: ""
    property int timeoutMs: 5000
    property int termGraceMs: 1000
    property int maxStdoutBytes: 32768
    property int maxStderrBytes: 32768
    property bool expectJson: false
    property string operationId: ""
    readonly property bool running: process.running
    property bool timedOut: false
    property bool cancelled: false
    property double startedAt: 0
    property int sequence: 1
    property string stdoutText: ""
    property string stderrText: ""
    property bool stdoutTruncated: false
    property bool stderrTruncated: false
    property bool awaitingCompletion: false

    signal finished(var result)

    function start() {
        if (process.running || command.length === 0) return false;
        operationId = operationId || `command-${Date.now()}-${sequence++}`;
        timedOut = false;
        cancelled = false;
        stdoutText = "";
        stderrText = "";
        stdoutTruncated = false;
        stderrTruncated = false;
        awaitingCompletion = true;
        startedAt = Date.now();
        process.command = command;
        process.workingDirectory = workingDirectory;
        process.running = true;
        timeoutTimer.restart();
        return true;
    }

    function stop(cancelWasRequested) {
        if (!process.running) return;
        cancelled = cancelWasRequested;
        process.running = false;
        killTimer.restart();
    }

    function cancel() { stop(true); }

    function appendOutput(data, isStdout) {
        const current = isStdout ? stdoutText : stderrText;
        const maximum = isStdout ? maxStdoutBytes : maxStderrBytes;
        const bounded = Validation.truncateUtf8(current + data, maximum);
        if (isStdout) {
            stdoutText = bounded.text;
            stdoutTruncated = stdoutTruncated || bounded.truncated;
        } else {
            stderrText = bounded.text;
            stderrTruncated = stderrTruncated || bounded.truncated;
        }
    }

    function resultFor(exitCode, exitStatus, errorCode) {
        let parsed = null;
        let parseError = null;
        if (expectJson && !timedOut && !cancelled) {
            if (stdoutTruncated) {
                parseError = "structured output exceeded the configured limit";
            } else {
                try { parsed = JSON.parse(stdoutText); }
                catch (error) { parseError = `malformed JSON output: ${error.message}`; }
            }
        }
        return {
            operationId,
            command: Array.prototype.slice.call(command),
            exitCode,
            exitStatus,
            stdout: stdoutText,
            stdoutTruncated,
            stderr: stderrText,
            stderrTruncated,
            timedOut,
            cancelled,
            errorCode: errorCode || null,
            durationMs: Math.max(0, Date.now() - startedAt),
            parsed,
            parseError,
            success: exitCode === 0 && !timedOut && !cancelled && errorCode === null && parseError === null
        };
    }

    function complete(exitCode, exitStatus, errorCode) {
        if (!awaitingCompletion) return;
        awaitingCompletion = false;
        timeoutTimer.stop();
        killTimer.stop();
        const result = resultFor(exitCode, exitStatus, errorCode);
        operationId = "";
        finished(result);
    }

    Process {
        id: process
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root.appendOutput(data, true)
        }
        stderr: SplitParser {
            splitMarker: ""
            onRead: data => root.appendOutput(data, false)
        }
        onExited: (exitCode, exitStatus) => root.complete(exitCode, exitStatus, null)
        onRunningChanged: {
            if (root.awaitingCompletion && !running)
                Qt.callLater(() => root.complete(null, null, "FAILED_TO_START"));
        }
    }

    Timer {
        id: timeoutTimer
        interval: Math.max(1, root.timeoutMs)
        repeat: false
        onTriggered: {
            root.timedOut = true;
            root.stop(false);
        }
    }

    Timer {
        id: killTimer
        interval: Math.max(1, root.termGraceMs)
        repeat: false
        onTriggered: if (process.running) process.signal(9)
    }
}
