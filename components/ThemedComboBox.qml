import QtQuick
import QtQuick.Controls.Basic
import "../services" as Services

ComboBox {
    id: root

    implicitHeight: 36
    implicitWidth: 240
    property string placeholderText: "Select theme"
    font.family: Services.ConfigService.config.appearance.fontFamily
    font.pixelSize: Services.ConfigService.config.appearance.fontSize

    contentItem: Item {
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: arrow.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: root.currentIndex >= 0 ? root.currentText : root.placeholderText
            color: Services.ThemeService.theme.tokens.on_surface_variant
            font: root.font
            elide: Text.ElideRight
        }
        Text {
            id: arrow
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "arrow_drop_down"
            color: Services.ThemeService.theme.tokens.on_surface_disabled
            font.family: Services.ConfigService.config.appearance.iconFontFamily
            font.pixelSize: 24
        }
    }

    indicator: Item { implicitWidth: 0; implicitHeight: 0; width: 0; height: 0; visible: false }

    background: Rectangle {
        radius: 6
        color: root.popup.visible ? Services.ThemeService.theme.tokens.surface_pressed
            : (hover.hovered ? Services.ThemeService.theme.tokens.surface_hover
                : Services.ThemeService.theme.tokens.surface)
        border.width: Services.ConfigService.config.appearance.borderWidth
        border.color: Services.ThemeService.theme.tokens.on_surface_disabled
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    delegate: ItemDelegate {
        id: option
        width: root.width
        implicitHeight: 38
        highlighted: root.highlightedIndex === index
        text: root.textAt(index)
        contentItem: Text {
            text: option.text
            color: Services.ThemeService.theme.tokens.on_surface
            font.family: root.font.family
            font.pixelSize: root.font.pixelSize
            verticalAlignment: Text.AlignVCenter
            leftPadding: 12
        }
        background: Rectangle {
            color: option.pressed ? Services.ThemeService.theme.tokens.surface_pressed
                : (option.highlighted || option.hovered
                    ? Services.ThemeService.theme.tokens.surface_hover
                    : Services.ThemeService.theme.tokens.surface)
        }
    }

    popup: Popup {
        y: root.height
        width: root.width
        padding: 4
        focus: true

        contentItem: ListView {
            id: options
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            Keys.onEscapePressed: root.popup.close()
        }
        background: Rectangle {
            color: Services.ThemeService.theme.tokens.surface
            radius: 6
            border.width: Services.ConfigService.config.appearance.borderWidth
            border.color: Services.ThemeService.theme.tokens.outline_variant
        }
        onOpened: Qt.callLater(options.forceActiveFocus)
        onClosed: Qt.callLater(root.forceActiveFocus)
    }
}
