import QtQuick
import Quickshell
import Quickshell as QS
import "../../services" as Services

PanelWindow {
    id: root

    property var modelData
    property var dashboardController
    property bool idleWindowRegistered: false

    function updateIdleWindowRegistration() {
        if (visible && !idleWindowRegistered) {
            Services.IdleService.registerWindow(root);
            idleWindowRegistered = true;
        } else if (!visible && idleWindowRegistered) {
            Services.IdleService.unregisterWindow(root);
            idleWindowRegistered = false;
        }
    }
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
        color: Services.ThemeService.theme.tokens.surface_panel
        border.width: 0

        Row {
            id: leftModules
            anchors.left: parent.left
            anchors.leftMargin: Services.ConfigService.config.bar.moduleSpacing / 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Services.ConfigService.config.bar.moduleSpacing

            NetworkModule { sourceScreen: root.modelData; dashboardController: root.dashboardController }
            MetricsModule {}
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
            IdleInhibitorModule {}
            DoNotDisturbModule {}
            BluetoothModule {}
             AudioModule { sourceScreen: root.modelData; dashboardController: root.dashboardController }
            BrightnessModule {}
            BatteryModule {}
            ClockModule {}
        }
    }

    onVisibleChanged: updateIdleWindowRegistration()
    Component.onCompleted: updateIdleWindowRegistration()
    Component.onDestruction: if (idleWindowRegistered) Services.IdleService.unregisterWindow(root)
}
