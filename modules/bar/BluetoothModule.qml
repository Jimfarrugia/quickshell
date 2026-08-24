import "../../components"
import "../../services" as Services

BarChip {
    readonly property bool shouldShow: Services.ConfigService.config.bar.enabled
        && Services.ConfigService.config.bar.bluetoothEnabled
    visible: shouldShow
    icon: !Services.BluetoothService.enabled ? "bluetooth_disabled"
        : (Services.BluetoothService.connectedCount > 0 ? "bluetooth_connected" : "bluetooth")
    iconColor: Services.BluetoothService.connectedCount > 0
        ? Services.ThemeService.theme.tokens.success
        : (Services.BluetoothService.enabled
            ? Services.ThemeService.theme.tokens.accentSecondary
            : Services.ThemeService.theme.tokens.error)
    warning: Services.BluetoothService.operation === "pending"
    hoverText: Services.BluetoothService.hoverText
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
}
