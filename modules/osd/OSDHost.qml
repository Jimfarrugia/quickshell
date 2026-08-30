import QtQuick
import Quickshell
import "."
import "../../services" as Services

PanelWindow {
    id: root
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: Services.ConfigService.config.osd.enabled && Services.OSDService.activeItem !== null
    implicitWidth: osd.implicitWidth + 48
    implicitHeight: osd.implicitHeight + 48
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    anchors { top: true }
    margins {
        // The extra host height provides 24px of shadow clearance above the card.
        top: 20 - 24
    }

    Loader {
        id: osd
        anchors.fill: parent
        source: "OSD.qml"
        onLoaded: item.item = Services.OSDService.activeItem
    }

    Connections {
        target: Services.OSDService
        function onActiveItemChanged() { if (osd.item) osd.item.item = Services.OSDService.activeItem; }
    }
}
