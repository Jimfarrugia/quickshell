import QtQml

QtObject {
    id: root

    property string owner: "qe"
    property string availability: "available"
    property string freshness: "current"
    property var lastUpdated: new Date()
    property var lastError: null
    signal notificationReceived(var notification)
    signal notificationUpdated(var notification)
    signal notificationClosed(var notification, var reason)

    function send(notification) { notificationReceived(notification); }
    function update(notification) { notificationUpdated(notification); }
    function close(notification, reason) { notificationClosed(notification, reason || "dismissed"); }
}
