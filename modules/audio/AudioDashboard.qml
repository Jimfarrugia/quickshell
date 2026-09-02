import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../components" as Components

ColumnLayout {
    id: root
    spacing: 0

    function labelFor(node) {
        return node && (node.description || node.nickname || node.name) || "Unknown device";
    }
    function percentFor(node) {
        return node ? Services.AudioService.displayNodeVolumePercent(node) : 0;
    }

    component StateLabel: Text {
        color: Services.ThemeService.theme.tokens.on_surface_variant
        font.family: Services.ConfigService.config.appearance.fontFamily
        font.pixelSize: Services.ConfigService.config.appearance.fontSize
    }

    component SectionLabel: Text {
        color: Services.ThemeService.theme.tokens.on_surface
        font.family: Services.ConfigService.config.appearance.fontFamily
        font.pixelSize: Services.ConfigService.config.appearance.fontSize
        font.weight: Font.DemiBold
    }

    component DeviceRow: RowLayout {
        required property var modelData
        required property int index
        readonly property var node: modelData
        required property bool input
        property bool stream: false
        property bool showName: true
        property color nameColor: Services.ThemeService.theme.tokens.on_surface_variant
        Layout.fillWidth: true
        spacing: 8

        StateLabel {
            visible: parent.showName
            text: root.labelFor(parent.node)
            color: parent.nameColor
            font.pixelSize: Services.ConfigService.config.appearance.fontSize
            Layout.fillWidth: true
            Layout.preferredWidth: Math.max(0, root.width / 2 - 4)
            Layout.maximumWidth: Math.max(0, root.width / 2 - 4)
            elide: Text.ElideRight
        }
        Components.IconButton {
            iconName: parent.input ? "mic_off" : "volume_off"
            toggleable: true
            checked: parent.node ? Services.AudioService.displayNodeMuted(parent.node) : false
            toggleColor: Services.ThemeService.theme.tokens.error
            foregroundColor: Services.ThemeService.theme.palette.foreground
            borderColor: Services.ThemeService.theme.tokens.outline
            tooltipText: parent.node && Services.AudioService.displayNodeMuted(parent.node)
                ? "Unmute" : "Mute"
            onToggled: function(nextChecked) {
                Services.AudioService.setNodeMuted(parent.node, nextChecked);
            }
        }
        Slider {
            id: volumeSlider
            from: 0
            to: 200
            value: root.percentFor(parent.node)
            Layout.fillWidth: true
            Layout.preferredWidth: 110
            onMoved: Services.AudioService.setNodeVolume(parent.node, value)

            background: Rectangle {
                x: volumeSlider.leftPadding
                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                width: volumeSlider.availableWidth
                height: 6
                radius: height / 2
                color: Qt.rgba(Services.ThemeService.theme.tokens.surface_sidebar.r,
                    Services.ThemeService.theme.tokens.surface_sidebar.g,
                    Services.ThemeService.theme.tokens.surface_sidebar.b, 245 / 255)

                Rectangle {
                    width: volumeSlider.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: Services.ThemeService.theme.tokens.primary
                }
            }

            handle: Rectangle {
                x: volumeSlider.leftPadding
                    + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                width: 14
                height: 14
                radius: width / 2
                color: Services.ThemeService.theme.palette.foreground
                border.width: 1
                border.color: Services.ThemeService.theme.tokens.outline
            }
        }
        StateLabel {
            text: `${root.percentFor(parent.node)}%`
                + (parent.node === Services.AudioService.defaultOutput
                    && Services.AudioService.pendingVolumePercent >= 0 ? " pending" : "")
            Layout.alignment: Qt.AlignVCenter
        }
    }

    component DeviceSection: ColumnLayout {
        required property bool input
        readonly property var devices: input ? Services.AudioService.inputs
                                             : Services.AudioService.outputs
        readonly property var selectedNode: selector.currentIndex >= 0
            ? (devices[selector.currentIndex] || null) : null
        Layout.fillWidth: true
        spacing: 0

        SectionLabel {
            Layout.bottomMargin: 12
            text: parent.input
                ? (Services.AudioService.microphoneAvailability === "available"
                    ? "Inputs" : `Inputs unavailable (${Services.AudioService.microphoneAvailability})`)
                : (Services.AudioService.availability === "available"
                    ? "Outputs" : `Outputs unavailable (${Services.AudioService.availability})`)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ComboBox {
                id: selector
                Layout.fillWidth: true
                Layout.preferredWidth: Math.max(0, root.width / 2 - 4)
                Layout.maximumWidth: Math.max(0, root.width / 2 - 4)
                model: parent.parent.devices.map(node => root.labelFor(node))
                currentIndex: parent.parent.devices.length > 0
                    ? Math.max(0, parent.parent.devices.indexOf(
                        parent.parent.input ? Services.AudioService.defaultInput
                                             : Services.AudioService.defaultOutput)) : -1
                enabled: parent.parent.devices.length > 0
                onActivated: function(index) {
                    if (parent.parent.input)
                        Services.AudioService.setDefaultInput(parent.parent.devices[index]);
                    else Services.AudioService.setDefaultOutput(parent.parent.devices[index]);
                }

                contentItem: Text {
                    leftPadding: 12
                    rightPadding: 12
                    text: selector.currentIndex >= 0 ? selector.currentText : "No devices"
                    color: Services.ThemeService.theme.tokens.on_surface
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: Services.ConfigService.config.appearance.fontSize
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                background: Rectangle {
                    implicitHeight: 36
                    radius: Services.ConfigService.config.appearance.radius
                    color: Services.ThemeService.theme.tokens.background
                    border.width: Services.ConfigService.config.appearance.borderWidth
                    border.color: Services.ThemeService.theme.tokens.outline
                }
            }

            DeviceRow {
                visible: parent.parent.selectedNode !== null
                modelData: parent.parent.selectedNode
                input: parent.parent.input
                index: -1
                showName: false
                Layout.fillWidth: true
            }
        }

        StateLabel {
            visible: parent.devices.length === 0
            text: parent.input ? "No input devices" : "No output devices"
        }
    }

    StateLabel {
        visible: Services.AudioService.freshness !== "current"
            || Services.AudioService.lastError !== null
        text: `Audio service: ${Services.AudioService.freshness}`
            + (Services.AudioService.lastError ? ` (${Services.AudioService.lastError})` : "")
        color: Services.ThemeService.theme.tokens.warning
    }

    DeviceSection { input: false; Layout.bottomMargin: 20 }
    DeviceSection { input: true; Layout.bottomMargin: 20 }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        SectionLabel {
            text: "Applications"
            Layout.bottomMargin: 12
        }
        Repeater {
            model: Services.AudioService.playbackStreams
            delegate: DeviceRow {
                input: false
                stream: true
                nameColor: Services.ThemeService.theme.tokens.on_surface
                Layout.bottomMargin: index < Services.AudioService.playbackStreams.length - 1 ? 12 : 0
            }
        }
        StateLabel {
            visible: Services.AudioService.playbackStreams.length === 0
            text: "No active playback streams"
        }
    }

    StateLabel {
        visible: Services.AudioService.fallbackError.length > 0
        text: Services.AudioService.fallbackError
        color: Services.ThemeService.theme.tokens.error
    }
}
