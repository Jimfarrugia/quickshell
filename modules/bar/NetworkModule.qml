import "../../components"
import "../../services" as Services

BarChip {
    property var sourceScreen: null
    property var dashboardController
    property string sourceSide: "left"
    readonly property bool wifiConnected: Services.NetworkService.connectionType === "wifi"
    readonly property bool wiredConnected: Services.NetworkService.connectionType === "wired"

    text: wifiConnected ? Services.NetworkService.ssid
                        : (wiredConnected ? (Services.NetworkService.ipv4Address || "Connecting...") : "Disconnected")
    trailingText: wifiConnected ? `${Services.NetworkService.signalStrength}%` : ""
    icon: wifiConnected ? "wifi" : (wiredConnected ? "lan" : "signal_wifi_bad")
    textColor: wifiConnected ? Services.ThemeService.theme.tokens.primary
                             : Services.ThemeService.theme.tokens.on_surface_disabled
    trailingTextColor: Services.ThemeService.theme.tokens.on_surface_disabled
    iconColor: wifiConnected || wiredConnected ? Services.ThemeService.theme.tokens.secondary
                                               : Services.ThemeService.theme.tokens.error
    warning: false
    hoverText: Services.NetworkService.hoverText
    horizontalPadding: Services.ConfigService.config.bar.moduleSpacing / 2
    contentSpacing: Services.ConfigService.config.bar.moduleSpacing * 2
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
    onClicked: dashboardController.toggle("network", sourceScreen, sourceSide)
}
