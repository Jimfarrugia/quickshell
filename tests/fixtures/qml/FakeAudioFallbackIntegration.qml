import QtQuick

QtObject {
    property string error: ""
    property bool failLaunch: true

    function launch() {
        error = failLaunch ? "Could not launch pavucontrol" : "";
        return !failLaunch;
    }
}
