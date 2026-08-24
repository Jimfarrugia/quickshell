import QtQuick

// Test double for BrightnessIntegration. Tests drive it by emitting signals.
QtObject {
  property bool active: false
  property string availability: "available"
  property string freshness: "current"
  property var lastUpdated: null
  property var lastError: null
  property string operation: "idle"
  property bool setRunning: false
  property bool acceptSet: true
  property int setCallCount: 0

  property string deviceName: ""
  property string deviceClass: "backlight"
  property int deviceMaxBrightness: 1060

  signal read(var result)
  signal setFinished(var result)

  function setBrightness(percent) {
    setCallCount++;
    if (!acceptSet) return false;
    setRunning = true;
    return true;
  }

  function emitRead(result) {
    read(result);
  }

  function emitSetFinished(result) {
    setRunning = false;
    setFinished(result);
  }
}
