import QtQuick
import Quickshell
import Quickshell.Widgets
import "../services" as Services

PopupWindow {
    id: root

    required property Item anchorItem
    required property string text
    property bool show: false
    property bool delayedShow: false

    anchor {
        window: root.anchorItem.QsWindow.window
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.SlideX | PopupAdjustment.FlipY

        onAnchoring: {
            const contentItem = root.anchorItem.QsWindow.contentItem;
            if (!contentItem) return;
            const verticalPosition = Services.ConfigService.config.bar.edge === "top"
                ? root.anchorItem.height + 5
                : -root.height - 5;
            const position = contentItem.mapFromItem(
                root.anchorItem,
                root.anchorItem.width / 2 - root.width / 2,
                verticalPosition
            );
            anchor.rect.x = position.x;
            anchor.rect.y = position.y;
        }
    }
    color: "transparent"
    visible: delayedShow && text.length > 0
    implicitWidth: content.implicitWidth + 2
    implicitHeight: content.implicitHeight + 2

    onShowChanged: {
        if (show) showTimer.restart();
        else {
            showTimer.stop();
            delayedShow = false;
        }
    }

    Timer {
        id: showTimer
        interval: 350
        onTriggered: root.delayedShow = root.show
    }

    Text {
        id: textMeasure
        visible: false
        font: tooltipText.font
        text: root.text
        wrapMode: Text.NoWrap
    }

    Rectangle {
        id: content
        anchors.fill: parent
        anchors.margins: 1
        implicitWidth: Math.ceil(Math.min(textMeasure.implicitWidth + 16, 264))
        implicitHeight: Math.ceil(tooltipText.implicitHeight + 14)
        radius: 7
        color: Services.ThemeService.theme.tokens.tooltip
        border.width: 1
        border.color: Services.ThemeService.theme.tokens.border

        Text {
            id: tooltipText
            x: 8
            y: 8
            width: content.implicitWidth - 16
            text: root.text
            color: Services.ThemeService.theme.tokens.textPrimary
            font.family: Services.ConfigService.config.appearance.fontFamily
            font.pixelSize: 13
            lineHeight: 1.2
            lineHeightMode: Text.ProportionalHeight
            wrapMode: Text.Wrap
        }
    }
}
