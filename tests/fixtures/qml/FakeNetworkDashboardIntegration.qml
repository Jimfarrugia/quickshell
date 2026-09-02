import QtQuick
import Quickshell.Networking

Item {
    id: root
    property string availability: "available"
    property string freshness: "current"
    property var lastUpdated: new Date()
    property var lastError: null
    property string operation: "idle"
    property string connectivity: "full"
    property string summary: "Online"
    property string connectionType: "wifi"
    property string ssid: "Office"
    property int signalStrength: 82
    property int linkSpeed: 1000
    property string wiredInterface: ""
    property string interfaceName: "wlan0"
    property bool wifiEnabled: true
    property bool wifiHardwareEnabled: true
    property bool scanning: false
    property var calls: []
    property var scanCalls: []
    property var recordedPsks: []
    property var selectedDevice: fakeDevice
    property bool selectedDeviceConnected: fakeDevice.connected
    property string selectedDeviceLabel: "wlan0"
    property var wifiDevice: fakeDevice
    readonly property var fixtureWifiDevice: fakeDevice
    property var activeWifiDevice: fakeDevice
    property bool connectShouldAccept: true
    property bool daemonLost: false
    function setWifiEnabled(value) { wifiEnabled = value; return true; }
    function setScanning(value) {
        if (!wifiDevice) return false;
        scanning = value;
        scanCalls = scanCalls.concat([value ? "start" : "stop"]);
        wifiDevice.scannerEnabled = value;
        return true;
    }
    function connect(network, settings) { calls = calls.concat(["connect"]); return connectShouldAccept; }
    function connectWithPsk(network, psk) { calls = calls.concat(["psk"]); return connectShouldAccept; }
    function disconnect(network) { calls = calls.concat(["disconnect"]); return true; }
    function forget(network, settings) { calls = calls.concat([settings ? "forget-profile" : "forget"]); return true; }
    function loseDaemon() { daemonLost = true; availability = "unavailable"; freshness = "unknown"; wifiDevice = null; }
    function recoverDaemon() { daemonLost = false; wifiDevice = fakeDevice; availability = "available"; freshness = "current"; }

    QtObject { id: fakeDevice; property int type: DeviceType.Wifi; property bool connected: false; property bool scannerEnabled: false; property var networks: fakeNetworks; property string name: "wlan0"; property string address: "00:11:22:33:44:55" }
    QtObject { id: fakeNetworks; property var values: [fakeNetwork, fakeUnprofiled, fakeUnsupported, fakeEap, fakeOwe, fakeWep, fakeUnknown, fakeMalformed] }
    QtObject {
        id: fakeNetwork
        signal connectionFailed(int reason)
        property string name: "Office"
        property bool connected: false
        property bool known: true
        property bool stateChanging: false
        property int security: 3
        property real signalStrength: 0.82
        property var nmSettings: [profileA, profileB]
        function connect() {}
        function connectWithSettings(settings) {}
        function connectWithPsk(psk) {}
        function disconnect() {}
        function forget() {}
        function failAuthentication() { connectionFailed(4); }
    }
    QtObject {
        id: fakeUnprofiled
        signal connectionFailed(int reason)
        property string name: "Office"
        property bool connected: false
        property bool known: false
        property bool stateChanging: false
        property int security: 10
        property real signalStrength: 0.65
        property var nmSettings: []
    }
    QtObject {
        id: fakeUnsupported
        signal connectionFailed(int reason)
        property string name: "Enterprise"
        property bool connected: false
        property bool known: true
        property bool stateChanging: false
        property int security: 2
        property real signalStrength: 0.5
         property var nmSettings: [profileEap]
    }
    QtObject { id: profileA; function read() { return {connection: {id: "Office", uuid: "uuid-a"}}; } }
    QtObject { id: profileB; function read() { return {connection: {id: "Office (guest profile)", uuid: "uuid-b"}}; } }
    QtObject { id: profileEap; function read() { return {connection: {id: "Enterprise", uuid: "uuid-eap"}}; } }
    QtObject { id: fakeEap; signal connectionFailed(int reason); property string name: "EAP"; property bool connected: false; property bool known: true; property bool stateChanging: false; property int security: WifiSecurityType.WpaEap; property real signalStrength: 0.45; property var nmSettings: [profileEap] }
    QtObject { id: fakeOwe; signal connectionFailed(int reason); property string name: "OWE"; property bool connected: false; property bool known: true; property bool stateChanging: false; property int security: WifiSecurityType.Owe; property real signalStrength: 0.4; property var nmSettings: [] }
    QtObject { id: fakeWep; signal connectionFailed(int reason); property string name: "WEP"; property bool connected: false; property bool known: true; property bool stateChanging: false; property int security: WifiSecurityType.StaticWep; property real signalStrength: 0.3; property var nmSettings: [] }
    QtObject { id: fakeUnknown; signal connectionFailed(int reason); property string name: "Unknown"; property bool connected: false; property bool known: false; property bool stateChanging: false; property int security: WifiSecurityType.Unknown; property real signalStrength: 0.2; property var nmSettings: [] }
    QtObject { id: fakeMalformed; signal connectionFailed(int reason); property string name: "Malformed"; property bool connected: false; property bool known: true; property bool stateChanging: false; property int security: WifiSecurityType.Wpa2Psk; property real signalStrength: 0.1; property var nmSettings: [profileMalformed] }
    QtObject { id: profileMalformed; function read() { throw new Error("fixture profile is malformed"); } }
}
