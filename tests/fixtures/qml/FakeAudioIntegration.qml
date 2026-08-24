import QtQuick

QtObject {
    property string availability: "available"
    property string freshness: "current"
    property var lastUpdated: new Date()
    property var lastError: null
    property string operation: "idle"
    property int volumePercent: 42
    property bool muted: false
    property string description: "Fixture sink"
    property int setCallCount: 0
    property int lastSetPercent: -1
    property bool acceptSet: true

    function setVolume(percent) {
        setCallCount++;
        lastSetPercent = percent;
        return acceptSet;
    }
}
