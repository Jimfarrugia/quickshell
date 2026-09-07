import QtQuick
import Quickshell
import "lock" as Lock

ShellRoot {
    id: root

    property int stage: 0

    QtObject {
        id: fakeSessionLock
        property bool locked: false
        property bool secure: false
    }

    QtObject {
        id: fakeAuthenticator
        property bool active: false
        property bool responseRequired: false
        property bool responseVisible: false
        property string message: ""
        property int starts: 0
        property int responses: 0
        property int aborts: 0
        property int attemptId: 0
        signal completed(string result, int attemptId)

        function start() {
            starts++;
            attemptId++;
            active = true;
            responseRequired = true;
            return true;
        }

        function respond(response) {
            responses++;
            responseRequired = false;
        }

        function abort() {
            aborts++;
            active = false;
            responseRequired = false;
        }
    }

    Lock.LockController {
        id: controller
        sessionLock: fakeSessionLock
        authenticator: fakeAuthenticator
        retryDelayMs: 1
        acquisitionTimeoutMs: 100
        maxFailures: 3
    }

    QtObject {
        id: timeoutSessionLock
        property bool locked: false
        property bool secure: false
    }

    QtObject {
        id: unavailableAuthenticator
        property bool active: false
        property bool responseRequired: false
        property bool responseVisible: false
        property string message: ""
        property int attemptId: 0
        signal completed(string result, int attemptId)
        function start() { attemptId++; return false; }
        function respond(response) {}
        function abort() {}
    }

    Lock.LockController {
        id: timeoutController
        sessionLock: timeoutSessionLock
        authenticator: fakeAuthenticator
        prerequisitesReady: true
        acquisitionTimeoutMs: 1
    }

    QtObject {
        id: unavailableSessionLock
        property bool locked: false
        property bool secure: true
    }

    Lock.LockController {
        id: unavailableController
        sessionLock: unavailableSessionLock
        authenticator: unavailableAuthenticator
        prerequisitesReady: true
        retryDelayMs: 1
        acquisitionTimeoutMs: 100
        maxFailures: 2
    }

    QtObject {
        id: helperLossSessionLock
        property bool locked: false
        property bool secure: true
    }

    QtObject {
        id: helperLossAuthenticator
        property bool active: false
        property bool responseRequired: false
        property bool responseVisible: false
        property string message: ""
        property int attemptId: 0
        property int starts: 0
        signal completed(string result, int attemptId)
        function start() {
            starts++;
            attemptId++;
            active = true;
            responseRequired = true;
            return true;
        }
        function respond(response) { responseRequired = false; }
        function abort() { active = false; responseRequired = false; }
    }

    Lock.LockController {
        id: helperLossController
        sessionLock: helperLossSessionLock
        authenticator: helperLossAuthenticator
        prerequisitesReady: true
        retryDelayMs: 1
        acquisitionTimeoutMs: 100
    }

    QtObject {
        id: hungSessionLock
        property bool locked: false
        property bool secure: true
    }

    QtObject {
        id: hungAuthenticator
        property bool active: false
        property bool responseRequired: false
        property bool responseVisible: false
        property string message: ""
        property int attemptId: 0
        property int starts: 0
        signal completed(string result, int attemptId)
        function start() {
            starts++;
            attemptId++;
            active = true;
            responseRequired = true;
            return true;
        }
        function respond(response) { responseRequired = false; }
        function abort() { active = false; responseRequired = false; }
    }

    Lock.LockController {
        id: hungController
        sessionLock: hungSessionLock
        authenticator: hungAuthenticator
        prerequisitesReady: true
        retryDelayMs: 1
        authenticationTimeoutMs: 1
        acquisitionTimeoutMs: 100
        maxFailures: 2
    }

    function fail(message) {
        console.error(`LOCK_CONTROLLER_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function runChecks() {
        if (!timeoutController.begin())
            return fail("acquisition-timeout fixture could not begin");
        if (!unavailableController.begin())
            return fail("unavailable-authenticator fixture could not begin");
        if (!helperLossController.begin()
                || helperLossController.state !== "awaitingInput")
            return fail("helper-loss fixture could not begin authentication");
        helperLossAuthenticator.completed("failed", helperLossAuthenticator.attemptId);
        if (helperLossController.state !== "retryDelay" || !helperLossSessionLock.locked)
            return fail("PAM helper loss while awaiting input did not remain locked and retry");
        if (!hungController.begin() || hungController.state !== "awaitingInput")
            return fail("hung-authentication fixture could not begin");

        if (controller.begin() || fakeSessionLock.locked)
            return fail("lock acquisition began before lock-safe inputs were ready");

        controller.prerequisitesReady = true;
        if (!controller.begin() || !fakeSessionLock.locked || controller.state !== "acquiring")
            return fail("ready controller did not request the session lock");

        if (controller.submit("password") || fakeAuthenticator.responses !== 0)
            return fail("authentication was accepted before compositor secure");

        fakeSessionLock.secure = true;
        if (controller.state !== "awaitingInput" || fakeAuthenticator.starts !== 1)
            return fail("secure confirmation did not start authentication");

        fakeAuthenticator.completed("success", fakeAuthenticator.attemptId);
        if (!fakeSessionLock.locked || controller.state !== "awaitingInput")
            return fail("PAM success outside an active submission released the lock");

        if (controller.submit("") || fakeAuthenticator.responses !== 0)
            return fail("empty authentication response was submitted");

        if (!controller.submit("wrong") || controller.state !== "authenticating"
                || fakeAuthenticator.responses !== 1)
            return fail("non-empty authentication response was not submitted");

        fakeAuthenticator.completed("failed", fakeAuthenticator.attemptId);
        if (!fakeSessionLock.locked || controller.state !== "retryDelay")
            return fail("failed authentication released the session lock");

        stage = 1;
        retryTimer.start();
    }

    Timer {
        id: retryTimer
        interval: 10
        repeat: false
        onTriggered: {
            if (timeoutController.state !== "acquisitionFailed" || timeoutSessionLock.locked)
                return root.fail("missing secure confirmation did not fail acquisition by deadline");
            if (unavailableController.state !== "recoveryRequired"
                    || !unavailableSessionLock.locked)
                return root.fail("repeated PAM startup failure did not stop in locked recovery state");
            if (helperLossController.state !== "awaitingInput"
                    || helperLossAuthenticator.starts !== 2)
                return root.fail("PAM helper loss did not restore a usable authentication prompt");
            if (hungController.state !== "recoveryRequired" || !hungSessionLock.locked
                    || hungAuthenticator.starts !== 2)
                return root.fail("non-completing PAM attempts were not bounded in locked recovery");
            if (root.stage !== 1 || controller.state !== "awaitingInput"
                    || fakeAuthenticator.starts !== 2)
                return root.fail("failed authentication did not restart after a bounded delay");

            controller.cancelAuthentication();
            if (!fakeSessionLock.locked || controller.state !== "awaitingInput"
                    || fakeAuthenticator.starts !== 3)
                return root.fail("cancelled authentication did not remain locked and restart");

            controller.submit("correct");
            fakeAuthenticator.completed("success", fakeAuthenticator.attemptId - 1);
            if (!fakeSessionLock.locked || controller.state !== "authenticating")
                return root.fail("stale PAM success released the session lock");
            fakeAuthenticator.completed("success", fakeAuthenticator.attemptId);
            if (fakeSessionLock.locked || controller.state !== "unlocked")
                return root.fail("successful secure authentication did not release the lock");

            console.log("LOCK_CONTROLLER_TEST_PASSED");
            Qt.quit();
        }
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail("test timed out")
    }

    Component.onCompleted: Qt.callLater(runChecks)
}
