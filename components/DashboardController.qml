import QtQml

QtObject {
    property bool visible: false
    property string activeId: ""
    property var sourceScreen: null
    property string sourceSide: "right"
    function open(id, screen, side) { activeId = String(id || ""); sourceScreen = screen || null; sourceSide = side === "left" ? "left" : "right"; visible = activeId !== ""; }
    function close() { visible = false; activeId = ""; sourceScreen = null; sourceSide = "right"; }
    function toggle(id, screen, side) { visible && activeId === id ? close() : open(id, screen, side); }
    function isOpen(id) { return visible && activeId === id; }
}
