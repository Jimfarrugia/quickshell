import QtQuick
import Quickshell.Services.SystemTray

QtObject {
    readonly property string availability: "available"
    readonly property string freshness: "current"
    readonly property var lastError: null
    readonly property string operation: "idle"
    readonly property var lastUpdated: new Date()
    readonly property var items: SystemTray.items
}
