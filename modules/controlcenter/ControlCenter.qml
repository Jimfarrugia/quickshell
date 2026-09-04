import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../components" as Components
import "../../services" as Services

PanelWindow {
    id: root

    visible: true
    screen: Services.SurfaceService.controlCenterScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; bottom: true; left: true; right: true }

    property string confirmationAction: ""
    property string resultText: ""
    readonly property real surfaceWidth: panel.width
    readonly property real surfaceHeight: panel.height
    readonly property real contentImplicitHeight: panelContent.implicitHeight
    readonly property real contentImplicitWidth: panelContent.implicitWidth
    readonly property real themeColumnWidth: themeColumn.width
    readonly property real surfaceRadius: panel.radius
    readonly property real contentSpacing: 40
    readonly property real contentMargin: 40
    readonly property bool confirmationVisible: confirmationAction.length > 0
    readonly property var themeDropdown: themeMenu
    readonly property color buttonSurface: Services.ThemeService.theme.tokens.surface
    readonly property color buttonSurfaceHover: Services.ThemeService.theme.tokens.surface_hover
    readonly property color buttonSurfacePressed: Services.ThemeService.theme.tokens.surface_pressed
    readonly property color buttonForeground: Services.ThemeService.theme.tokens.on_surface_disabled
    readonly property color buttonBorder: Services.ThemeService.theme.tokens.on_surface_disabled
    readonly property real themeSectionSpacing: 12
    readonly property real themeTitleSpacing: 12
    readonly property real quickSettingWidth: Math.max(wifiTile.implicitWidth,
        bluetoothTile.implicitWidth, dndTile.implicitWidth, idleTile.implicitWidth,
        volumeTile.implicitWidth, micTile.implicitWidth)
    readonly property var quickSettingWidths: [wifiTile.width, bluetoothTile.width,
        dndTile.width, idleTile.width, volumeTile.width, micTile.width]

    function close() { Services.SurfaceService.closeControlCenter(); }

    function openDestination(action) {
        root.close();
        Qt.callLater(action);
    }

    function openDashboard(id, side) {
        root.openDestination(() => Services.SurfaceService.openDashboard(id, null, side || "right"));
    }

    function requestDefaults(action) {
        root.confirmationAction = action;
    }

    function performDefaults() {
        const action = root.confirmationAction;
        root.confirmationAction = "";
        const started = action === "capture"
            ? Services.DefaultsService.capture() : Services.DefaultsService.restore();
        if (!started) root.resultText = Services.DefaultsService.operationError;
    }

    function statusFor(availability, freshness, error) {
        if (error) return String(error);
        if (availability !== "available") return availability;
        if (freshness !== "current") return freshness;
        return "Ready";
    }

    function themeIndex() {
        return Math.max(0, Services.ThemeService.catalog.findIndex(
            theme => theme.id === Services.ThemeService.activeThemeId));
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: panel
        z: 1
        anchors.centerIn: parent
        implicitWidth: panelContent.implicitWidth + 80
        width: Math.min(implicitWidth, Math.max(0, parent.width - 40))
        implicitHeight: panelContent.implicitHeight + 70
        height: Math.min(implicitHeight, Math.max(0, parent.height - 40))
        color: Services.ThemeService.theme.tokens.surface_sidebar
        radius: Services.ConfigService.config.appearance.radius + 2
        border.width: Services.ConfigService.config.appearance.borderWidth
        border.color: Services.ThemeService.theme.tokens.outline_variant
        focus: true

        MouseArea { anchors.fill: parent; onClicked: event => event.accepted = true }

        Keys.onEscapePressed: {
            if (root.confirmationAction.length > 0) root.confirmationAction = "";
            else if (themeMenu.popup.visible) themeMenu.popup.close();
            else root.close();
        }
        Keys.onPressed: function(event) {
            if (event.modifiers === Qt.NoModifier && event.key === Qt.Key_Q) {
                root.close();
                event.accepted = true;
            }
        }

        Component.onCompleted: forceActiveFocus()

        ColumnLayout {
            id: panelContent
            anchors.fill: parent
            anchors.leftMargin: 40
            anchors.rightMargin: 40
            anchors.bottomMargin: 40
            anchors.topMargin: 30
            spacing: 0

            RowLayout {
                id: header
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                spacing: 12

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6
                    Text {
                        text: Services.TimeService.timeText
                        color: Services.ThemeService.theme.tokens.on_surface_variant
                        font.family: Services.ConfigService.config.appearance.fontFamily
                        font.pixelSize: 48
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: Services.TimeService.longDateText
                        color: Services.ThemeService.theme.tokens.on_surface_disabled
                        font.family: Services.ConfigService.config.appearance.fontFamily
                        font.pixelSize: 14
                    }
                }

                Item { Layout.fillWidth: true }

                Components.IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    iconName: "notifications"
                    iconSize: 28
                    implicitWidth: 52
                    implicitHeight: 52
                    radius: width / 2
                    border.width: 2
                    foregroundColor: root.buttonForeground
                    borderColor: root.buttonBorder
                    baseBackgroundColor: root.buttonSurface
                    hoverBackgroundColor: root.buttonSurfaceHover
                    pressedBackgroundColor: root.buttonSurfacePressed
                    tooltipText: "Open notifications"
                    onClicked: root.openDestination(() => Services.SurfaceService.openNotificationCenter())
                }
                Components.IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    iconName: "power_settings_new"
                    iconSize: 28
                    implicitWidth: 52
                    implicitHeight: 52
                    radius: width / 2
                    border.width: 2
                    foregroundColor: root.buttonForeground
                    borderColor: root.buttonBorder
                    baseBackgroundColor: root.buttonSurface
                    hoverBackgroundColor: root.buttonSurfaceHover
                    pressedBackgroundColor: root.buttonSurfacePressed
                    tooltipText: "Open power menu"
                    onClicked: root.openDestination(() => Services.PowerService.openPowerMenu())
                }
            }

            Item { Layout.preferredHeight: 40 }

            RowLayout {
                id: content
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 40

                GridLayout {
                    id: settingsGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    columns: 2
                    rowSpacing: 12
                    columnSpacing: 12

                    Components.QuickSettingTile {
                        id: wifiTile
                        Layout.fillWidth: false
                        Layout.preferredWidth: root.quickSettingWidth
                        Layout.maximumWidth: root.quickSettingWidth
                        Layout.preferredHeight: implicitHeight
                        Layout.maximumHeight: implicitHeight
                        title: "Wi-Fi"
                        iconName: Services.NetworkService.wifiEnabled ? "wifi" : "wifi_off"
                        checked: Services.NetworkService.wifiEnabled
                        pending: Services.NetworkService.wifiTogglePending
                        primaryEnabled: Services.NetworkService.availability === "available"
                        secondaryEnabled: true
                        valueText: Services.NetworkService.ssid || "Disconnected"
                        statusText: root.statusFor(Services.NetworkService.availability,
                            Services.NetworkService.freshness, Services.NetworkService.operationError)
                        onClicked: Services.NetworkService.setWifiEnabled(!Services.NetworkService.wifiEnabled)
                        onSecondaryClicked: root.openDashboard("network", "left")
                    }
                    Components.QuickSettingTile {
                        id: bluetoothTile
                        Layout.fillWidth: false
                        Layout.preferredWidth: root.quickSettingWidth
                        Layout.maximumWidth: root.quickSettingWidth
                        Layout.preferredHeight: implicitHeight
                        Layout.maximumHeight: implicitHeight
                        title: "Bluetooth"
                        iconName: Services.BluetoothService.enabled ? "bluetooth" : "bluetooth_disabled"
                        checked: Services.BluetoothService.enabled
                        pending: Services.BluetoothService.operation === "pending"
                        primaryEnabled: Services.BluetoothService.availability === "available"
                        secondaryEnabled: true
                        valueText: Services.BluetoothService.connectedSummary || "Disconnected"
                        statusText: root.statusFor(Services.BluetoothService.availability,
                            Services.BluetoothService.freshness, Services.BluetoothService.operationError)
                        onClicked: Services.BluetoothService.setEnabled(!Services.BluetoothService.enabled)
                        onSecondaryClicked: root.openDashboard("bluetooth")
                    }
                    Components.QuickSettingTile {
                        id: dndTile
                        Layout.fillWidth: false
                        Layout.preferredWidth: root.quickSettingWidth
                        Layout.maximumWidth: root.quickSettingWidth
                        Layout.preferredHeight: implicitHeight
                        Layout.maximumHeight: implicitHeight
                        title: "Do Not Disturb"
                        iconName: Services.NotificationService.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                        checked: Services.NotificationService.dnd
                        activeColor: Services.ThemeService.theme.tokens.warning
                        primaryEnabled: Services.NotificationService.stateReady
                        valueText: Services.NotificationService.dnd ? "On" : "Off"
                        statusText: Services.NotificationService.stateReady ? "Notifications" : "Unavailable"
                        onClicked: Services.NotificationService.setDnd(!Services.NotificationService.dnd)
                    }
                    Components.QuickSettingTile {
                        id: idleTile
                        Layout.fillWidth: false
                        Layout.preferredWidth: root.quickSettingWidth
                        Layout.maximumWidth: root.quickSettingWidth
                        Layout.preferredHeight: implicitHeight
                        Layout.maximumHeight: implicitHeight
                        title: "Idle inhibitor"
                        iconName: Services.IdleService.requested ? "visibility" : "visibility_off"
                        checked: Services.IdleService.requested
                        activeColor: Services.ThemeService.theme.tokens.warning
                        primaryEnabled: Services.IdleService.availability === "available" && Services.IdleService.configured
                        valueText: Services.IdleService.requested ? "Requested" : "Disabled"
                        statusText: Services.IdleService.configured ? Services.IdleService.availability : "Unavailable"
                        onClicked: Services.IdleService.toggle()
                    }
                    Components.QuickSettingTile {
                        id: volumeTile
                        Layout.fillWidth: false
                        Layout.preferredWidth: root.quickSettingWidth
                        Layout.maximumWidth: root.quickSettingWidth
                        Layout.preferredHeight: implicitHeight
                        Layout.maximumHeight: implicitHeight
                        title: "Volume"
                        iconName: Services.AudioService.muted ? "volume_off" : "volume_up"
                        checked: !Services.AudioService.muted
                        alert: Services.AudioService.muted
                        activeColor: Services.ThemeService.theme.tokens.success
                        alertColor: Services.ThemeService.theme.tokens.error
                        pending: Services.AudioService.pendingMuted !== null
                            || Services.AudioService.pendingVolumePercent >= 0
                        primaryEnabled: Services.AudioService.availability === "available"
                        valueText: `${Services.AudioService.displayVolumePercent}%`
                        statusText: Services.AudioService.muted ? "Muted" : "Output"
                        secondaryEnabled: true
                        onClicked: Services.AudioService.toggleMuted()
                        onSecondaryClicked: root.openDashboard("audio")
                        onWheelChanged: Services.AudioService.wheelStep(angleDeltaY)
                    }
                    Components.QuickSettingTile {
                        id: micTile
                        Layout.fillWidth: false
                        Layout.preferredWidth: root.quickSettingWidth
                        Layout.maximumWidth: root.quickSettingWidth
                        Layout.preferredHeight: implicitHeight
                        Layout.maximumHeight: implicitHeight
                        title: "Microphone"
                        iconName: Services.AudioService.microphoneMuted ? "mic_off" : "mic"
                        checked: !Services.AudioService.microphoneMuted
                        alert: Services.AudioService.microphoneMuted
                        activeColor: Services.ThemeService.theme.tokens.success
                        alertColor: Services.ThemeService.theme.tokens.error
                        pending: Services.AudioService.pendingMicrophoneMuted !== null
                            || Services.AudioService.pendingMicrophoneVolumePercent >= 0
                        primaryEnabled: Services.AudioService.microphoneAvailability === "available"
                        valueText: `${Services.AudioService.displayMicrophoneVolumePercent}%`
                        statusText: Services.AudioService.microphoneMuted ? "Muted" : "Input"
                        secondaryEnabled: true
                        onClicked: Services.AudioService.toggleMicrophoneMuted()
                        onSecondaryClicked: root.openDashboard("audio")
                        onWheelChanged: Services.AudioService.microphoneWheelStep(angleDeltaY)
                    }
                }

                ColumnLayout {
                    id: themeColumn
                    Layout.minimumWidth: root.quickSettingWidth
                    Layout.fillHeight: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: root.themeTitleSpacing
                        Text {
                            text: "Theme"
                            color: Services.ThemeService.theme.tokens.on_surface
                            font.family: Services.ConfigService.config.appearance.fontFamily
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }
                        Repeater {
                            model: ["primary", "secondary", "link", "warning", "error"]
                            delegate: Rectangle {
                                required property string modelData
                                implicitWidth: 18
                                implicitHeight: 18
                                radius: width / 2
                                color: Services.ThemeService.theme.tokens[modelData]
                                border.width: 0
                            }
                        }
                    }

                    Components.ThemedComboBox {
                        id: themeMenu
                        Layout.fillWidth: true
                        Layout.bottomMargin: root.themeSectionSpacing
                        model: Services.ThemeService.catalog
                        textRole: "name"
                        valueRole: "id"
                        currentIndex: root.themeIndex()
                        enabled: Services.ThemeService.operation !== "pending"
                            && Services.ThemeService.externalOperation !== "pending"
                        onActivated: Services.ThemeService.requestTheme(currentValue)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Components.IconButton {
                            iconName: "palette"
                            foregroundColor: root.buttonForeground
                            borderColor: root.buttonBorder
                            baseBackgroundColor: root.buttonSurface
                            hoverBackgroundColor: root.buttonSurfaceHover
                            pressedBackgroundColor: root.buttonSurfacePressed
                            Layout.fillWidth: true
                            tooltipText: "Open palette viewer"
                            onClicked: root.openDestination(() => Services.SurfaceService.openPaletteViewer())
                        }
                        Components.IconButton {
                            iconName: "wallpaper"
                            foregroundColor: root.buttonForeground
                            borderColor: root.buttonBorder
                            baseBackgroundColor: root.buttonSurface
                            hoverBackgroundColor: root.buttonSurfaceHover
                            pressedBackgroundColor: root.buttonSurfacePressed
                            Layout.fillWidth: true
                            tooltipText: "Select wallpaper"
                            onClicked: root.openDestination(() => Services.SurfaceService.openWallpaperSelector())
                        }
                        Components.IconButton {
                            iconName: "wallpaper_slideshow"
                            foregroundColor: root.buttonForeground
                            borderColor: root.buttonBorder
                            baseBackgroundColor: root.buttonSurface
                            hoverBackgroundColor: root.buttonSurfaceHover
                            pressedBackgroundColor: root.buttonSurfacePressed
                            Layout.fillWidth: true
                            enabled: Services.WallpaperService.wallpaperDirectoryReady
                                && Services.WallpaperService.wallpaperDirectoryCount > 0
                            tooltipText: "Random wallpaper"
                            onClicked: Services.WallpaperService.requestRandomWallpaper()
                        }
                        Components.IconButton {
                            iconName: "save"
                            foregroundColor: root.buttonForeground
                            borderColor: root.buttonBorder
                            baseBackgroundColor: root.buttonSurface
                            hoverBackgroundColor: root.buttonSurfaceHover
                            pressedBackgroundColor: root.buttonSurfacePressed
                            Layout.fillWidth: true
                            tooltipText: "Capture defaults"
                            onClicked: root.requestDefaults("capture")
                        }
                        Components.IconButton {
                            iconName: "restore"
                            foregroundColor: root.buttonForeground
                            borderColor: root.buttonBorder
                            baseBackgroundColor: root.buttonSurface
                            hoverBackgroundColor: root.buttonSurfaceHover
                            pressedBackgroundColor: root.buttonSurfacePressed
                            Layout.fillWidth: true
                            tooltipText: "Restore defaults"
                            onClicked: root.requestDefaults("restore")
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: root.themeSectionSpacing
                        visible: Services.ThemeService.operation === "pending"
                            || Services.ThemeService.externalOperation === "pending"
                            || Services.ThemeService.lastError !== null
                        text: Services.ThemeService.operation === "pending" ? "Applying theme..."
                            : (Services.ThemeService.externalOperation === "pending" ? "Updating desktop theme..."
                                : "Theme service degraded")
                        color: Services.ThemeService.operation === "failed"
                            ? Services.ThemeService.theme.tokens.error
                            : Services.ThemeService.theme.tokens.warning
                        font.family: Services.ConfigService.config.appearance.fontFamily
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: root.themeSectionSpacing
                        visible: Services.DefaultsService.operation !== "idle"
                            || root.resultText.length > 0
                        text: Services.DefaultsService.operation === "pending" ? "Defaults operation in progress..."
                            : (Services.DefaultsService.operationError || Services.DefaultsService.operationWarning
                                || root.resultText)
                        color: Services.DefaultsService.operation === "failed"
                            ? Services.ThemeService.theme.tokens.error
                            : Services.ThemeService.theme.tokens.warning
                        font.family: Services.ConfigService.config.appearance.fontFamily
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        Rectangle {
            visible: root.confirmationAction.length > 0
            anchors.fill: parent
            z: 5
            color: Services.ThemeService.theme.tokens.scrim
            radius: panel.radius

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(360, parent.width - 80)
                spacing: 16
                Text {
                    Layout.fillWidth: true
                    text: root.confirmationAction === "capture"
                        ? "Capture current defaults?" : "Restore saved defaults?"
                    color: Services.ThemeService.theme.tokens.on_surface
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                Text {
                    Layout.fillWidth: true
                    text: root.confirmationAction === "capture"
                        ? "This replaces the authored defaults snapshot."
                        : "This changes the live theme and wallpaper files."
                    color: Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12
                    Components.IconButton {
                        iconName: "close"
                        foregroundColor: root.buttonForeground
                        borderColor: root.buttonBorder
                        baseBackgroundColor: root.buttonSurface
                        hoverBackgroundColor: root.buttonSurfaceHover
                        pressedBackgroundColor: root.buttonSurfacePressed
                        tooltipText: "Cancel"
                        onClicked: root.confirmationAction = ""
                    }
                    Components.IconButton {
                        iconName: "check"
                        foregroundColor: root.buttonForeground
                        borderColor: root.buttonBorder
                        baseBackgroundColor: root.buttonSurface
                        hoverBackgroundColor: root.buttonSurfaceHover
                        pressedBackgroundColor: root.buttonSurfacePressed
                        toggleColor: Services.ThemeService.theme.tokens.warning
                        tooltipText: "Confirm"
                        onClicked: root.performDefaults()
                    }
                }
            }
            MouseArea { anchors.fill: parent; z: -1; onClicked: event => event.accepted = true }
        }
    }
}
