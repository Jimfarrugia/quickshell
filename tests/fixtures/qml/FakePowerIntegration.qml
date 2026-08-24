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
    property string iconName: ""
}
