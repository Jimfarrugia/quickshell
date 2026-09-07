import QtQuick
import Qt5Compat.GraphicalEffects
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
                text: Qt.formatTime(new Date(), "h:mm")
                color: surface.lockTheme.tokens.on_background
                font.family: surface.appearance.fontFamily
                font.pixelSize: 96
                font.bold: false
                layer.enabled: true
                layer.effect: DropShadow {
                    color: surface.lockTheme.tokens.background
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 8
                    samples: 17
                }
            }

            Rectangle {
                id: inputField
                width: clock.implicitWidth
                height: 52
                radius: surface.appearance.radius
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"
                readonly property bool errorState: surface.controller.state === "retryDelay"
                    || surface.controller.state === "recoveryRequired"
                readonly property bool inputPending: passwordInput.text.length > 0
                    || surface.controller.authenticationSubmitted
                readonly property string statusMessage: surface.controller.state === "retryDelay"
                    ? "Authentication failed"
                    : (surface.controller.state === "recoveryRequired"
                        ? "Too many failures; recover from a TTY"
                        : (surface.controller.state === "authenticating"
                                && surface.controller.authenticationSubmitted
                            ? "Authenticating..." : ""))
                layer.enabled: true
                layer.effect: DropShadow {
                    color: surface.lockTheme.tokens.background
                    horizontalOffset: 0
                    verticalOffset: 4
                    radius: 10
                    samples: 21
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: inputBorder.border.width
                    radius: Math.max(0, inputField.radius - inputBorder.border.width)
                    color: surface.lockTheme.tokens.background
                    opacity: 0.35
                }

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

                Text {
                    id: statusText
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: passwordInput.text.length === 0 && inputField.statusMessage.length > 0
                    text: inputField.statusMessage
                    color: inputField.errorState
                        ? surface.lockTheme.tokens.error
                        : surface.lockTheme.tokens.warning
                    font.family: surface.appearance.fontFamily
                    font.pixelSize: surface.appearance.fontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                }

                Rectangle {
                    id: inputBorder
                    anchors.fill: parent
                    color: "transparent"
                    border.width: Math.max(1, surface.appearance.borderWidth)
                    border.color: surface.controller.state === "retryDelay"
                            || surface.controller.state === "recoveryRequired"
                        ? surface.lockTheme.tokens.error
                        : inputField.inputPending
                        ? surface.lockTheme.tokens.warning
                        : surface.lockTheme.tokens.primary
                    radius: inputField.radius
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: surface.visible
        repeat: true
        onTriggered: clock.text = Qt.formatTime(new Date(), "h:mm")
    }
}
