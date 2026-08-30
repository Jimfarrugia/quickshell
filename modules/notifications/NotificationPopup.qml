import QtQuick
import QtQuick.Layouts
import "../../services" as Services

Item {
    id: root

    required property var record
    property real contentWidth: 360
    implicitWidth: contentWidth
    implicitHeight: card.implicitHeight

    function restartAutoDismiss() {
        if (record && record.data.urgency !== "critical") autoDismiss.restart();
        else autoDismiss.stop();
    }

    function formatNotificationTime(timestamp) {
        const value = Number(timestamp);
        if (!Number.isFinite(value)) return "";
        return Qt.formatTime(new Date(value), "hh:mm");
    }

    Rectangle {
        id: card
        width: root.width
        implicitHeight: cardLayout.implicitHeight + 24
        radius: Services.ConfigService.config.appearance.radius
        color: Services.ThemeService.theme.tokens.background
        border.width: 1
        border.color: root.record.data.urgency === "critical"
            ? Services.ThemeService.theme.tokens.error : Services.ThemeService.theme.tokens.outline_variant

        MouseArea {
            id: dismissArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: Services.NotificationService.dismiss(root.record.data.id)
        }

        RowLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Item {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 96
                Layout.preferredHeight: 96
                Layout.minimumWidth: 96
                Layout.minimumHeight: 96
                Layout.maximumWidth: 96
                Layout.maximumHeight: 96
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: Math.min(96, implicitWidth)
                    height: Math.min(96, implicitHeight)
                    visible: root.record.data.image.length > 0
                    source: root.record.data.image
                    sourceSize.width: 96
                    sourceSize.height: 96
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                }

                Text {
                    anchors.fill: parent
                    visible: root.record.data.image.length === 0
                    text: root.record.data.iconName
                    color: root.record.data.urgency === "critical"
                        ? Services.ThemeService.theme.tokens.error
                        : Services.ThemeService.theme.tokens.outline_variant
                    font.family: Services.ConfigService.config.appearance.iconFontFamily
                    font.pixelSize: 64
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

            }

            ColumnLayout {
                id: content
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 12
                    text: root.record.data.summary
                    color: Services.ThemeService.theme.tokens.on_surface
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 12
                    visible: text.length > 0
                    clip: true
                    text: root.record.data.body
                    textFormat: root.record.data.isScreenshot ? Text.PlainText : Text.RichText
                    color: Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 14
                    wrapMode: root.record.data.isScreenshot ? Text.NoWrap : Text.WordWrap
                    maximumLineCount: root.record.data.isScreenshot ? 1 : 0
                    elide: root.record.data.isScreenshot ? Text.ElideMiddle : Text.ElideNone
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 12
                    columns: 2
                    columnSpacing: 6
                    rowSpacing: 4
                    visible: actionRepeater.count > 0

                    Repeater {
                        id: actionRepeater
                        model: root.record.data.actions
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.columnSpan: actionRepeater.count === 1 ? 2 : 1
                            implicitHeight: 28
                            radius: 5
                            color: actionHover.hovered
                                ? Services.ThemeService.theme.tokens.surface_hover
                                : Services.ThemeService.theme.tokens.surface_variant

                            Text {
                                anchors.centerIn: parent
                                text: modelData.text
                                color: Services.ThemeService.theme.tokens.on_surface_variant
                                font.family: Services.ConfigService.config.appearance.fontFamily
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                            HoverHandler { id: actionHover }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: Services.NotificationService.invokeAction(
                                    root.record.data.id, modelData.identifier)
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.record.data.appName
                        color: Services.ThemeService.theme.tokens.on_surface_disabled
                        font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.formatNotificationTime(root.record.data.receivedAt)
                        color: Services.ThemeService.theme.tokens.on_surface_disabled
                        font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }

}
