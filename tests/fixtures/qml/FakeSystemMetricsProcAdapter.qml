import QtQuick

QtObject {
  property bool cpuActive: false
  property bool memoryActive: false
  readonly property bool active: cpuActive || memoryActive
  property string availability: "available"
  property string freshness: "current"
  property var lastUpdated: null
  property var lastError: null
  property string operation: "idle"

  signal cpuRead(string text, bool failed, string error)
  signal memRead(string text, bool failed, string error)

  function emitCpu(text, failed, error) { cpuRead(text, failed, error); }
  function emitMem(text, failed, error) { memRead(text, failed, error); }
}
