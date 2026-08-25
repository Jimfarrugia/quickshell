import QtQuick
import QtQuick.Effects
import "../../services" as Services

Row {
    id: root
    property var parentWindow
    property var items: Services.TrayService.items
    property var tintedItemIds: ["nextcloud"]
    property real itemHorizontalPadding: 8
    spacing: Services.ConfigService.config.bar.moduleSpacing

    function shouldTint(item) {
        const identifier = String(item.id || item.title || "").toLowerCase();
        return tintedItemIds.indexOf(identifier) !== -1;
    }

    function itemAt(index) {
        return trayRepeater.itemAt(index);
    }

    function hoverBackground(hovered) {
        return hovered ? Services.ThemeService.theme.tokens.surface_hover : "transparent";
    }

    Repeater {
        id: trayRepeater
        model: root.items
        delegate: Rectangle {
            id: trayItem
            required property var modelData
            readonly property bool themedIcon: root.shouldTint(modelData)
            readonly property string iconSource: modelData.icon
            readonly property color tintColor: Services.ThemeService.theme.tokens.secondary

            width: 18 + root.itemHorizontalPadding * 2
            height: 26
            radius: 7
            color: root.hoverBackground(trayHover.hovered)

            Image {
                id: nativeIcon
                anchors.centerIn: parent
                width: 18
                height: 18
                source: trayItem.modelData.icon
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                visible: !trayItem.themedIcon
            }

            MultiEffect {
                anchors.fill: nativeIcon
                source: nativeIcon
                visible: trayItem.themedIcon
                colorization: 1
                colorizationColor: trayItem.tintColor
                autoPaddingEnabled: false
            }

            HoverHandler { id: trayHover }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        const position = trayItem.mapToItem(root.parentWindow.contentItem, 0, 0);
                        if (trayItem.modelData.hasMenu)
                            trayItem.modelData.display(root.parentWindow, position.x, position.y + trayItem.height);
                        else trayItem.modelData.secondaryActivate();
                    } else trayItem.modelData.activate();
                }
                onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y / 8, false)
            }
        }
    }
}
