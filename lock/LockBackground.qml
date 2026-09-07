import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    required property var lockTheme
    property string source: ""
    property int maxImageWidth: 3840
    property int maxImageHeight: 2160
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: root.lockTheme.tokens.background
    }

    Item {
        id: composition
        anchors.fill: parent
        visible: false

        Image {
            id: wallpaperImage
            anchors.fill: parent
            source: root.source
            sourceSize: Qt.size(root.maxImageWidth, root.maxImageHeight)
            fillMode: Image.PreserveAspectCrop
            autoTransform: true
            asynchronous: false
            cache: true
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 1.0; color: "#ff000000" }
            }
        }
    }

    GaussianBlur {
        anchors.fill: composition
        source: composition
        radius: 12
        samples: 25
        cached: true
        visible: wallpaperImage.status === Image.Ready
    }
}
