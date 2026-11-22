pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import "../services" as Services

// Heading-styled picker with the ADR-021 vim keys. `model` is an array of
// { id, name }. Selection is one-way: the host binds `selectedId` and answers
// `selected(value)` by updating its own state, so its binding is never broken.
ComboBox {
    id: root

    property string selectedId: ""
    property string prefix: ""

    signal selected(string value)
    signal dismissRequested()
    signal leaveDown()

    implicitHeight: 26
    topPadding: 0
    bottomPadding: 0
    implicitWidth: contentItem.implicitWidth
    textRole: "name"
    valueRole: "id"
    currentIndex: Math.max(0, root.model.findIndex(option => option.id === root.selectedId))
    displayText: root.prefix.length > 0 ? `${root.prefix}: ${currentText}` : currentText
    font.family: Services.ConfigService.config.appearance.fontFamily
    font.pixelSize: 22
    font.weight: Font.DemiBold
    onActivated: root.selected(currentValue)

    Keys.onEscapePressed: {
        if (root.popup.visible) root.popup.close();
        else root.dismissRequested();
    }
    Keys.onPressed: function(event) {
        if (event.modifiers !== Qt.NoModifier) return;
        if (event.key === Qt.Key_Q) {
            root.dismissRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.popup.open();
            event.accepted = true;
        } else if (!root.popup.visible && event.key === Qt.Key_L) {
            root.popup.open();
            event.accepted = true;
        } else if (!root.popup.visible && event.key === Qt.Key_J) {
            root.leaveDown();
            event.accepted = true;
        }
    }
    // Swallow Enter's release so the press that closed the popup cannot reopen it.
    Keys.onReleased: function(event) {
        if (event.modifiers === Qt.NoModifier
                && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            event.accepted = true;
        }
    }

    indicator: Item {
        implicitWidth: 0
        implicitHeight: 0
    }

    contentItem: Text {
        leftPadding: 0
        text: root.displayText
        color: root.hovered || root.activeFocus
            ? Services.ThemeService.theme.tokens.link
            : Services.ThemeService.theme.tokens.on_surface_subdued
        font: root.font
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: "transparent"
        radius: Services.ConfigService.config.appearance.radius
    }

    delegate: ItemDelegate {
        id: optionDelegate
        required property var modelData
        required property int index
        readonly property bool selectedOption: root.currentIndex === index
        width: root.width
        implicitHeight: 38
        highlighted: optionsList.currentIndex === index
        text: modelData.name
        contentItem: Text {
            text: optionDelegate.modelData.name
            color: optionDelegate.selectedOption
                ? Services.ThemeService.theme.tokens.on_primary
                : Services.ThemeService.theme.tokens.on_surface
            font.family: root.font.family
            font.weight: root.font.weight
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            leftPadding: 12
        }
        background: Rectangle {
            color: optionDelegate.selectedOption
                ? Services.ThemeService.theme.tokens.primary
                : (optionDelegate.highlighted || optionDelegate.hovered
                    ? Services.ThemeService.theme.tokens.surface_hover
                    : Services.ThemeService.theme.tokens.surface)
        }
    }

    popup: Popup {
        id: optionsPopup
        y: root.height
        width: root.width
        padding: 4
        focus: true
        onOpened: Qt.callLater(optionsList.forceActiveFocus)
        onClosed: Qt.callLater(root.forceActiveFocus)

        contentItem: ListView {
            id: optionsList
            clip: true
            focus: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex

            function chooseCurrent() {
                root.selected(root.valueAt(currentIndex));
                optionsPopup.close();
            }

            Keys.onEscapePressed: optionsPopup.close()
            Keys.onPressed: function(event) {
                if (event.modifiers !== Qt.NoModifier && event.key !== Qt.Key_Escape)
                    return;
                if (event.key === Qt.Key_Q) {
                    root.dismissRequested();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape) {
                    optionsPopup.close();
                    event.accepted = true;
                } else if (event.key === Qt.Key_J) {
                    currentIndex = Math.min(currentIndex + 1, count - 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_H) {
                    optionsPopup.close();
                    event.accepted = true;
                } else if (event.key === Qt.Key_L) {
                    chooseCurrent();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K) {
                    currentIndex = Math.max(currentIndex - 1, 0);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    chooseCurrent();
                    event.accepted = true;
                }
            }
            Keys.onReleased: function(event) {
                if (event.modifiers === Qt.NoModifier
                        && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                    event.accepted = true;
                }
            }
        }

        background: Rectangle {
            color: Services.ThemeService.theme.tokens.surface
            border.width: Services.ConfigService.config.appearance.borderWidth
            border.color: Services.ThemeService.theme.tokens.outline_variant
            radius: Services.ConfigService.config.appearance.radius
        }
    }
}
