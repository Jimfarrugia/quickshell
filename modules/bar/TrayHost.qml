import QtQuick
import "../../services" as Services

Row {
    id: root
    property var parentWindow
    spacing: 3

    Repeater {
        model: Services.TrayService.items
        delegate: Item {
            id: trayItem
            required property var modelData

            width: 26
            height: 26

            Image {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: trayItem.modelData.icon
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
            }

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
