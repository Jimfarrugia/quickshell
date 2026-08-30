import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services" as Services

PanelWindow {
    id: root

    property real popupMargin: 20

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: Services.NotificationService.ready
        && Services.NotificationService.popupNotifications.length > 0
    implicitWidth: 384 + root.popupMargin
    implicitHeight: popupColumn.implicitHeight + root.popupMargin
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    anchors {
        top: true
        right: true
    }
    margins { top: root.popupMargin; right: root.popupMargin }

    ColumnLayout {
        id: popupColumn
        anchors.fill: parent
        anchors.leftMargin: root.popupMargin
        anchors.bottomMargin: root.popupMargin
        spacing: root.popupMargin

        Repeater {
            model: Services.NotificationService.popupNotifications
            delegate: NotificationPopup {
                required property var modelData
                Layout.fillWidth: true
                record: modelData
            }
        }
    }
}
