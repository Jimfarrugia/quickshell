import QtQuick
import Quickshell
import Quickshell.Io

// Reads /proc/stat and /proc/meminfo asynchronously on a shared cadence.
// This adapter owns the procfs boundary only; it does not compute percentages.
QtObject {
  id: root

  property bool cpuActive: false
  property bool memoryActive: false
  readonly property bool active: cpuActive || memoryActive
  property string availability: active ? "unknown" : "unavailable"
  property string freshness: "unknown"
  property var lastUpdated: null
  property var lastError: null
  readonly property string operation: "idle"

  signal cpuRead(string text, bool failed, string error)
  signal memRead(string text, bool failed, string error)

  function publish(text, failed, error, cpu) {
    lastUpdated = new Date();
    if (failed) {
      availability = "degraded";
      freshness = "stale";
      lastError = error;
    } else {
      availability = "available";
      freshness = "current";
      lastError = null;
    }
    if (cpu) cpuRead(text, failed, error);
    else memRead(text, failed, error);
  }

  function poll() {
    if (cpuActive) statFile.reload();
    if (memoryActive) memFile.reload();
  }

  property Timer cadence: Timer {
    interval: 2000
    repeat: true
    running: root.active
    onTriggered: root.poll()
  }

  property FileView statFile: FileView {
    path: root.cpuActive ? "/proc/stat" : ""
    blockLoading: false
    printErrors: false
    onLoaded: if (root.cpuActive) root.publish(root.statFile.text(), false, "", true)
    onLoadFailed: error => { if (root.cpuActive) root.publish("", true, error, true); }
  }

  property FileView memFile: FileView {
    path: root.memoryActive ? "/proc/meminfo" : ""
    blockLoading: false
    printErrors: false
    onLoaded: if (root.memoryActive) root.publish(root.memFile.text(), false, "", false)
    onLoadFailed: error => { if (root.memoryActive) root.publish("", true, error, false); }
  }

  onActiveChanged: if (!active) {
    availability = "unavailable";
    freshness = "unknown";
    lastError = null;
  } else if (availability === "unavailable") {
    availability = "unknown";
  }
}
