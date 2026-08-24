pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property string dateText: ""
    property string timeText: ""
    readonly property string text: dateText.length > 0 ? `${dateText} ${timeText}` : ""
    property var lastUpdated: null
    readonly property bool hasConsumer: ConfigService.config.bar.enabled
    readonly property string availability: "available"
    readonly property string freshness: "current"
    readonly property var lastError: null
    readonly property string operation: "idle"

    function update() {
        if (!hasConsumer) {
            cadence.stop();
            dateText = "";
            timeText = "";
            return;
        }
        const now = new Date();
        const options = ConfigService.config.clock.format24h
            ? (ConfigService.config.clock.showSeconds ? "HH:mm:ss" : "HH:mm")
            : (ConfigService.config.clock.showSeconds ? "h:mm:ss AP" : "h:mm AP");
        dateText = Qt.formatDateTime(now, "ddd d");
        timeText = Qt.formatDateTime(now, options);
        lastUpdated = now;
        const unit = ConfigService.config.clock.showSeconds ? 1000 : 60000;
        cadence.interval = Math.max(50, unit - (now.getTime() % unit));
        cadence.restart();
    }

    Timer {
        id: cadence
        repeat: false
        onTriggered: root.update()
    }

    Connections {
        target: ConfigService
        function onConfigChanged() { root.update(); }
    }

    onHasConsumerChanged: update()

    Component.onCompleted: update()
}
