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
    property real contentVerticalOffset: -1
    property color iconColor: Services.ThemeService.theme.tokens.accentSecondary
    property color textColor: Services.ThemeService.theme.tokens.textSecondary
    property color trailingTextColor: Services.ThemeService.theme.tokens.textSecondary
    property color backgroundColor: active ? Services.ThemeService.theme.tokens.accentPrimary
                                           : (hover.hovered ? Services.ThemeService.theme.tokens.surfaceRaised : "transparent")
    signal clicked()
    signal secondaryClicked()

    implicitWidth: content.implicitWidth + horizontalPadding * 2
    implicitHeight: 26
    radius: 7
    color: backgroundColor
    border.width: warning ? 1 : 0
    border.color: Services.ThemeService.theme.tokens.warning

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
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.secondaryClicked();
            else root.clicked();
        }
    }
}
