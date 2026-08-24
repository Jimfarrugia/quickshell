pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property string qeVersion: "0.1.0-phase1"
    readonly property string quickshellVersion: "0.3.0"
    readonly property int configSchemaVersion: 1
    readonly property int themeSchemaVersion: 1
    readonly property int stateSchemaVersion: 1
    property int maximumErrors: 100
    property var errors: []

    function report(code, boundary, summary, detail, retryable, operationId) {
        const error = {
            code: code,
            boundary: boundary,
            summary: summary,
            detail: detail || "",
            timestamp: new Date().toISOString(),
            retryable: retryable === true,
            operationId: operationId || null
        };
        errors = errors.concat([error]).slice(-maximumErrors);
        console.warn(`[QE][${boundary}][${code}] ${summary}${detail ? `: ${detail}` : ""}`);
        return error;
    }

    function clear() { errors = []; }
}
