import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Brightness.mjs" as Brightness

// Brightness external boundary adapter. Discovers a backlight device through a
// project-relative helper, then polls the discovered sysfs files every 10 s
// while consumed. Set operations are bounded, clamped, and confirmed by a fresh
// authoritative read performed by the helper before returning.
QtObject {
  id: root

  property bool active: false
  readonly property string availability: active
      ? (deviceName.length > 0 ? "available" : (__failureCount >= 3 ? "unavailable" : "unknown"))
      : "unavailable"
  readonly property string freshness: active
      ? (__failureCount >= 3 ? "stale" : (__lastReadOk ? "current" : "unknown"))
      : "unknown"
  property var lastUpdated: null
  property var lastError: null
  readonly property string operation: setRunner.running || discoverRunner.running ? "pending" : "idle"
  readonly property bool setRunning: setRunner.running

  property string deviceName: ""
  property string deviceClass: ""
  property int deviceMaxBrightness: 0

  property int __failureCount: 0
  property bool __lastReadOk: false
  property string sysfsRoot: "/sys/class/backlight"

  signal read(var result)
  signal setFinished(var result)

  readonly property string helperPath: Quickshell.shellPath("scripts/qe-brightness.sh")

  function discoverCommand() { return [helperPath, "--mode", "discover"]; }
  function setCommand(percent) {
    return [helperPath, "--mode", "set", "--device", deviceName, "--percent", String(percent)];
  }

  function publishDiscover(result) {
    if (result.cancelled) return;
    lastUpdated = new Date();
    if (result.success && result.parsed !== null && !result.stdoutTruncated) {
      const parsed = Brightness.parseDiscoverOutput(JSON.stringify(result.parsed));
      if (!parsed.ok) {
        __failureCount++;
        lastError = `BRIGHTNESS_DISCOVER_PARSE_FAILED: ${parsed.error}`;
        deviceName = "";
        __lastReadOk = false;
        read({ ok: false, error: parsed.error });
        return;
      }
      const selected = Brightness.selectBacklightDevice(parsed.devices);
      if (!selected) {
        __failureCount++;
        lastError = "BRIGHTNESS_NO_DEVICE: no backlight device discovered";
        deviceName = "";
        __lastReadOk = false;
        read({ ok: false, error: "no backlight device discovered" });
        return;
      }
      deviceName = selected.name;
      deviceClass = selected.class;
      deviceMaxBrightness = selected.maxBrightness;
      lastError = null;
      __failureCount = 0;
      __lastReadOk = true;
      read({ ok: true, name: selected.name, class: selected.class, brightness: selected.brightness, maxBrightness: selected.maxBrightness, percent: selected.percent });
    } else {
      __failureCount++;
      deviceName = "";
      __lastReadOk = false;
      lastError = `BRIGHTNESS_DISCOVER_FAILED: ${result.parseError || result.stderr || result.errorCode || "brightness helper failed"}`;
      read({ ok: false, error: lastError });
    }
  }

  function failSysfsRead(detail) {
    __failureCount++;
    __lastReadOk = false;
    lastError = `BRIGHTNESS_SYSFS_READ_FAILED: ${detail}`;
    read({ ok: false, error: lastError });
    if (__failureCount >= 3) {
      deviceName = "";
      deviceClass = "";
      deviceMaxBrightness = 0;
    }
  }

  function publishSysfsRead() {
    if (!active || deviceName.length === 0 || !brightnessFile.loaded || !maxBrightnessFile.loaded) return;
    const parsed = Brightness.parseSysfsSnapshot(
      brightnessFile.text(), maxBrightnessFile.text(), deviceName, deviceClass);
    if (!parsed.ok) {
      failSysfsRead(parsed.error);
      return;
    }
    deviceMaxBrightness = parsed.maxBrightness;
    __failureCount = 0;
    __lastReadOk = true;
    lastUpdated = new Date();
    lastError = null;
    read(parsed);
  }

  function publishSet(result) {
    if (result.cancelled) {
      setFinished({ ok: false, error: "cancelled" });
      return;
    }
    lastUpdated = new Date();
    if (result.success && result.parsed !== null && !result.stdoutTruncated) {
      const parsed = Brightness.parseSetOutput(JSON.stringify(result.parsed));
      if (!parsed.ok || parsed.name !== deviceName) {
        const error = parsed.ok ? "set returned a different device" : parsed.error;
        lastError = `BRIGHTNESS_SET_PARSE_FAILED: ${error}`;
        setFinished({ ok: false, error });
        return;
      }
      deviceName = parsed.name;
      deviceMaxBrightness = parsed.maxBrightness;
      __failureCount = 0;
      __lastReadOk = true;
      lastError = null;
      setFinished({ ok: true, name: parsed.name, brightness: parsed.brightness, maxBrightness: parsed.maxBrightness, percent: parsed.percent });
    } else {
      lastError = `BRIGHTNESS_SET_FAILED: ${result.parseError || result.stderr || result.errorCode || "brightness helper failed"}`;
      setFinished({ ok: false, error: lastError });
    }
  }

  function setBrightness(percent) {
    if (deviceName.length === 0) {
      if (!discoverRunner.running) discoverRunner.start();
      return false;
    }
    if (setRunner.running) return false;
    setRunner.command = setCommand(percent);
    setRunner.start();
    return true;
  }

  property Timer pollTimer: Timer {
    interval: 10000
    repeat: true
    running: root.active
    onTriggered: {
      if (root.deviceName.length === 0) {
        if (!root.discoverRunner.running) root.discoverRunner.start();
      } else {
        root.brightnessFile.reload();
      }
    }
  }

  property CommandRunner discoverRunner: CommandRunner {
    command: root.discoverCommand()
    expectJson: true
    timeoutMs: 5000
    termGraceMs: 1000
    maxStdoutBytes: 8192
    maxStderrBytes: 4096
    onFinished: result => root.publishDiscover(result)
  }

  property FileView brightnessFile: FileView {
    path: root.active && root.deviceName.length > 0
      ? `${root.sysfsRoot}/${root.deviceName}/brightness` : ""
    blockLoading: false
    printErrors: false
    onLoaded: root.publishSysfsRead()
    onLoadFailed: error => { if (root.active) root.failSysfsRead(`brightness: ${error}`); }
  }

  property FileView maxBrightnessFile: FileView {
    path: root.active && root.deviceName.length > 0
      ? `${root.sysfsRoot}/${root.deviceName}/max_brightness` : ""
    blockLoading: false
    printErrors: false
    onLoaded: root.publishSysfsRead()
    onLoadFailed: error => { if (root.active) root.failSysfsRead(`max_brightness: ${error}`); }
  }

  property CommandRunner setRunner: CommandRunner {
    command: []
    expectJson: true
    timeoutMs: 5000
    termGraceMs: 1000
    maxStdoutBytes: 4096
    maxStderrBytes: 4096
    onFinished: result => root.publishSet(result)
  }

  onActiveChanged: {
    if (active) {
      if (deviceName.length === 0 && !discoverRunner.running) discoverRunner.start();
    } else {
      if (discoverRunner.running) discoverRunner.cancel();
      if (setRunner.running) setRunner.cancel();
      deviceName = "";
      deviceClass = "";
      deviceMaxBrightness = 0;
      __failureCount = 0;
      __lastReadOk = false;
      lastError = null;
    }
  }

}
