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
        || SurfaceService.controlCenterVisible
    property string longDateText: ""
    readonly property string availability: "available"
    readonly property string freshness: "current"
    readonly property var lastError: null
    readonly property string operation: "idle"

    function formatLongDate(date) {
        const day = date.getDate();
        const suffix = day % 100 >= 11 && day % 100 <= 13
            ? "th" : ({ 1: "st", 2: "nd", 3: "rd" }[day % 10] || "th");
        const weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday",
            "Friday", "Saturday"];
        const months = ["January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"];
        return `${weekdays[date.getDay()]} ${day}${suffix} ${months[date.getMonth()]}`;
    }

    function update() {
        if (!hasConsumer) {
            cadence.stop();
            dateText = "";
            timeText = "";
            longDateText = "";
            return;
        }
        const now = new Date();
        const options = ConfigService.config.clock.format24h
            ? (ConfigService.config.clock.showSeconds ? "HH:mm:ss" : "HH:mm")
            : (ConfigService.config.clock.showSeconds ? "h:mm:ss AP" : "h:mm AP");
        dateText = Qt.formatDateTime(now, "ddd d");
        longDateText = formatLongDate(now);
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
