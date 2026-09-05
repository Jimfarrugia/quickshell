import QtQml
import Quickshell

Variants {
    id: root
    property var dashboardController
    model: Quickshell.screens
    delegate: Component {
        Bar {
            dashboardController: root.dashboardController
        }
    }
}
