import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services

ColumnLayout {
    id: root
    spacing: Services.ConfigService.config.appearance.spacing

    function labelFor(node) { return node.description || node.nickname || node.name || "Unknown device"; }
    function percentFor(node) {
        return Services.AudioService.displayNodeVolumePercent(node);
    }

    component StateLabel: Text {
        color: Services.ThemeService.theme.tokens.on_surface_variant
        font.family: Services.ConfigService.config.appearance.fontFamily
        font.pixelSize: Services.ConfigService.config.appearance.fontSize
    }

    component DeviceRow: RowLayout {
        required property var modelData
        readonly property var node: modelData
        required property bool input
        property bool stream: false
        Layout.fillWidth: true
        spacing: 8

        StateLabel { text: root.labelFor(parent.node); Layout.fillWidth: true; elide: Text.ElideRight }
        StateLabel {
            text: `${root.percentFor(parent.node)}%${Services.AudioService.displayNodeMuted(parent.node) ? " muted" : ""}`
                + (parent.node === Services.AudioService.defaultOutput
                    && Services.AudioService.pendingVolumePercent >= 0 ? " pending" : "")
        }
        Button {
            text: Services.AudioService.displayNodeMuted(parent.node) ? "Unmute" : "Mute"
            onClicked: Services.AudioService.setNodeMuted(parent.node, !Services.AudioService.displayNodeMuted(parent.node))
        }
        Button {
            visible: !parent.stream
            text: parent.input ? "Use input" : "Use output"
            enabled: parent.input ? Services.AudioService.defaultInput !== parent.node
                                  : Services.AudioService.defaultOutput !== parent.node
            onClicked: parent.input ? Services.AudioService.setDefaultInput(parent.node)
                                     : Services.AudioService.setDefaultOutput(parent.node)
        }
        Slider {
            from: 0; to: 200; value: root.percentFor(parent.node)
            Layout.preferredWidth: 110
            onMoved: Services.AudioService.setNodeVolume(parent.node, value)
        }
    }

    StateLabel {
        visible: Services.AudioService.freshness !== "current"
            || Services.AudioService.lastError !== null
        text: `Audio service: ${Services.AudioService.freshness}`
            + (Services.AudioService.lastError ? ` (${Services.AudioService.lastError})` : "")
        color: Services.ThemeService.theme.tokens.warning
    }

    StateLabel { text: Services.AudioService.availability === "available"
        ? "Outputs" : `Outputs unavailable (${Services.AudioService.availability})` }
    Repeater {
        model: Services.AudioService.outputs
        delegate: DeviceRow { input: false }
    }
    StateLabel { visible: Services.AudioService.outputs.length === 0; text: "No output devices" }

    StateLabel { text: Services.AudioService.microphoneAvailability === "available"
        ? "Inputs" : `Inputs unavailable (${Services.AudioService.microphoneAvailability})` }
    Repeater {
        model: Services.AudioService.inputs
        delegate: DeviceRow { input: true }
    }
    StateLabel { visible: Services.AudioService.inputs.length === 0; text: "No input devices" }

    StateLabel { text: "Applications" }
    Repeater {
        model: Services.AudioService.playbackStreams
        delegate: DeviceRow { input: false; stream: true }
    }
    StateLabel { visible: Services.AudioService.playbackStreams.length === 0; text: "No active playback streams" }

    StateLabel {
        visible: Services.AudioService.fallbackError.length > 0
        text: Services.AudioService.fallbackError
        color: Services.ThemeService.theme.tokens.error
    }
}
