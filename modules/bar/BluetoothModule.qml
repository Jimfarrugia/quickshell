import "../../components"
import "../../services" as Services

BarChip {
    property var sourceScreen: null
    property var dashboardController
    property string sourceSide: "right"
    readonly property bool shouldShow: Services.ConfigService.config.bar.enabled
        && Services.ConfigService.config.bar.bluetoothEnabled
    visible: shouldShow
    icon: !Services.BluetoothService.enabled ? "bluetooth_disabled"
        : (Services.BluetoothService.connectedCount > 0 ? "bluetooth_connected" : "bluetooth")
    iconColor: Services.BluetoothService.availability === "unavailable"
        ? Services.ThemeService.theme.tokens.error
        : (Services.BluetoothService.operation === "failed" || Services.BluetoothService.operationError.length > 0
            ? Services.ThemeService.theme.tokens.error
            : (Services.BluetoothService.freshness === "stale"
            ? Services.ThemeService.theme.tokens.warning
            : (Services.BluetoothService.operation === "pending"
                ? Services.ThemeService.theme.tokens.primary
                : (Services.BluetoothService.connectedCount > 0
                    ? Services.ThemeService.theme.tokens.success
                    : Services.ThemeService.theme.tokens.on_surface_indicator))))
    warning: Services.BluetoothService.operation === "pending"
    warningColor: Services.ThemeService.theme.tokens.primary
    hoverText: Services.BluetoothService.hoverText
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
    onClicked: if (dashboardController) {
        if (dashboardController.isOpen("bluetooth")) dashboardController.close();
        else {
            Services.SurfaceService.closeControlCenter();
            dashboardController.open("bluetooth", sourceScreen, sourceSide);
        }
    }
}
