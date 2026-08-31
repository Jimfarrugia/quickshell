import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import "../../services" as Services

Item {
    id: root
    property var item: null
    readonly property real meterSurfaceWidth: 330
    readonly property real surfaceWidth: root.meter
        ? root.meterSurfaceWidth
        : 16 + 24 + 12 + body.implicitWidth + 16
    readonly property real surfaceHeight: 56
    readonly property bool meter: root.item
        && root.item.state !== "failed"
        && !(root.item.replacementKey === "audio" && root.item.detail === "Muted")
        && ["audio", "brightness", "keyboard-brightness", "battery"].indexOf(root.item.replacementKey) >= 0
    implicitWidth: root.surfaceWidth
    implicitHeight: root.surfaceHeight

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: root.surfaceWidth
        height: root.surfaceHeight
        z: 1
        radius: Services.ConfigService.config.appearance.radius + 2
        color: Services.ThemeService.theme.tokens.surface

        Shape {
            id: topBorder
            anchors.fill: parent
            property real borderInset: 0.5
            property real borderRadius: card.radius - borderInset
            property real cornerControl: borderRadius * 0.5522848
            property color borderSource: Services.ThemeService.theme.tokens.outline
            z: 1

            ShapePath {
                strokeColor: Qt.rgba(
                    topBorder.borderSource.r,
                    topBorder.borderSource.g,
                    topBorder.borderSource.b,
                    0.3)
                strokeWidth: 1
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                joinStyle: ShapePath.RoundJoin
                startX: topBorder.borderInset
                startY: card.radius

                PathCubic {
                    x: card.radius
                    y: topBorder.borderInset
                    control1X: topBorder.borderInset
                    control1Y: card.radius - topBorder.cornerControl
                    control2X: card.radius - topBorder.cornerControl
                    control2Y: topBorder.borderInset
                }
                PathLine {
                    x: card.width - card.radius
                    y: topBorder.borderInset
                }
                PathCubic {
                    x: card.width - topBorder.borderInset
                    y: card.radius
                    control1X: card.width - card.radius + topBorder.cornerControl
                    control1Y: topBorder.borderInset
                    control2X: card.width - topBorder.borderInset
                    control2Y: card.radius - topBorder.cornerControl
                }
            }
        }

        RowLayout {
            id: content
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: root.item ? root.item.icon : "info"
                color: Services.ThemeService.theme.tokens.on_surface
                font.family: Services.ConfigService.config.appearance.iconFontFamily
                font.pixelSize: 24
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
            }

            Text {
                id: body
                Layout.fillWidth: true
                visible: !root.meter
                text: root.item ? root.item.detail : ""
                color: Services.ThemeService.theme.tokens.on_surface
                font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                id: progressTrack
                visible: root.meter
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 6
                Layout.minimumWidth: 0
                radius: height / 2
                color: Qt.rgba(Services.ThemeService.theme.tokens.surface_sidebar.r,
                    Services.ThemeService.theme.tokens.surface_sidebar.g,
                    Services.ThemeService.theme.tokens.surface_sidebar.b, 245 / 255)

                Rectangle {
                    width: root.item ? parent.width * Math.max(0, Math.min(100, root.item.value)) / 100 : 0
                    height: parent.height
                    radius: parent.radius
                    color: Services.ThemeService.theme.tokens.primary
                }
            }

            Text {
                visible: root.meter
                Layout.alignment: Qt.AlignVCenter
                text: root.item && root.item.value >= 0 ? `${root.item.value}%` : ""
                color: Services.ThemeService.theme.tokens.on_surface
                font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: 14
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                Layout.preferredWidth: 42
            }
        }
    }

    RectangularShadow {
        anchors.fill: card
        z: 0
        offset: Qt.vector2d(0, 4)
        color: Services.ThemeService.theme.tokens.shadow
        blur: 24
        radius: card.radius
        spread: 0
        visible: Services.ConfigService.config.appearance.shadows
    }
}
