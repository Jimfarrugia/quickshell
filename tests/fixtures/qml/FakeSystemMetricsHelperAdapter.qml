import QtQuick

QtObject {
  property bool thermalActive: false
  property bool diskActive: false
  property string thermalSensorPath: ""
  readonly property bool active: thermalActive || diskActive
  property string availability: "available"
  property string freshness: "current"
  property var lastUpdated: null
  property var lastError: null
  property string operation: "idle"

  signal thermalRead(var result)
  signal diskRead(var result)

  function emitThermal(result) { thermalRead(result); }
  function emitDisk(result) { diskRead(result); }
}
