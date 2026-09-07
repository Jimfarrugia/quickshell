import QtQuick
import Quickshell.Wayland

WlSessionLockSurface {
    id: surface

    required property var controller
    required property var lockTheme
    required property var appearance
    property string wallpaperSource: ""
    color: lockTheme.tokens.background

    LockBackground {
        lockTheme: surface.lockTheme
        source: surface.wallpaperSource
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Column {
            anchors.centerIn: parent
            width: Math.min(360, parent.width - 48)
            spacing: surface.appearance.spacing * 2

            Text {
                id: clock
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(new Date(), "hh:mm")
                color: surface.lockTheme.tokens.on_background
                font.family: surface.appearance.fontFamily
                font.pixelSize: 64
            }

            Rectangle {
                width: parent.width
                height: 52
                radius: surface.appearance.radius
                color: surface.lockTheme.tokens.surface
                border.width: surface.appearance.borderWidth
                border.color: passwordInput.activeFocus
                    ? surface.lockTheme.tokens.focus_ring
                    : surface.lockTheme.tokens.outline

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.margins: 14
                    clip: true
                    focus: surface.visible && surface.controller.state === "awaitingInput"
                    enabled: surface.controller.state === "awaitingInput"
                    onEnabledChanged: if (enabled) Qt.callLater(() => passwordInput.forceActiveFocus())
                    color: surface.lockTheme.tokens.on_surface
                    selectionColor: surface.lockTheme.tokens.primary
                    selectedTextColor: surface.lockTheme.tokens.on_primary
                    font.family: surface.appearance.monospaceFontFamily
                    font.pixelSize: surface.appearance.fontSize + 2
                    echoMode: surface.controller.responseVisible
                        ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "*"
                    onAccepted: {
                        const response = text;
                        text = "";
                        surface.controller.submit(response);
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: surface.controller.state === "retryDelay"
                    ? "Authentication failed"
                    : (surface.controller.state === "recoveryRequired"
                        ? "Too many failures; recover from a TTY"
                        : "Enter password")
                color: surface.controller.state === "retryDelay"
                        || surface.controller.state === "recoveryRequired"
                    ? surface.lockTheme.tokens.error
                    : surface.lockTheme.tokens.on_surface_variant
                font.family: surface.appearance.fontFamily
                font.pixelSize: surface.appearance.fontSize
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
            }
        }
    }

    Timer {
        interval: 1000
        running: surface.visible
        repeat: true
        onTriggered: clock.text = Qt.formatTime(new Date(), "hh:mm")
    }
}
