import QtQml

QtObject {
    property bool running: false
    property var command: []
    signal finished(var result)
    function start() { running = true; return true; }
    function cancel() { running = false; finished({ cancelled: true }); }
    function finish(result) { running = false; finished(result); }
}
