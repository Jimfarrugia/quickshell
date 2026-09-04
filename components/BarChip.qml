import QtQuick
import QtQuick.Layouts
import "../services" as Services

Rectangle {
    id: root

    property alias text: label.text
    property alias icon: iconLabel.text
    property alias trailingText: trailingLabel.text
    property bool active: false
    property bool warning: false
    property string configuredFontFamily: "JetBrainsMono Nerd Font"
    property string configuredIconFontFamily: "Material Symbols Rounded"
    property real configuredFontSize: 14
    property real configuredIconSize: 16
    property real horizontalPadding: 8
    property real contentSpacing: 5
    property real iconSpacing: 5
    property real contentVerticalOffset: 0
    property color iconColor: active ? Services.ThemeService.theme.tokens.on_primary_container
                                     : Services.ThemeService.theme.tokens.secondary
    property color textColor: active ? Services.ThemeService.theme.tokens.on_primary_container
                                      : Services.ThemeService.theme.tokens.on_surface_disabled
    property color trailingTextColor: textColor
    property string hoverText: ""
    property color warningColor: Services.ThemeService.theme.tokens.warning
    property color backgroundColor: active ? Services.ThemeService.theme.tokens.primary_container
                                           : (pointerArea.pressed
                                               ? Services.ThemeService.theme.tokens.surface_pressed
                                               : (hover.hovered ? Services.ThemeService.theme.tokens.surface_hover : "transparent"))
    signal clicked()
    signal secondaryClicked()

    implicitWidth: content.implicitWidth + horizontalPadding * 2
    implicitHeight: 26
    radius: 7
    color: backgroundColor
    border.width: warning ? 1 : 0
    border.color: warningColor

    RowLayout {
        id: content
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.contentVerticalOffset
        height: parent.height
        spacing: 0

        Text {
            id: label
            visible: text.length > 0
            color: root.textColor
            font.family: root.configuredFontFamily
            font.pixelSize: root.configuredFontSize
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            visible: label.visible && trailingLabel.visible
            Layout.preferredWidth: root.contentSpacing
            Layout.preferredHeight: 1
        }

        Text {
            id: trailingLabel
            visible: text.length > 0
            color: root.trailingTextColor
            font.family: root.configuredFontFamily
            font.pixelSize: root.configuredFontSize
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            visible: iconLabel.visible && (label.visible || trailingLabel.visible)
            Layout.preferredWidth: root.iconSpacing
            Layout.preferredHeight: 1
        }

        Text {
            id: iconLabel
            visible: text.length > 0
            color: root.iconColor
            font.family: root.configuredIconFontFamily
            font.pixelSize: root.configuredIconSize
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    HoverHandler { id: hover }
    BarTooltip {
        anchorItem: root
        text: root.hoverText
        show: hover.hovered && root.hoverText.length > 0
    }
    MouseArea {
        id: pointerArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.secondaryClicked();
            else root.clicked();
        }
    }
}
