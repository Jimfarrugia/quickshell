import "../../components"
import "../../services" as Services

BarChip {
    readonly property bool healthy: Services.CompositorService.availability === "available"
        && Services.AudioService.availability === "available"
        && Services.NetworkService.availability === "available"
    readonly property bool pending: Services.CompositorService.availability === "unknown"
        || Services.AudioService.availability === "unknown"
        || Services.NetworkService.availability === "unknown"

    visible: !healthy
    text: pending ? "Starting..." : "Degraded"
    warning: !pending
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
}
