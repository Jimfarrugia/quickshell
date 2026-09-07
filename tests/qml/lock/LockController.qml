import QtQuick

QtObject {
    id: root

    property var sessionLock: null
    property var authenticator: null
    property bool prerequisitesReady: false
    property int retryDelayMs: 1000
    property int acquisitionTimeoutMs: 3000
    property int authenticationTimeoutMs: 300000
    property int maxFailures: 5
    property int failureCount: 0
    property int activeAttemptId: 0
    property bool authenticationSubmitted: false
    readonly property bool secure: sessionLock !== null && sessionLock.secure
    readonly property bool responseRequired: authenticator !== null && authenticator.responseRequired
    readonly property bool responseVisible: authenticator !== null && authenticator.responseVisible
    readonly property string message: authenticator !== null ? authenticator.message : ""
    property string state: "idle"

    function begin() {
        if (!prerequisitesReady || sessionLock === null || authenticator === null
                || state !== "idle")
            return false;
        state = "acquiring";
        acquisitionTimer.restart();
        sessionLock.locked = true;
        if (!sessionLock.locked) {
            state = "acquisitionFailed";
            return false;
        }
        if (sessionLock.secure) {
            acquisitionTimer.stop();
            startAuthentication();
        }
        return true;
    }

    function startAuthentication() {
        if (!secure || state === "unlocked" || state === "acquisitionFailed"
                || state === "recoveryRequired")
            return false;
        authenticationSubmitted = false;
        state = "startingAuthentication";
        if (!authenticator.start()) {
            scheduleRetry();
            return false;
        }
        activeAttemptId = authenticator.attemptId;
        state = authenticator.responseRequired ? "awaitingInput" : "authenticating";
        authenticationTimer.restart();
        return true;
    }

    function submit(response) {
        if (!secure || state !== "awaitingInput" || !responseRequired || response.length === 0)
            return false;
        state = "authenticating";
        authenticationSubmitted = true;
        authenticator.respond(response);
        return true;
    }

    function cancelAuthentication() {
        if (!secure || authenticator === null
                || (state !== "awaitingInput" && state !== "authenticating"))
            return false;
        authenticator.abort();
        authenticationTimer.stop();
        return startAuthentication();
    }

    function handleAuthenticationResult(result, attemptId) {
        if (!secure || attemptId !== activeAttemptId) return;
        if (result === "success" && state !== "authenticating") return;
        if (result !== "success" && state !== "startingAuthentication"
                && state !== "awaitingInput" && state !== "authenticating")
            return;
        authenticationTimer.stop();
        authenticator.abort();
        authenticationSubmitted = false;
        if (result === "success") {
            failureCount = 0;
            state = "unlocking";
            sessionLock.locked = false;
            state = "unlocked";
            return;
        }
        scheduleRetry();
    }

    function scheduleRetry() {
        authenticationTimer.stop();
        failureCount++;
        if (failureCount >= maxFailures) {
            state = "recoveryRequired";
            return;
        }
        state = "retryDelay";
        retryTimer.restart();
    }

    function failAcquisition() {
        if (state !== "acquiring" || secure) return;
        state = "acquisitionFailed";
        sessionLock.locked = false;
    }

    property Timer retryTimer: Timer {
        interval: root.retryDelayMs
        repeat: false
        onTriggered: root.startAuthentication()
    }

    property Timer acquisitionTimer: Timer {
        interval: root.acquisitionTimeoutMs
        repeat: false
        onTriggered: root.failAcquisition()
    }

    property Timer authenticationTimer: Timer {
        interval: root.authenticationTimeoutMs
        repeat: false
        onTriggered: root.handleAuthenticationResult("failed", root.activeAttemptId)
    }

    property Connections sessionLockConnections: Connections {
        target: root.sessionLock
        ignoreUnknownSignals: true

        function onSecureChanged() {
            if (root.sessionLock.secure && root.state === "acquiring") {
                root.acquisitionTimer.stop();
                root.startAuthentication();
            }
        }

        function onLockedChanged() {
            if (!root.sessionLock.locked && root.state !== "idle"
                    && root.state !== "unlocking" && root.state !== "unlocked") {
                root.authenticator.abort();
                root.retryTimer.stop();
                root.acquisitionTimer.stop();
                root.authenticationTimer.stop();
                root.state = "acquisitionFailed";
            }
        }
    }

    property Connections authenticatorConnections: Connections {
        target: root.authenticator
        ignoreUnknownSignals: true

        function onResponseRequiredChanged() {
            if (root.secure && root.authenticator.responseRequired
                    && (root.state === "startingAuthentication"
                        || root.state === "authenticating"))
                root.state = "awaitingInput";
        }

        function onCompleted(result, attemptId) {
            root.handleAuthenticationResult(result, attemptId);
        }
    }
}
