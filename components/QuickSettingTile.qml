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
    readonly property bool actionAvailable: root.primaryEnabled || root.secondaryEnabled
    readonly property color resolvedBorderColor: root.pending
        ? Services.ThemeService.theme.tokens.primary
        : (!root.actionAvailable ? Services.ThemeService.theme.tokens.outline_variant
            : (root.checked ? Services.ThemeService.theme.tokens.primary
                : (root.alert ? Services.ThemeService.theme.tokens.error
                    : Services.ThemeService.theme.tokens.outline_variant)))
    readonly property color resolvedIconBackgroundColor: root.pending
        ? Services.ThemeService.theme.tokens.primary
        : (root.checked ? Services.ThemeService.theme.tokens.primary_container
            : Services.ThemeService.theme.tokens.surface_variant)
    readonly property color resolvedIconColor: root.pending
        ? Services.ThemeService.theme.tokens.on_primary
        : (!root.actionAvailable ? Services.ThemeService.theme.tokens.on_surface_disabled
            : (root.checked ? Services.ThemeService.theme.tokens.on_primary_container
                : (root.alert ? Services.ThemeService.theme.tokens.error
                    : Services.ThemeService.theme.tokens.on_surface_variant)))
    readonly property color resolvedTitleColor: root.actionAvailable
        ? Services.ThemeService.theme.tokens.on_surface
        : Services.ThemeService.theme.tokens.on_surface_disabled
    readonly property color resolvedValueColor: !root.actionAvailable
        ? Services.ThemeService.theme.tokens.on_surface_disabled
        : (root.pending ? Services.ThemeService.theme.tokens.primary
            : Services.ThemeService.theme.tokens.on_surface_subdued)
    signal clicked()
    signal secondaryClicked()
    signal wheelChanged(real angleDeltaY)

    implicitWidth: 52 + 12 + Math.max(titleLabel.implicitWidth, valueLabel.implicitWidth)
        + contentPadding * 2
    implicitHeight: 52 + contentPadding * 2
    radius: Services.ConfigService.config.appearance.radius
    color: pointer.pressed && root.actionAvailable && !root.pending
        ? Services.ThemeService.theme.tokens.surface_pressed
        : (hover.hovered && root.actionAvailable && !root.pending
            ? Services.ThemeService.theme.tokens.surface_hover
            : Services.ThemeService.theme.tokens.surface)
    border.width: Services.ConfigService.config.appearance.borderWidth
    border.color: root.resolvedBorderColor

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.contentPadding
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 52
            radius: width / 2
            color: root.resolvedIconBackgroundColor
            border.width: Services.ConfigService.config.appearance.borderWidth
            border.color: root.checked ? Services.ThemeService.theme.tokens.primary
                : (root.alert ? Services.ThemeService.theme.tokens.error
                    : Services.ThemeService.theme.tokens.outline)

            Text {
                anchors.centerIn: parent
                text: root.iconName
                color: root.resolvedIconColor
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
                color: root.resolvedTitleColor
                font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            Text {
                id: valueLabel
                Layout.fillWidth: true
                text: root.pending ? "Pending..." : (root.valueText || root.statusText)
                color: root.resolvedValueColor
                font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }

    HoverHandler {
        id: hover
        enabled: root.actionAvailable && !root.pending
        cursorShape: Qt.PointingHandCursor
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.actionAvailable && !root.pending
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.secondaryEnabled) root.secondaryClicked();
            } else if (root.primaryEnabled && !root.pending) root.clicked();
        }
    }
    WheelHandler {
        enabled: root.primaryEnabled && !root.pending
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            root.wheelChanged(event.angleDelta.y);
            event.accepted = true;
        }
    }
}
