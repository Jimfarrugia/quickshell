import Quickshell

Variants {
    id: root
    property var dashboardController
    model: Quickshell.screens
    Bar { dashboardController: root.dashboardController }
}
