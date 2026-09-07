import QtQuick

QtObject {
    id: root

    property var attempt: null
    property int attemptId: 0
    readonly property bool active: attempt !== null && attempt.active
    readonly property bool responseRequired: attempt !== null && attempt.responseRequired
    readonly property bool responseVisible: attempt !== null && attempt.responseVisible
    readonly property string message: attempt !== null ? attempt.message : ""
    signal completed(string result, int attemptId)

    function start() {
        if (attempt !== null) return false;
        attemptId++;
        const created = attemptFactory.createObject(root, { attemptId: attemptId });
        if (created === null) return false;
        attempt = created;
        created.completed.connect(handleCompleted);
        created.failed.connect(handleFailed);
        if (created.start()) return true;
        created.completed.disconnect(handleCompleted);
        created.failed.disconnect(handleFailed);
        attempt = null;
        created.destroy();
        return false;
    }

    function respond(response) {
        if (attempt !== null && attempt.responseRequired) attempt.respond(response);
    }

    function abort() {
        if (attempt === null) return;
        const aborted = attempt;
        attempt = null;
        aborted.completed.disconnect(handleCompleted);
        aborted.failed.disconnect(handleFailed);
        aborted.abort();
        aborted.destroy();
    }

    function handleCompleted(result, completedAttemptId) {
        if (attempt === null || completedAttemptId !== attempt.attemptId) return;
        const finished = attempt;
        attempt = null;
        finished.completed.disconnect(handleCompleted);
        finished.failed.disconnect(handleFailed);
        finished.destroy();
        completed(result, completedAttemptId);
    }

    function handleFailed(failedAttemptId) {
        handleCompleted("failed", failedAttemptId);
    }

    property Component attemptFactory: Component {
        LockPamAttempt {}
    }
}
