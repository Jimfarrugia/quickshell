import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Wayland

WlSessionLockSurface {
    id: surface

    required property var controller
    required property var lockTheme
    required property var appearance
    required property var power
    required property date now
    property string wallpaperSource: ""
    color: lockTheme.tokens.background

    function ordinalDay(day) {
        if (day >= 11 && day <= 13) return `${day}th`;
        switch (day % 10) {
        case 1: return `${day}st`;
        case 2: return `${day}nd`;
        case 3: return `${day}rd`;
        default: return `${day}th`;
        }
    }

    function dateText(date) {
        const months = ["January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"];
        return `${ordinalDay(date.getDate())} ${months[date.getMonth()]} ${date.getFullYear()}`;
    }

    function dayText(date) {
        const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        return days[date.getDay()];
    }

    LockBackground {
        lockTheme: surface.lockTheme
        source: surface.wallpaperSource
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Column {
            id: dateTime
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 60
            anchors.bottomMargin: Math.max(0, 60 - clockFontMetrics.descent)
            spacing: 4
            layer.enabled: true
            layer.effect: DropShadow {
                color: surface.lockTheme.tokens.background
                horizontalOffset: 0
                verticalOffset: 2
                radius: 4
                samples: 9
            }

            Text {
                text: surface.dayText(surface.now)
                color: surface.lockTheme.tokens.on_background
                font.family: "Roboto"
                font.pixelSize: 36
                font.weight: Font.Bold
            }

            Column {
                spacing: -18

                Text {
                    text: surface.dateText(surface.now)
                    color: surface.lockTheme.tokens.primary
                    font.family: "Roboto"
                    font.pixelSize: 36
                    font.weight: Font.Bold
                }

                Text {
                    id: clock
                    x: -clockTextMetrics.tightBoundingRect.x
                    text: Qt.formatTime(surface.now, "h:mm")
                    color: surface.lockTheme.tokens.on_background
                    font.family: "Roboto"
                    font.pixelSize: 149
                    font.weight: Font.Bold
                }
            }
        }

        FontMetrics {
            id: clockFontMetrics
            font.family: "Roboto"
            font.pixelSize: 149
            font.weight: Font.Bold
        }

        TextMetrics {
            id: clockTextMetrics
            text: Qt.formatTime(surface.now, "h:mm")
            font.family: "Roboto"
            font.pixelSize: 166
            font.weight: Font.Bold
        }

        FontMetrics {
            id: batteryFontMetrics
            font.family: "Roboto"
            font.pixelSize: 54
            font.weight: Font.Bold
        }

        Rectangle {
            id: inputField
            anchors.centerIn: parent
            width: 179
            height: 52
            radius: surface.appearance.radius
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

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 60
            anchors.bottomMargin: Math.max(0, 60 - batteryFontMetrics.descent)
            spacing: 12
            visible: surface.power.available
            layer.enabled: true
            layer.effect: DropShadow {
                color: surface.lockTheme.tokens.background
                horizontalOffset: 0
                verticalOffset: 2
                radius: 4
                samples: 9
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "battery_android_frame_full"
                color: surface.lockTheme.tokens.warning
                font.family: surface.appearance.iconFontFamily
                font.pixelSize: 54
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: `${surface.power.percentage}%`
                color: surface.lockTheme.tokens.on_background
                font.family: "Roboto"
                font.pixelSize: 54
                font.weight: Font.Bold
            }
        }
    }

}
