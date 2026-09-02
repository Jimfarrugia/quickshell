import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Networking
import "../../services" as Services
import "../../components" as Components

ColumnLayout {
    id: root
    spacing: Services.ConfigService.config.appearance.spacing
    property string confirmForgetKey: ""
    property string pskKey: ""
    property string selectedProfileKey: ""

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

    function securityText(network) {
        return network && network.security !== undefined
            ? WifiSecurityType.toString(network.security) : "Security unknown";
    }
    function securitySupported(row) { return Services.NetworkService.isSupportedSecurity(row.network); }
    function rowPending(row) {
        const selected = root.selectedRow(row);
        return Services.NetworkService.pendingTargetKey === row.key
            || Services.NetworkService.pendingTargetKey === selected.key;
    }
    function selectedProfile(row) {
        if (!row.profiles || row.profiles.length === 0) return null;
        return row.profiles.find(profile => profile.key === root.selectedProfileKey) || row.profiles[0];
    }
    function selectedRow(row) {
        const profile = selectedProfile(row);
        return profile ? {network: row.network, settings: profile.settings, key: profile.key, name: profile.name}
            : row;
    }
    function selectProfile(row, index) {
        const profile = row.profiles[index];
        if (profile) root.selectedProfileKey = profile.key;
    }

    Component.onCompleted: Services.NetworkService.setScanning(true)
    Component.onDestruction: if (Services.NetworkService.scanning)
        Services.NetworkService.setScanning(false)

    LabelText {
        visible: Services.NetworkService.availability !== "available"
            || Services.NetworkService.freshness !== "current"
            || Services.NetworkService.lastError !== null
        text: `Network service: ${Services.NetworkService.availability}`
            + (Services.NetworkService.operationError ? ` — ${Services.NetworkService.operationError}` : "")
        color: Services.ThemeService.theme.tokens.warning
    }
    SectionTitle { text: "Active Connection" }
    RowLayout {
        Layout.fillWidth: true
        LabelText {
            id: activeAddress
            text: Services.NetworkService.connectionType === "wired"
                ? (Services.NetworkService.ipv4Address || "No LAN IP")
                : (Services.NetworkService.ssid || "No active connection")
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
        }
        Item {
            Layout.preferredWidth: 92
            Layout.maximumWidth: 92
            implicitHeight: activeStatus.implicitHeight
            Layout.alignment: Qt.AlignVCenter
            LabelText {
                id: activeStatus
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Services.NetworkService.summary
            }
        }
        Item {
            Layout.preferredWidth: 58
            Layout.maximumWidth: 58
            implicitHeight: activeMetricContent.implicitHeight
            Layout.alignment: Qt.AlignVCenter
            RowLayout {
                id: activeMetricContent
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                LabelText {
                    id: activeMetric
                    text: Services.NetworkService.connectionType === "wired"
                        ? (Services.NetworkService.linkSpeed > 0
                            ? `${Services.NetworkService.linkSpeed} Mbps` : "Unknown speed")
                        : `${Services.NetworkService.signalStrength}%`
                    elide: Text.ElideRight
                }
                Text {
                    visible: Services.NetworkService.connectionType !== "wired"
                    text: "signal_cellular_alt"
                    color: Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.iconFontFamily
                    font.pixelSize: Services.ConfigService.config.appearance.fontSize + 2
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            implicitHeight: activeDevice.implicitHeight
            Layout.alignment: Qt.AlignVCenter
            LabelText {
                id: activeDevice
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Services.NetworkService.selectedDeviceLabel
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }
    }

    ColumnLayout {
        visible: Services.NetworkService.wifiEnabled
        Layout.fillWidth: true
        spacing: root.spacing
        SectionTitle {
            text: "Visible Wi-Fi networks"
            Layout.topMargin: 12
        }
        LabelText { visible: Services.NetworkService.networks.length === 0; text: "No networks visible" }
        Repeater {
            model: Services.NetworkService.networks
            delegate: RowLayout {
            required property var modelData
            readonly property var row: modelData
            readonly property color rowTextColor: row.network.connected
                ? Services.ThemeService.theme.tokens.primary
                : Services.ThemeService.theme.tokens.on_surface_variant
            Layout.fillWidth: true
            spacing: 6
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                implicitHeight: identityContent.implicitHeight
                Layout.alignment: Qt.AlignVCenter
                ColumnLayout {
                    id: identityContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    LabelText {
                        text: row.name
                        color: row.network.connected
                            ? Services.ThemeService.theme.tokens.primary
                            : Services.ThemeService.theme.tokens.on_surface_variant
                        elide: Text.ElideRight
                    }
                    LabelText {
                        visible: row.profiles.length === 1
                        text: row.profiles.length === 1
                            ? `Saved profile: ${row.profiles[0].name}` : ""
                        font.pixelSize: Services.ConfigService.config.appearance.fontSize - 1
                        elide: Text.ElideRight
                    }
                    ComboBox {
                        visible: row.profiles.length > 1
                        Layout.fillWidth: true
                        model: row.profiles.map(profile => profile.name)
                        currentIndex: {
                            const selected = root.selectedProfile(row);
                            return selected ? row.profiles.indexOf(selected) : 0;
                        }
                        onActivated: root.selectProfile(row, currentIndex)
                    }
                }
            }
            Item {
                Layout.preferredWidth: 92
                Layout.maximumWidth: 92
                implicitHeight: securityLabel.implicitHeight
                Layout.alignment: Qt.AlignVCenter
                LabelText {
                    id: securityLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.securityText(row.network)
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                }
            }
            Item {
                Layout.preferredWidth: 58
                Layout.maximumWidth: 58
                implicitHeight: signalLabel.implicitHeight
                Layout.alignment: Qt.AlignVCenter
                RowLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    LabelText {
                        id: signalLabel
                        text: `${Math.round((row.network.signalStrength || 0) * 100)}%`
                    }
                    Text {
                        text: "signal_cellular_alt"
                        color: Services.ThemeService.theme.tokens.on_surface_variant
                        font.family: Services.ConfigService.config.appearance.iconFontFamily
                        font.pixelSize: Services.ConfigService.config.appearance.fontSize + 2
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                implicitHeight: actionContent.implicitHeight
                Layout.alignment: Qt.AlignVCenter
                RowLayout {
                    id: actionContent
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                Components.IconButton {
                    visible: row.network.known
                    Layout.preferredWidth: visible ? implicitWidth : 0
                    Layout.maximumWidth: visible ? implicitWidth : 0
                    iconName: "delete"
                    foregroundColor: Services.ThemeService.theme.tokens.error
                    borderColor: Services.ThemeService.theme.tokens.error
                    tooltipText: "Forget"
                    enabled: !root.rowPending(row)
                    onClicked: root.confirmForgetKey = root.confirmForgetKey === row.key ? "" : row.key
                }
                LabelText {
                    visible: root.confirmForgetKey === row.key
                    Layout.preferredWidth: visible ? implicitWidth : 0
                    Layout.maximumWidth: visible ? implicitWidth : 0
                    text: "Confirm?"
                }
                Components.IconButton {
                    visible: root.confirmForgetKey === row.key
                    Layout.preferredWidth: visible ? implicitWidth : 0
                    Layout.maximumWidth: visible ? implicitWidth : 0
                    iconName: "check"
                    foregroundColor: rowTextColor
                    borderColor: rowTextColor
                    tooltipText: "Confirm"
                    onClicked: {
                        Services.NetworkService.forget(root.selectedRow(row));
                        root.confirmForgetKey = "";
                    }
                }
                LabelText {
                    visible: row.network.stateChanging
                    Layout.preferredWidth: text.length > 0 ? implicitWidth : 0
                    Layout.maximumWidth: visible ? implicitWidth : 0
                    text: row.network.stateChanging ? "Connecting..." : ""
                }
                Components.IconButton {
                    visible: row.network.connected && root.securitySupported(row)
                    Layout.preferredWidth: visible ? implicitWidth : 0
                    Layout.maximumWidth: visible ? implicitWidth : 0
                    iconName: "link"
                    foregroundColor: Services.ThemeService.theme.tokens.success
                    borderColor: Services.ThemeService.theme.tokens.success
                    tooltipText: "Disconnect"
                    enabled: !root.rowPending(row)
                    onClicked: Services.NetworkService.disconnect(root.selectedRow(row))
                }
                Components.IconButton {
                    visible: !root.securitySupported(row)
                    Layout.preferredWidth: visible ? implicitWidth : 0
                    Layout.maximumWidth: visible ? implicitWidth : 0
                    iconName: "settings"
                    foregroundColor: rowTextColor
                    borderColor: rowTextColor
                    tooltipText: "Unsupported security — open NetworkManager editor"
                    onClicked: Services.NetworkService.openNetworkFallback(row)
                }
                LabelText {
                    visible: !root.securitySupported(row)
                    Layout.preferredWidth: visible ? implicitWidth : 0
                    Layout.maximumWidth: visible ? implicitWidth : 0
                    text: "Unsupported here — use nm-connection-editor"
                    color: Services.ThemeService.theme.tokens.warning
                }
                    RowLayout {
                        visible: root.pskKey === row.key
                        Layout.preferredWidth: visible ? implicitWidth : 0
                        Layout.maximumWidth: visible ? implicitWidth : 0
                        TextField {
                            id: psk
                            visible: root.pskKey === row.key
                            placeholderText: "Password"
                            placeholderTextColor: Services.ThemeService.theme.tokens.on_surface_placeholder
                            color: Services.ThemeService.theme.tokens.on_surface
                            selectionColor: Services.ThemeService.theme.tokens.primary
                            selectedTextColor: Services.ThemeService.theme.tokens.on_primary
                            font.family: Services.ConfigService.config.appearance.fontFamily
                            font.pixelSize: Services.ConfigService.config.appearance.fontSize
                            leftPadding: 16
                            rightPadding: 16
                            Layout.preferredHeight: 36
                            echoMode: TextInput.Password
                            implicitWidth: Math.ceil(passwordMetrics.width + leftPadding + rightPadding + 2)
                            Component.onCompleted: Qt.callLater(forceActiveFocus)
                            onVisibleChanged: if (visible) Qt.callLater(forceActiveFocus)
                            Keys.onEscapePressed: event => {
                                if (Services.SurfaceService.dashboardController)
                                    Services.SurfaceService.dashboardController.close();
                                event.accepted = true;
                            }
                            background: Rectangle {
                                radius: 6
                                color: Services.ThemeService.theme.tokens.surface
                                border.width: 1
                                border.color: Services.ThemeService.theme.tokens.outline
                            }
                            TextMetrics {
                                id: passwordMetrics
                                font: psk.font
                                text: psk.placeholderText
                            }
                        }
                        Components.IconButton {
                            iconName: "check"
                            foregroundColor: rowTextColor
                            borderColor: rowTextColor
                            tooltipText: "Confirm"
                            onClicked: {
                                Services.NetworkService.connect(root.selectedRow(row), psk.text);
                                psk.clear();
                                root.pskKey = "";
                            }
                        }
                    }
                Components.IconButton {
                    visible: !row.network.connected && root.securitySupported(row)
                    Layout.preferredWidth: visible ? implicitWidth : 0
                    Layout.maximumWidth: visible ? implicitWidth : 0
                    iconName: "link"
                    foregroundColor: rowTextColor
                    borderColor: rowTextColor
                    tooltipText: "Connect"
                    enabled: !root.rowPending(row)
                    onClicked: {
                        if (row.network.known || row.network.security === WifiSecurityType.Open)
                            Services.NetworkService.connect(root.selectedRow(row), "");
                        else root.pskKey = row.key;
                    }
                }
                }
            }
            }
        }
    }
    LabelText { visible: Services.NetworkService.fallbackError.length > 0; text: Services.NetworkService.fallbackError
        color: Services.ThemeService.theme.tokens.error }
}
