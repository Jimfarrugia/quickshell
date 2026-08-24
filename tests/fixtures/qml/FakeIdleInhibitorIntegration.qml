import QtQuick

QtObject {
    property var ownerWindow: null
    property bool requested: false
    readonly property string availability: ownerWindow ? "available" : "unavailable"
    readonly property string freshness: ownerWindow ? "current" : "unknown"
    property var lastUpdated: null
    property var lastError: null
    property string operation: "idle"
}
