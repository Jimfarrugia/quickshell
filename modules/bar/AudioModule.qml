import QtQuick
import "../../components"
import "../../services" as Services

BarChip {
    property var sourceScreen: null
    property var dashboardController
    property string sourceSide: "right"
    function iconForVolume(volumePercent) {
        if (volumePercent <= 30) return "volume_mute";
        if (volumePercent <= 60) return "volume_down";
        return "volume_up";
    }

    visible: Services.AudioService.availability !== "unavailable"
    icon: Services.AudioService.muted ? "volume_off" : iconForVolume(Services.AudioService.displayVolumePercent)
    iconColor: Services.AudioService.muted ? Services.ThemeService.theme.tokens.error
                                           : Services.ThemeService.theme.tokens.secondary
    text: Services.AudioService.availability === "available"
        ? (Services.AudioService.muted ? "" : `${Services.AudioService.displayVolumePercent}%`)
        : "Audio..."
    warning: Services.AudioService.availability !== "available"
    hoverText: Services.AudioService.description
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
    onClicked: dashboardController.toggle("audio", sourceScreen, sourceSide)

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            Services.AudioService.wheelStep(event.angleDelta.y);
            event.accepted = true;
        }
    }
}
