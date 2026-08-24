import QtQuick
import Quickshell
import Quickshell.Io

// Bounded structured helper contract for thermal discovery and disk capacity.
// Invokes scripts/qe-system-metrics.sh with a stable JSON stdout contract.
QtObject {
  id: root

  property bool thermalActive: false
  property bool diskActive: false
  property string thermalSensorPath: ""
  property var thermalSensors: []
  readonly property bool active: thermalActive || diskActive
  property string availability: active ? "unknown" : "unavailable"
  property string freshness: "unknown"
  property var lastUpdated: null
  property var lastError: null
  readonly property string operation: thermalRunner.running || diskRunner.running ? "pending" : "idle"

  signal thermalRead(var result)
  signal diskRead(var result)

  readonly property string helperPath: Quickshell.shellPath("scripts/qe-system-metrics.sh")

  function thermalCommand() { return [helperPath, "--mode", "thermal"]; }
  function diskCommand() { return [helperPath, "--mode", "disk"]; }

  function publish(result, thermal) {
    if (result.cancelled) return;
    lastUpdated = new Date();
    if (result.success && result.parsed !== null && !result.stdoutTruncated) {
      availability = "available";
      freshness = "current";
      lastError = null;
      if (thermal) {
        thermalSensors = result.parsed.sensors || [];
        thermalRead({ ok: true, data: result.parsed });
      }
      else diskRead({ ok: true, data: result.parsed });
    } else {
      availability = "degraded";
      freshness = "stale";
      lastError = result.parseError || result.stderr || result.errorCode || "system metrics helper failed";
      if (thermal) thermalRead({ ok: false, error: lastError });
      else diskRead({ ok: false, error: lastError });
    }
  }

  function publishSelectedThermal() {
    const raw = thermalFile.text().trim();
    if (!/^-?\d+$/.test(raw)) {
      failSelectedThermal("selected thermal sensor returned a non-integer value");
      return;
    }
    const temperature = Number(raw);
    if (!Number.isInteger(temperature) || temperature < -100000 || temperature > 300000) {
      failSelectedThermal("selected thermal sensor returned an out-of-range value");
      return;
    }
    const selected = thermalSensors.find(sensor => sensor.path === thermalSensorPath);
    if (!selected) {
      failSelectedThermal("selected thermal sensor metadata is unavailable");
      return;
    }
    lastUpdated = new Date();
    availability = "available";
    freshness = "current";
    lastError = null;
    thermalRead({
      ok: true,
      data: {
        schemaVersion: 1,
        sensors: [{
          name: selected.name,
          label: selected.label,
          path: selected.path,
          temp: temperature
        }]
      }
    });
  }

  function failSelectedThermal(error) {
    lastError = error;
    availability = "degraded";
    freshness = "stale";
    thermalRead({ ok: false, error });
  }

  property Timer thermalTimer: Timer {
    interval: 5000
    repeat: true
    running: root.thermalActive
    onTriggered: {
      if (root.thermalSensorPath.length > 0) root.thermalFile.reload();
      else if (!root.thermalRunner.running) root.thermalRunner.start();
    }
  }

  property Timer diskTimer: Timer {
    interval: 30000
    repeat: true
    running: root.diskActive
    onTriggered: if (!root.diskRunner.running) root.diskRunner.start()
  }

  property CommandRunner thermalRunner: CommandRunner {
    command: root.thermalCommand()
    expectJson: true
    timeoutMs: 5000
    termGraceMs: 1000
    maxStdoutBytes: 32768
    maxStderrBytes: 4096
    onFinished: result => root.publish(result, true)
  }

  property FileView thermalFile: FileView {
    path: root.thermalActive && root.thermalSensorPath.length > 0 ? root.thermalSensorPath : ""
    blockLoading: false
    printErrors: false
    onLoaded: if (root.thermalActive) root.publishSelectedThermal()
    onLoadFailed: error => {
      if (root.thermalActive)
        root.failSelectedThermal(`selected thermal sensor read failed: ${error}`);
    }
  }

  property CommandRunner diskRunner: CommandRunner {
    command: root.diskCommand()
    expectJson: true
    timeoutMs: 10000
    termGraceMs: 1000
    maxStdoutBytes: 8192
    maxStderrBytes: 4096
    onFinished: result => root.publish(result, false)
  }

  onThermalActiveChanged: {
    if (thermalActive && thermalSensorPath.length === 0 && !thermalRunner.running) thermalRunner.start();
    else if (!thermalActive && thermalRunner.running) thermalRunner.cancel();
  }

  onThermalSensorPathChanged: if (thermalActive && thermalSensorPath.length === 0
      && !thermalRunner.running) thermalRunner.start()

  onDiskActiveChanged: {
    if (diskActive && !diskRunner.running) diskRunner.start();
    else if (!diskActive && diskRunner.running) diskRunner.cancel();
  }

  onActiveChanged: if (!active) {
    availability = "unavailable";
    freshness = "unknown";
    lastError = null;
  } else if (availability === "unavailable") {
    availability = "unknown";
  }
}
