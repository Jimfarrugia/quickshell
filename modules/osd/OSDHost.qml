import QtQuick
import Quickshell
import "."
import "../../services" as Services

PanelWindow {
    id: root
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: Services.ConfigService.config.osd.enabled && Services.OSDService.activeItem !== null
    implicitWidth: 354
    implicitHeight: osd.implicitHeight + 24
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    anchors { bottom: true; right: true }
    margins { bottom: 42; right: 12 }

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
