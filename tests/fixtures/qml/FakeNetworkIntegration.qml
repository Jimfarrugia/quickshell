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
    property bool wifiEnabled: true
    property bool wifiHardwareEnabled: true
    property bool scanning: false
    property var wifiDevice: null
    property var calls: []
    function setWifiEnabled(value) { wifiEnabled = value; return true; }
    function setScanning(value) { scanning = value; return true; }
    function connect(network, settings) { calls = calls.concat(["connect"]); return true; }
    function connectWithPsk(network, psk) { calls = calls.concat(["psk"]); return true; }
    function disconnect(network) { calls = calls.concat(["disconnect"]); return true; }
    function forget(network) { calls = calls.concat(["forget"]); return true; }
}
