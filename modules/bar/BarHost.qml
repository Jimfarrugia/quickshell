import QtQml
import Quickshell

Variants {
    model: Quickshell.screens
    delegate: Component { Bar {} }
}
