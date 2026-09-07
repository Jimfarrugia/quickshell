import QtQml

QtObject {
    property bool running: false
    property var command: []
    property bool delayCancellation: false
    property bool cancelRequested: false
    property bool failNextStart: false
    property int startCalls: 0
    property int cancelCalls: 0
    signal finished(var result)
    function start() {
        startCalls++;
        if (failNextStart) {
            failNextStart = false;
            return false;
        }
        running = true;
        return true;
    }
    function cancel() {
        cancelCalls++;
        cancelRequested = true;
        running = false;
        if (!delayCancellation) completeCancellation();
    }
    function completeCancellation() {
        if (!cancelRequested) return;
        cancelRequested = false;
        finished({ cancelled: true });
    }
    function finish(result) { running = false; finished(result); }
}
