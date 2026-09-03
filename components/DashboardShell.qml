import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services" as Services
import "../modules/audio"
import "../modules/bluetooth"
import "../modules/network"
import "../components" as Components

PanelWindow {
    id: root

    property var controller
    property string title: controller ? controller.activeId : ""
    property real viewportWidth: width
    property real viewportHeight: height
    property bool testBarEnabled: Services.ConfigService.config.bar.enabled
    property string testBarEdge: Services.ConfigService.config.bar.edge
    property real testBarHeight: Services.ConfigService.config.bar.height
    property real contentHeightOverride: -1
    readonly property real surfaceX: surface.x
    readonly property real surfaceY: surface.y
    readonly property real surfaceWidth: surface.width
    readonly property real surfaceHeight: surface.height
    readonly property bool keyboardTargetFocused: keyTarget.activeFocus
    readonly property bool keyboardTargetRequested: keyTarget.focus
    readonly property string featureTitle: controller && controller.activeId === "audio" ? "Audio"
        : (controller && controller.activeId === "bluetooth" ? "Bluetooth"
            : (controller && controller.activeId === "network" ? "Network" : title))

    function dismiss() {
        if (root.controller && root.controller.activeId === "bluetooth"
                && Services.BluetoothService.discovering)
            Services.BluetoothService.setDiscovering(false);
        if (root.controller && root.controller.activeId === "bluetooth")
            Services.BluetoothService.operationError = "";
        if (root.controller) root.controller.close();
    }
    function dismissFromOutside() { root.dismiss(); }
    function dismissFromEscape() { root.dismiss(); }
    property Component contentComponent: null
    default property alias contentData: contentColumn.data

    visible: true
    screen: controller && typeof controller.sourceScreen === "object"
        ? controller.sourceScreen : null
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; bottom: true; left: true; right: true }

    function availableHeight() {
        const config = Services.ConfigService.config.bar;
        const barGap = config.enabled ? config.height + 20 : 20;
        return Math.max(0, root.viewportHeight - barGap - 20);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissFromOutside()
    }

    Rectangle {
        id: surface
        z: 1
        x: root.controller && root.controller.sourceSide === "left" ? 20
            : root.viewportWidth - width - 20
        y: root.testBarEdge === "top"
            ? (root.testBarEnabled ? root.testBarHeight + 20 : 20)
            : root.viewportHeight - height - (root.testBarEnabled
                ? root.testBarHeight + 20 : 20)
        width: Math.min(636, root.viewportWidth - 40)
        height: Math.min(root.availableHeight(),
            (root.contentHeightOverride >= 0 ? root.contentHeightOverride
                : headerRow.implicitHeight + headerRow.Layout.bottomMargin
                    + contentColumn.height) + 40)
        color: Services.ThemeService.theme.tokens.surface_sidebar
        radius: Services.ConfigService.config.appearance.radius + 2
        border.width: Services.ConfigService.config.appearance.borderWidth
        border.color: Services.ThemeService.theme.tokens.outline_variant

        MouseArea { anchors.fill: parent; onClicked: event => event.accepted = true }

        Item {
            id: keyTarget
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.dismissFromEscape()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 0

            RowLayout {
                id: headerRow
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                Layout.preferredHeight: 32
                Text {
                    Layout.fillWidth: true
                    text: root.featureTitle
                    color: Services.ThemeService.theme.tokens.on_surface_disabled
                    font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }
            RowLayout {
                visible: !!root.controller && root.controller.activeId === "network"
                spacing: 6
                Components.IconButton {
                    iconName: "wifi"
                    toggleable: true
                    toggleColor: Services.NetworkService.wifiTogglePending
                        ? Services.ThemeService.theme.tokens.warning
                        : Services.ThemeService.theme.tokens.success
                    foregroundColor: Services.NetworkService.wifiTogglePending
                        ? Services.ThemeService.theme.tokens.warning
                        : Services.ThemeService.theme.tokens.on_surface_disabled
                    borderColor: Services.NetworkService.wifiTogglePending
                        ? Services.ThemeService.theme.tokens.warning
                        : Services.ThemeService.theme.tokens.on_surface_disabled
                    checked: Services.NetworkService.wifiTogglePending
                        ? Services.NetworkService.pendingWifiEnabled
                        : Services.NetworkService.wifiEnabled
                    enabled: Services.NetworkService.availability === "available"
                        && Services.NetworkService.wifiHardwareEnabled
                    tooltipText: Services.NetworkService.wifiEnabled
                        ? "Disable Wi-Fi" : "Enable Wi-Fi"
                    tooltipBelow: true
                    onToggled: Services.NetworkService.setWifiEnabled(checked)
                }
                Components.IconButton {
                    iconName: "wifi_find"
                    foregroundColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    borderColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    enabled: Services.NetworkService.availability === "available"
                    tooltipText: "Scan for networks"
                    tooltipBelow: true
                    onClicked: Services.NetworkService.refreshScan()
                }
            }
            RowLayout {
                visible: !!root.controller && root.controller.activeId === "bluetooth"
                spacing: 6
                Components.IconButton {
                    iconName: "power_settings_new"
                    toggleable: true
                    checked: Services.BluetoothService.enabled
                    toggleColor: Services.ThemeService.theme.tokens.success
                    foregroundColor: Services.BluetoothService.enabled
                        ? Services.ThemeService.theme.tokens.success
                        : Services.ThemeService.theme.tokens.error
                    borderColor: Services.BluetoothService.enabled
                        ? Services.ThemeService.theme.tokens.success
                        : Services.ThemeService.theme.tokens.error
                    enabled: Services.BluetoothService.availability === "available"
                    tooltipText: Services.BluetoothService.enabled
                        ? "Disable Bluetooth" : "Enable Bluetooth"
                    tooltipBelow: true
                    onToggled: Services.BluetoothService.setEnabled(checked)
                }
                Components.IconButton {
                    iconName: "explore"
                    toggleable: true
                    checked: Services.BluetoothService.discoverable
                    toggleColor: Services.ThemeService.theme.tokens.success
                    foregroundColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    borderColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    enabled: Services.BluetoothService.enabled
                    tooltipText: Services.BluetoothService.discoverable
                        ? "Disable Discoverable Mode" : "Enable Discoverable Mode"
                    tooltipBelow: true
                    onToggled: Services.BluetoothService.setDiscoverable(checked)
                }
                Components.IconButton {
                    iconName: "join_right"
                    toggleable: true
                    checked: Services.BluetoothService.pairable
                    toggleColor: Services.ThemeService.theme.tokens.success
                    foregroundColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    borderColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    enabled: Services.BluetoothService.enabled
                    tooltipText: Services.BluetoothService.pairable
                        ? "Disable Pairable Mode" : "Enable Pairable Mode"
                    tooltipBelow: true
                    onToggled: Services.BluetoothService.setPairable(checked)
                }
                Components.IconButton {
                    iconName: Services.BluetoothService.discovering ? "stop" : "search"
                    toggleable: true
                    checked: Services.BluetoothService.discovering
                    toggleColor: Services.ThemeService.theme.tokens.warning
                    foregroundColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    borderColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    enabled: Services.BluetoothService.enabled
                    tooltipText: Services.BluetoothService.discovering
                        ? "Stop Searching" : "Search for Devices"
                    tooltipBelow: true
                    onToggled: Services.BluetoothService.setDiscovering(checked)
                }
            }
            Components.IconButton {
                    id: settingsButton
                visible: !!root.controller && ["audio", "bluetooth", "network"].indexOf(root.controller.activeId) >= 0
                    iconName: "settings"
                    foregroundColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    borderColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    tooltipText: root.controller && root.controller.activeId === "bluetooth"
                    ? "Open Blueman" : (root.controller && root.controller.activeId === "network"
                        ? "Open NetworkManager editor" : "Open pavucontrol")
                    tooltipBelow: true
                    onClicked: root.controller && root.controller.activeId === "bluetooth"
                    ? Services.BluetoothService.launchFallback() : (root.controller && root.controller.activeId === "network"
                        ? Services.NetworkService.openFallback() : Services.AudioService.launchFallback())
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: contentColumn.height

                ColumnLayout {
                    id: contentColumn
                    width: parent.width
                    height: loader.item ? loader.item.implicitHeight : 0
                    spacing: Services.ConfigService.config.appearance.spacing
                    Loader {
                        id: loader
                        Layout.fillWidth: true
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                        active: !!root.controller && root.controller.visible
                        sourceComponent: root.contentComponent
                            || (root.controller && root.controller.activeId === "audio"
                             ? audioDashboard : (root.controller && root.controller.activeId === "bluetooth"
                             ? bluetoothDashboard : (root.controller && root.controller.activeId === "network"
                                 ? networkDashboard : unavailableDashboard)))
                    }
                }
            }
        }
    }

    Component { id: audioDashboard; AudioDashboard {} }
    Component { id: bluetoothDashboard; BluetoothDashboard {} }
    Component { id: networkDashboard; NetworkDashboard {} }
    Component {
        id: unavailableDashboard
        Text {
            text: `${root.featureTitle || "Dashboard"} is not available yet`
            color: Services.ThemeService.theme.tokens.on_surface_variant
            font.family: Services.ConfigService.config.appearance.fontFamily
            font.pixelSize: Services.ConfigService.config.appearance.fontSize
        }
    }

    Component.onCompleted: keyTarget.forceActiveFocus()
    onClosed: root.dismiss()
}
