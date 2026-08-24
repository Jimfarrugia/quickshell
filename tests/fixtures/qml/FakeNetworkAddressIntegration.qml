import QtQuick

QtObject {
    property string ipv4Address: ""
    property string availability: "unknown"
    property string freshness: "unknown"
    property var lastUpdated: null
    property var lastError: null
    property string operation: "idle"

    function refresh(interfaceName) {
        ipv4Address = interfaceName === "fixture0" ? "192.0.2.10"
            : (interfaceName === "wlan0" ? "198.51.100.5" : "");
        availability = ipv4Address ? "available" : "degraded";
        freshness = "current";
        operation = "succeeded";
        lastUpdated = new Date();
        return true;
    }

    function clear() {
        ipv4Address = "";
        availability = "unknown";
        freshness = "unknown";
        operation = "idle";
        lastError = null;
    }
}
