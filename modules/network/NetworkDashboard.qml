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
    RowLayout {
        Layout.fillWidth: true
        SectionTitle { text: Services.NetworkService.summary; Layout.fillWidth: true }
         LabelText { text: Services.NetworkService.connectionType === "wired"
                 ? `Wired (${Services.NetworkService.interfaceName})`
                 : (Services.NetworkService.ssid || (Services.NetworkService.selectedDeviceConnected
                     ? "No active connection" : `Disconnected · ${Services.NetworkService.selectedDeviceLabel}`)) }
    }
    RowLayout {
        Layout.fillWidth: true
        LabelText { text: "Wi-Fi"; Layout.fillWidth: true }
        Switch {
            checked: Services.NetworkService.wifiTogglePending
                ? Services.NetworkService.pendingWifiEnabled : Services.NetworkService.wifiEnabled
            enabled: Services.NetworkService.availability === "available"
                && Services.NetworkService.wifiHardwareEnabled
            onToggled: Services.NetworkService.setWifiEnabled(checked)
        }
        Components.IconButton {
            iconName: "refresh"
            enabled: Services.NetworkService.availability === "available"
            tooltipText: "Refresh Wi-Fi networks"
            onClicked: Services.NetworkService.refreshScan()
        }
    }

     SectionTitle { text: `Visible Wi-Fi networks · ${Services.NetworkService.selectedDeviceLabel}`; Layout.topMargin: 12 }
    LabelText { visible: Services.NetworkService.networks.length === 0; text: "No networks visible" }
    Repeater {
        model: Services.NetworkService.networks
        delegate: RowLayout {
            required property var modelData
            readonly property var row: modelData
            Layout.fillWidth: true
            spacing: 6
            ColumnLayout {
                Layout.fillWidth: true
                LabelText { text: row.name; color: row.network.connected
                        ? Services.ThemeService.theme.tokens.primary
                        : Services.ThemeService.theme.tokens.on_surface_variant }
                LabelText { text: `${root.securityText(row.network)} · ${Math.round((row.network.signalStrength || 0) * 100)}%`
                    font.pixelSize: Services.ConfigService.config.appearance.fontSize - 1 }
                  LabelText { visible: row.profiles.length === 1
                      text: row.profiles.length === 1 ? `Saved profile: ${row.profiles[0].name}` : ""; font.pixelSize: 11 }
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
            LabelText { text: row.network.stateChanging ? "Connecting..."
                    : (row.network.connected ? "Connected" : "") }
            Components.IconButton {
                visible: row.network.connected && root.securitySupported(row)
                iconName: "link"
                tooltipText: "Disconnect"
                enabled: !root.rowPending(row)
                 onClicked: Services.NetworkService.disconnect(root.selectedRow(row))
            }
            Components.IconButton {
                visible: !row.network.connected && root.securitySupported(row)
                iconName: "link"
                tooltipText: row.network.known ? "Connect" : "Connect"
                enabled: !root.rowPending(row)
                onClicked: {
                    if (row.network.known || row.network.security === WifiSecurityType.Open)
                         Services.NetworkService.connect(root.selectedRow(row), "");
                    else root.pskKey = row.key;
                }
            }
            Components.IconButton {
                visible: !root.securitySupported(row)
                iconName: "settings"
                tooltipText: "Unsupported security — open NetworkManager editor"
                onClicked: Services.NetworkService.openNetworkFallback(row)
            }
            LabelText {
                visible: !root.securitySupported(row)
                text: "Unsupported here — use nm-connection-editor"
                color: Services.ThemeService.theme.tokens.warning
            }
            Components.IconButton {
                visible: row.network.known
                iconName: "delete"
                tooltipText: "Forget saved profiles"
                enabled: !root.rowPending(row)
                 onClicked: root.confirmForgetKey = root.confirmForgetKey === row.key ? "" : row.key
            }
            LabelText { visible: root.confirmForgetKey === row.key; text: "Confirm?" }
            Components.IconButton {
                visible: root.confirmForgetKey === row.key
                iconName: "check"
                tooltipText: "Confirm forget all saved profiles"
                 onClicked: { Services.NetworkService.forget(root.selectedRow(row)); root.confirmForgetKey = ""; }
            }
            RowLayout {
                visible: root.pskKey === row.key
                TextField { id: psk; placeholderText: "Wi-Fi password"; echoMode: TextInput.Password; implicitWidth: 130 }
                Components.IconButton {
                    iconName: "check"; tooltipText: "Connect"
                     onClicked: { Services.NetworkService.connect(root.selectedRow(row), psk.text); psk.clear(); root.pskKey = ""; }
                }
            }
        }
    }
    LabelText { visible: Services.NetworkService.connectionType === "wired"; text: "Wired networking is read-only here." }
    LabelText { visible: Services.NetworkService.fallbackError.length > 0; text: Services.NetworkService.fallbackError
        color: Services.ThemeService.theme.tokens.error }
}
