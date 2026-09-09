import QtQuick
import "../services" as Services
import "." as Components

Components.ActionButton {
    id: root

    property bool toggleable: false
    property string tooltipText: ""
    property bool tooltipBelow: false

    checkable: root.toggleable

    Components.BarTooltip {
        anchorItem: root
        text: root.tooltipText
        below: root.tooltipBelow
        show: root.hovered && root.tooltipText.length > 0
    }
}
