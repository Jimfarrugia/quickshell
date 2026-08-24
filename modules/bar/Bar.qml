import QtQuick
import Quickshell
import Quickshell as QS
import "../../services" as Services

PanelWindow {
    id: root

    property var modelData
    screen: modelData
    visible: Services.ConfigService.config.bar.enabled
    implicitHeight: Services.ConfigService.config.bar.height
    color: "transparent"
    exclusionMode: Services.ConfigService.config.bar.exclusive ? ExclusionMode.Auto : ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: Services.ConfigService.config.bar.edge === "top"
        bottom: Services.ConfigService.config.bar.edge === "bottom"
    }

    Rectangle {
        anchors.fill: parent
        color: Services.ThemeService.theme.tokens.surfaceOverlay
        border.width: 0

        NetworkModule {
            anchors.left: parent.left
            anchors.leftMargin: Services.ConfigService.config.bar.moduleSpacing / 2
            anchors.verticalCenter: parent.verticalCenter
        }

        WorkspacesModule {
            id: workspaces
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            id: rightModules
            anchors.right: parent.right
            anchors.rightMargin: Services.ConfigService.config.bar.moduleSpacing / 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Services.ConfigService.config.bar.moduleSpacing

            Item {
                id: traySlot
                width: trayLoader.item ? trayLoader.item.implicitWidth : 0
                height: rightModules.height

                QS.LazyLoader {
                    id: trayLoader
                    active: Services.ConfigService.config.bar.trayHostEnabled
                    source: "TrayHost.qml"
                    onItemChanged: if (item) {
                        item.parent = traySlot;
                        item.parentWindow = root;
                        item.y = Qt.binding(() => (traySlot.height - item.height) / 2);
                    }
                }
            }
            HealthModule {}
            AudioModule {}
            BatteryModule {}
            ClockModule {}
        }
    }
}
