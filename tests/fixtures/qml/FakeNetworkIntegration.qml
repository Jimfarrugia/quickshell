import QtQuick

QtObject {
    property string availability: "available"
    property string freshness: "current"
    property var lastUpdated: new Date()
    property var lastError: null
    property string operation: "idle"
    property string connectivity: "full"
    property string summary: "Online"
    property string connectionType: "wifi"
    property string ssid: "Fixture WiFi"
    property int signalStrength: 73
    property string wiredInterface: ""
    property string interfaceName: connectionType === "wifi" ? "wlan0" : wiredInterface
}
