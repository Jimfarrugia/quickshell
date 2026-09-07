import QtQml

QtObject {
    property bool active: false
    property bool busy: false
    property int refreshCalls: 0
    property var requestReasons: []
    property QtObject runner: QtObject { property bool running: false }
    signal refreshed(var result)
    signal resumed()
    function requestCycle(reason) {
        requestReasons = requestReasons.concat([reason]);
        if (reason === "manual") refreshCalls++;
        return active;
    }
    function refresh() { return requestCycle("manual"); }
    function publish(document) { refreshed({ ok: true, data: document }); }
}
