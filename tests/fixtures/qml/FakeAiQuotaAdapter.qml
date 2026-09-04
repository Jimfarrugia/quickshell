import QtQml

QtObject {
    property bool active: false
    property bool busy: false
    property int refreshCalls: 0
    property QtObject runner: QtObject { property bool running: false }
    signal refreshed(var result)
    function refresh() { refreshCalls++; return active; }
    function publish(document) { refreshed({ ok: true, data: document }); }
}
