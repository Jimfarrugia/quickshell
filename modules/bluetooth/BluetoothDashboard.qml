import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../components" as Components

ColumnLayout {
    id: root
    spacing: Services.ConfigService.config.appearance.spacing
    property var forgettingAddresses: []

    component LabelText: Text {
        color: Services.ThemeService.theme.tokens.on_surface_variant
        font.family: Services.ConfigService.config.appearance.fontFamily
        font.pixelSize: Services.ConfigService.config.appearance.fontSize
    }

    component SectionTitle: Text {
        color: Services.ThemeService.theme.tokens.on_surface
        font.family: Services.ConfigService.config.appearance.fontFamily
        font.pixelSize: Services.ConfigService.config.appearance.fontSize
        font.weight: Font.DemiBold
    }

    function deviceName(device) { return device.name || device.address; }
    function deviceStatus(device) {
        if (device.pairing) return "Pairing...";
        if (device.state === "connecting") return "Connecting...";
        if (device.state === "disconnecting") return "Disconnecting...";
        if (device.connected) return "Connected";
        if (device.paired || device.bonded) return "Paired";
        return "Discovered";
    }
    function forgetting(address) { return forgettingAddresses.indexOf(address) >= 0; }
    function toggleForget(address) {
        if (forgetting(address)) forgettingAddresses = forgettingAddresses.filter(item => item !== address);
        else forgettingAddresses = forgettingAddresses.concat([address]);
    }

    LabelText {
        visible: Services.BluetoothService.availability !== "available"
            || Services.BluetoothService.operationError.length > 0
        text: Services.BluetoothService.availability !== "available"
            ? `Bluetooth service: ${Services.BluetoothService.availability}`
            : Services.BluetoothService.operationError
        color: Services.ThemeService.theme.tokens.warning
    }

    SectionTitle {
        visible: Services.BluetoothService.adapters.length > 1
        text: "Adapters"
        Layout.topMargin: 20
        Layout.bottomMargin: 12
    }
    ComboBox {
        id: adapterSelector
        visible: Services.BluetoothService.adapters.length > 1
        Layout.fillWidth: true
        model: Services.BluetoothService.adapters
        textRole: "name"
        currentIndex: Math.max(0, Services.BluetoothService.adapters.findIndex(
            adapter => adapter.id === Services.BluetoothService.adapterId))
        onActivated: Services.BluetoothService.selectAdapter(
            Services.BluetoothService.adapters[index].id)
        delegate: ItemDelegate {
            id: adapterDelegate
            required property var modelData
            required property int index
            width: adapterSelector.width
            highlighted: adapterSelector.highlightedIndex === index
            contentItem: RowLayout {
                spacing: 8
                Text {
                    text: adapterDelegate.index === adapterSelector.currentIndex ? "check" : ""
                    color: Services.ThemeService.theme.tokens.on_surface
                    font.family: Services.ConfigService.config.appearance.iconFontFamily
                    font.pixelSize: Services.ConfigService.config.appearance.fontSize
                    Layout.preferredWidth: 20
                }
                Text {
                    text: adapterDelegate.modelData.name || adapterDelegate.modelData.id
                    color: Services.ThemeService.theme.tokens.on_surface
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: Services.ConfigService.config.appearance.fontSize
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }

    SectionTitle {
        text: "Known devices"
        Layout.topMargin: Services.BluetoothService.adapters.length > 1 ? 20 : 0
        Layout.bottomMargin: 12
    }
    Repeater {
        model: Services.BluetoothService.devices.filter(device => device.paired || device.bonded)
            .sort((left, right) => Number(right.connected) - Number(left.connected))
        delegate: deviceRow
    }
    SectionTitle {
        visible: Services.BluetoothService.devices.some(device => !(device.paired || device.bonded))
        text: "Discovered devices"
        Layout.topMargin: 20
        Layout.bottomMargin: 12
    }
    Repeater {
        model: Services.BluetoothService.devices.filter(device => !(device.paired || device.bonded))
        delegate: deviceRow
    }
    LabelText {
        visible: Services.BluetoothService.devices.length === 0
        text: "No Bluetooth devices"
    }

    Component {
        id: deviceRow
        RowLayout {
            required property var modelData
            readonly property var device: modelData
            id: deviceRowLayout
            Layout.fillWidth: true
            spacing: 6
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                implicitHeight: deviceNameLabel.implicitHeight
                Layout.alignment: Qt.AlignVCenter
                LabelText {
                    id: deviceNameLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.deviceName(deviceRowLayout.device)
                    elide: Text.ElideRight
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                implicitHeight: batteryContent.implicitHeight
                Layout.alignment: Qt.AlignVCenter
                RowLayout {
                    id: batteryContent
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: deviceRowLayout.device.batteryAvailable
                    spacing: 0
                    Text {
                        text: "battery_0_bar"
                        color: Services.ThemeService.theme.tokens.on_surface_variant
                        font.family: Services.ConfigService.config.appearance.iconFontFamily
                        font.pixelSize: Services.ConfigService.config.appearance.fontSize
                    }
                    LabelText { text: `${deviceRowLayout.device.batteryPercent}%` }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                implicitHeight: stateAndActions.implicitHeight
                Layout.alignment: Qt.AlignVCenter
                RowLayout {
                    id: stateAndActions
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    LabelText { text: root.deviceStatus(deviceRowLayout.device) }
                    RowLayout {
                        id: actionGroup
                        readonly property var rowDevice: deviceRowLayout.device
                        spacing: 6
                        Layout.leftMargin: 6
                        Components.IconButton {
                            visible: actionGroup.rowDevice.connected
                            iconName: "link"
                            foregroundColor: Services.ThemeService.theme.tokens.success
                            borderColor: Services.ThemeService.theme.tokens.success
                            tooltipText: "Disconnect"
                            enabled: Services.BluetoothService.pendingDeviceAddress !== actionGroup.rowDevice.address
                            onClicked: Services.BluetoothService.begin(actionGroup.rowDevice.address, "disconnect")
                        }
                        Components.IconButton {
                            visible: !actionGroup.rowDevice.connected
                                && (actionGroup.rowDevice.paired || actionGroup.rowDevice.bonded)
                            iconName: "link"
                            tooltipText: "Connect"
                            enabled: Services.BluetoothService.pendingDeviceAddress !== actionGroup.rowDevice.address
                            onClicked: Services.BluetoothService.begin(actionGroup.rowDevice.address, "connect")
                        }
                        Components.IconButton {
                            visible: !actionGroup.rowDevice.paired && !actionGroup.rowDevice.bonded
                            iconName: actionGroup.rowDevice.pairing ? "cancel" : "add_link"
                            tooltipText: actionGroup.rowDevice.pairing ? "Cancel pairing" : "Open Blueman"
                            enabled: actionGroup.rowDevice.pairing
                                ? Services.BluetoothService.pendingDeviceAddress === actionGroup.rowDevice.address
                                : Services.BluetoothService.availability === "available"
                            onClicked: actionGroup.rowDevice.pairing
                                ? Services.BluetoothService.begin(actionGroup.rowDevice.address, "cancel")
                                : Services.BluetoothService.launchFallback()
                        }
                        Components.IconButton {
                            visible: actionGroup.rowDevice.paired || actionGroup.rowDevice.bonded
                            iconName: "delete"
                            foregroundColor: Services.ThemeService.theme.tokens.error
                            borderColor: Services.ThemeService.theme.tokens.error
                            tooltipText: "Forget"
                            enabled: Services.BluetoothService.pendingDeviceAddress === ""
                                && !root.forgetting(actionGroup.rowDevice.address)
                            onClicked: root.toggleForget(actionGroup.rowDevice.address)
                        }
                        LabelText { visible: root.forgetting(actionGroup.rowDevice.address); text: "Confirm?" }
                        Components.IconButton {
                            visible: root.forgetting(actionGroup.rowDevice.address)
                            iconName: "check"
                            tooltipText: "Confirm forget"
                            onClicked: Services.BluetoothService.forget(actionGroup.rowDevice.address)
                        }
                    }
                }
            }
        }
    }
}
