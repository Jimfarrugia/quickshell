import QtQuick
import QtQuick.Layouts
import "../services" as Services

Rectangle {
    id: root

    property string iconName: ""
    property string title: ""
    property string valueText: ""
    property string statusText: ""
    property bool checked: false
    property bool alert: false
    property bool pending: false
    property bool primaryEnabled: true
    property bool secondaryEnabled: false
    property string tooltipText: ""
    property real contentPadding: 20
    property color activeColor: Services.ThemeService.theme.tokens.primary
    property color alertColor: Services.ThemeService.theme.tokens.error
    readonly property bool emphasized: root.checked || root.alert
    readonly property color emphasisColor: root.alert ? root.alertColor : root.activeColor
    signal clicked()
    signal secondaryClicked()
    signal wheelChanged(real angleDeltaY)

    implicitWidth: 52 + 12 + Math.max(titleLabel.implicitWidth, valueLabel.implicitWidth)
        + contentPadding * 2
    implicitHeight: 52 + contentPadding * 2
    radius: Services.ConfigService.config.appearance.radius
    color: pointer.pressed ? Services.ThemeService.theme.tokens.surface_pressed
        : (hover.hovered ? Services.ThemeService.theme.tokens.surface_hover
            : Services.ThemeService.theme.tokens.surface)
    border.width: Services.ConfigService.config.appearance.borderWidth
    border.color: root.pending ? Services.ThemeService.theme.tokens.warning
        : (root.emphasized ? root.emphasisColor : Services.ThemeService.theme.tokens.outline_variant)
    opacity: root.primaryEnabled || root.secondaryEnabled ? 1 : 0.55

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.contentPadding
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 52
            radius: width / 2
            color: root.emphasized ? root.emphasisColor
                : Services.ThemeService.theme.tokens.surface_variant
            border.width: Services.ConfigService.config.appearance.borderWidth
            border.color: root.emphasized ? root.emphasisColor
                : Services.ThemeService.theme.tokens.outline

            Text {
                anchors.centerIn: parent
                text: root.iconName
                color: root.emphasized ? Services.ThemeService.theme.tokens.on_primary
                    : Services.ThemeService.theme.tokens.on_surface
                font.family: Services.ConfigService.config.appearance.iconFontFamily
                font.pixelSize: 28
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                id: titleLabel
                Layout.fillWidth: true
                text: root.title
                color: Services.ThemeService.theme.tokens.on_surface
                font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            Text {
                id: valueLabel
                Layout.fillWidth: true
                text: root.pending ? "Pending..." : (root.valueText || root.statusText)
                color: root.pending ? Services.ThemeService.theme.tokens.warning
                    : Services.ThemeService.theme.tokens.on_surface_variant
                font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.secondaryEnabled) root.secondaryClicked();
            } else if (root.primaryEnabled) root.clicked();
        }
    }
    WheelHandler {
        enabled: root.primaryEnabled
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            root.wheelChanged(event.angleDelta.y);
            event.accepted = true;
        }
    }
}
