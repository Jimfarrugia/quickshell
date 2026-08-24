import QtQuick

QtObject {
    property string availability: "unavailable"
    property string freshness: "unknown"
    property var lastUpdated: null
    property var lastError: null
    property string operation: "idle"
    property bool present: false
    property int percentage: 0
    property bool charging: false
    property bool fullyCharged: false
    property int timeToEmptySeconds: 16200
    property int timeToFullSeconds: 0
    property string iconName: ""
}
