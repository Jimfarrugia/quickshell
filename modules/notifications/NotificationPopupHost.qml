import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services" as Services

PanelWindow {
    id: root

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: Services.NotificationService.ready
        && Services.NotificationService.popupNotifications.length > 0
    implicitWidth: 384
    implicitHeight: popupColumn.implicitHeight + 24
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    anchors {
        top: true
        right: true
    }
    margins: { top: 12; right: 12; }

    ColumnLayout {
        id: popupColumn
        anchors.fill: parent
        spacing: 8

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
