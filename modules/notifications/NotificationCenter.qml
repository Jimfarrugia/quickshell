import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import "../../components" as Components
import "../../services" as Services

Components.Sidebar {
    id: root

    function updatePopupPolicy() {
        Services.NotificationService.setPopupsBlocked(root.visible
            && historyList.atYBeginning && !root.preserveHistoryScroll);
    }

    property bool preserveHistoryScroll: false
    property real historyScrollY: 0
    property real historyContentHeight: 0
    property int notificationsBelowFold: 0
    property bool criticalFirst: false

    readonly property var displayedHistory: root.historyForView(
        Services.NotificationService.history)

    function historyForView(records) {
        if (!root.criticalFirst) return records;
        const critical = [];
        const other = [];
        for (const record of records) {
            if (record.data.urgency === "critical") critical.push(record);
            else other.push(record);
        }
        return critical.concat(other);
    }

    function scheduleNotificationsBelowFoldUpdate() {
        notificationsBelowFoldTimer.restart();
    }

    function updateNotificationsBelowFold() {
        const count = historyList.count;
        if (count === 0 || historyList.height <= 0) {
            root.notificationsBelowFold = 0;
            return;
        }

        let lastVisibleIndex = -1;
        for (let index = 0; index < count; index++) {
            const item = historyList.itemAtIndex(index);
            if (!item) continue;
            const itemTop = historyList.mapFromItem(item, 0, 0).y;
            const itemBottom = itemTop + item.height;
            if (itemTop < historyList.height && itemBottom > 0)
                lastVisibleIndex = index;
        }
        root.notificationsBelowFold = lastVisibleIndex < 0
            ? 0 : Math.max(0, count - lastVisibleIndex - 1);
    }

    function captureHistoryScroll() {
        if (historyList.atYBeginning || root.preserveHistoryScroll) return;
        root.preserveHistoryScroll = true;
        root.historyScrollY = historyList.contentY;
        root.historyContentHeight = historyList.contentHeight;
    }

    function restoreHistoryScroll() {
        if (!root.preserveHistoryScroll) return;
        Qt.callLater(function() {
            if (!root.preserveHistoryScroll) return;
            const heightDelta = historyList.contentHeight - root.historyContentHeight;
            historyList.contentY = Math.max(0, root.historyScrollY + heightDelta);
            root.preserveHistoryScroll = false;
            root.updatePopupPolicy();
            root.scheduleNotificationsBelowFoldUpdate();
        });
    }

    function formatNotificationTime(timestamp) {
        const value = Number(timestamp);
        if (!Number.isFinite(value)) return "";
        return Qt.formatTime(new Date(value), "hh:mm");
    }

    onClosed: {
        Services.NotificationService.setPopupsBlocked(false);
        Services.SurfaceService.closeNotificationCenter();
    }
    Component.onCompleted: {
        root.updatePopupPolicy();
        root.scheduleNotificationsBelowFoldUpdate();
    }
    Component.onDestruction: {
        if (!Services.SurfaceService.notificationCenterVisible)
            Services.NotificationService.setPopupsBlocked(false);
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                spacing: 12
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: "Notifications"
                    color: Services.ThemeService.theme.tokens.on_surface_panel
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                }
                Components.IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    iconName: "clear_all"
                    foregroundColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    borderColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    onClicked: Services.NotificationService.clearHistory()
                }
                Components.IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    iconName: "warning"
                    toggleable: true
                    checked: root.criticalFirst
                    toggleColor: Services.ThemeService.theme.tokens.warning
                    foregroundColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    borderColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    onToggled: function(nextChecked) {
                        root.criticalFirst = nextChecked;
                    }
                }
                Components.IconButton {
                    id: dndToggle
                    Layout.alignment: Qt.AlignVCenter
                    iconName: "do_not_disturb_on"
                    toggleable: true
                    checked: Services.NotificationService.dnd
                    toggleColor: Services.ThemeService.theme.tokens.warning
                    foregroundColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    borderColor: Services.ThemeService.theme.tokens.on_surface_disabled
                    onToggled: function(nextChecked) {
                        Services.NotificationService.setDnd(nextChecked);
                    }
                }
            }

            ListView {
                id: historyList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 12
                model: root.displayedHistory
                onAtYBeginningChanged: root.updatePopupPolicy()
                onContentYChanged: {
                    root.updatePopupPolicy();
                    root.scheduleNotificationsBelowFoldUpdate();
                }
                onContentHeightChanged: root.scheduleNotificationsBelowFoldUpdate()
                onCountChanged: root.scheduleNotificationsBelowFoldUpdate()
                onHeightChanged: root.scheduleNotificationsBelowFoldUpdate()
                onWidthChanged: root.scheduleNotificationsBelowFoldUpdate()
                Connections {
                    target: Services.NotificationService
                    function onHistoryAboutToChange() { root.captureHistoryScroll(); }
                    function onHistoryChanged() {
                        root.restoreHistoryScroll();
                        root.scheduleNotificationsBelowFoldUpdate();
                    }
                }

                delegate: Rectangle {
                    id: historyDelegate
                    required property var modelData
                    width: Math.min(historyList.width, 384)
                    x: (historyList.width - width) / 2
                    implicitHeight: historyLayout.implicitHeight + 24
                    radius: Services.ConfigService.config.appearance.radius
                    color: Services.ThemeService.theme.tokens.background
                    border.width: modelData.data.urgency === "critical" ? 1 : 0
                    border.color: modelData.data.urgency === "critical"
                        ? Services.ThemeService.theme.tokens.error : Services.ThemeService.theme.tokens.outline_variant

                    RowLayout {
                        id: historyLayout
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
                                visible: modelData.data.image.length > 0
                                source: modelData.data.image
                                sourceSize.width: 96
                                sourceSize.height: 96
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: false
                            }

                            Text {
                                anchors.fill: parent
                                visible: modelData.data.image.length === 0
                                text: modelData.data.iconName
                                color: modelData.data.urgency === "critical"
                                    ? Services.ThemeService.theme.tokens.error
                                    : Services.ThemeService.theme.tokens.on_surface_disabled
                                font.family: Services.ConfigService.config.appearance.iconFontFamily
                                font.pixelSize: 64
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                        }

                        ColumnLayout {
                            id: historyContent
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.bottomMargin: 12
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignTop
                                    text: modelData.data.summary
                                    color: Services.ThemeService.theme.tokens.on_surface_variant
                                    font.family: Services.ConfigService.config.appearance.fontFamily
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.WordWrap
                                }

                                Item {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.preferredWidth: 12
                                    Layout.preferredHeight: 12
                                    Layout.minimumWidth: 12
                                    Layout.minimumHeight: 12
                                    Layout.maximumWidth: 12
                                    Layout.maximumHeight: 12

                                    Text {
                                        anchors.fill: parent
                                        text: "close"
                                        color: Services.ThemeService.theme.tokens.on_surface_disabled
                                        font.family: Services.ConfigService.config.appearance.iconFontFamily
                                        font.pixelSize: 18
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: Services.NotificationService.removeFromHistory(modelData.data.id)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.bottomMargin: 12
                                visible: text.length > 0
                                clip: true
                                text: modelData.data.body
                                textFormat: modelData.data.isScreenshot ? Text.PlainText : Text.RichText
                                color: Services.ThemeService.theme.tokens.on_surface_variant
                                font.family: Services.ConfigService.config.appearance.fontFamily
                                font.pixelSize: 14
                                wrapMode: modelData.data.isScreenshot ? Text.NoWrap : Text.WordWrap
                                maximumLineCount: modelData.data.isScreenshot ? 1 : 0
                                elide: modelData.data.isScreenshot ? Text.ElideMiddle : Text.ElideNone
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
                                    model: modelData.data.actions
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
                                        }
                                        HoverHandler { id: actionHover }
                                        TapHandler {
                                            onTapped: Services.NotificationService.invokeAction(
                                                historyDelegate.modelData.data.id, modelData.identifier)
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
                                    text: modelData.data.appName
                                    color: Services.ThemeService.theme.tokens.on_surface_disabled
                                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: root.formatNotificationTime(modelData.data.receivedAt)
                                    color: Services.ThemeService.theme.tokens.on_surface_disabled
                                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: historyList.count === 0
                    text: "History is empty."
                    color: Services.ThemeService.theme.tokens.on_surface_placeholder
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 14
                }
            }
        }

        Timer {
            id: notificationsBelowFoldTimer
            interval: 0
            repeat: false
            onTriggered: root.updateNotificationsBelowFold()
        }

        Rectangle {
            id: infoPill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            z: 1
            visible: root.notificationsBelowFold > 0
            implicitWidth: infoContent.implicitWidth + 24
            implicitHeight: 32
            radius: height / 2
            color: Services.ThemeService.theme.tokens.surface_hover

            Shape {
                id: infoPillTopBorder
                anchors.fill: parent
                property real borderInset: 0.5
                property real borderRadius: infoPill.radius - borderInset
                property real cornerControl: borderRadius * 0.5522848
                property color borderSource: Services.ThemeService.theme.tokens.outline
                z: 1

                ShapePath {
                    strokeColor: Qt.rgba(
                        infoPillTopBorder.borderSource.r,
                        infoPillTopBorder.borderSource.g,
                        infoPillTopBorder.borderSource.b,
                        0.3)
                    strokeWidth: 1
                    fillColor: "transparent"
                    capStyle: ShapePath.FlatCap
                    joinStyle: ShapePath.RoundJoin
                    startX: infoPillTopBorder.borderInset
                    startY: infoPill.radius

                    PathCubic {
                        x: infoPill.radius
                        y: infoPillTopBorder.borderInset
                        control1X: infoPillTopBorder.borderInset
                        control1Y: infoPill.radius - infoPillTopBorder.cornerControl
                        control2X: infoPill.radius - infoPillTopBorder.cornerControl
                        control2Y: infoPillTopBorder.borderInset
                    }
                    PathLine {
                        x: infoPill.width - infoPill.radius
                        y: infoPillTopBorder.borderInset
                    }
                    PathCubic {
                        x: infoPill.width - infoPillTopBorder.borderInset
                        y: infoPill.radius
                        control1X: infoPill.width - infoPill.radius
                            + infoPillTopBorder.cornerControl
                        control1Y: infoPillTopBorder.borderInset
                        control2X: infoPill.width - infoPillTopBorder.borderInset
                        control2Y: infoPill.radius - infoPillTopBorder.cornerControl
                    }
                }
            }

            Row {
                id: infoContent
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "keyboard_arrow_down"
                    color: Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.iconFontFamily
                    font.pixelSize: 24
                    height: infoPill.height
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: root.notificationsBelowFold
                    color: Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 14
                    height: infoPill.height
                    rightPadding: 6
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        RectangularShadow {
            anchors.fill: infoPill
            offset: Qt.vector2d(0, 4)
            color: Services.ThemeService.theme.tokens.shadow
            blur: 24
            radius: infoPill.radius
            spread: 0
            visible: infoPill.visible && Services.ConfigService.config.appearance.shadows
        }
    }
}
