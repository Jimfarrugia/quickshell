pragma Singleton

import QtQuick
import Quickshell
import "../utils/Brightness.mjs" as Brightness
import "../integrations" as Integrations

// Owns brightness requested/confirmed state and coalesces rapid 5% scroll
// requests. Confirmed state is updated only from a fresh authoritative read
// returned by the integration after a successful set or poll.
Singleton {
  id: root

  property var integration: nativeIntegration

  readonly property bool consumed: ConfigService.config.bar.enabled
      && ConfigService.config.bar.brightnessEnabled

  readonly property string availability: consumed
      ? (integration.availability === "available" && confirmedDeviceName.length > 0 ? "available" : integration.availability)
      : "unavailable"
  readonly property string freshness: consumed ? integration.freshness : "unknown"
  readonly property var lastUpdated: consumed ? integration.lastUpdated : null
  readonly property var lastError: consumed ? integration.lastError : null
  readonly property string operation: __operation !== "idle" ? __operation : integration.operation

  readonly property int confirmedPercent: __confirmedPercent
  readonly property int pendingPercent: __pendingPercent
  readonly property string confirmedDeviceName: __confirmedDeviceName
  readonly property string confirmedDeviceClass: __confirmedDeviceClass
  readonly property int confirmedDeviceMaxBrightness: __confirmedDeviceMaxBrightness

  property int __confirmedPercent: 0
  property int __pendingPercent: -1
  property string __confirmedDeviceName: ""
  property string __confirmedDeviceClass: ""
  property int __confirmedDeviceMaxBrightness: 0
  property string __operation: "idle"
  property int __desiredPercent: -1

  Integrations.BrightnessIntegration { id: nativeIntegration }

  function setBrightness(percent) {
    if (!consumed || availability !== "available") return false;
    const clamped = Brightness.clampPercent(percent);
    __pendingPercent = clamped;
    __operation = "pending";
    if (integration.setRunning) {
      __desiredPercent = clamped;
      return true;
    }
    __desiredPercent = -1;
    if (!integration.setBrightness(clamped)) {
      __operation = "failed";
      __pendingPercent = -1;
      return false;
    }
    return true;
  }

  function stepBrightness(delta) {
    const base = pendingPercent >= 0 ? pendingPercent : confirmedPercent;
    return setBrightness(base + delta);
  }

  function wheelStep(angleDeltaY) {
    // Positive angleDelta.y scrolls up -> raise brightness.
    if (angleDeltaY > 0) stepBrightness(5);
    else if (angleDeltaY < 0) stepBrightness(-5);
  }

  function applyConfirmed(result) {
    __confirmedPercent = result.percent;
    __confirmedDeviceName = result.name;
    if (result.class !== undefined) __confirmedDeviceClass = result.class;
    __confirmedDeviceMaxBrightness = result.maxBrightness;
  }

  function onRead(result) {
    if (!consumed || !result.ok) return;
    applyConfirmed(result);
  }

  function onSetFinished(result) {
    if (!consumed) return;
    if (!result.ok) {
      __operation = "failed";
      __pendingPercent = -1;
      __desiredPercent = -1;
      return;
    }
    applyConfirmed(result);
    __operation = "idle";
    __pendingPercent = -1;
    if (__desiredPercent >= 0 && __desiredPercent !== __confirmedPercent) {
      const next = __desiredPercent;
      __desiredPercent = -1;
      setBrightness(next);
    } else {
      __desiredPercent = -1;
    }
  }

  Connections {
    target: root.integration
    function onRead(result) { root.onRead(result); }
    function onSetFinished(result) { root.onSetFinished(result); }
  }

  onConsumedChanged: {
    integration.active = consumed;
    if (!consumed) {
      __operation = "idle";
      __pendingPercent = -1;
      __desiredPercent = -1;
    }
  }

  Component.onCompleted: integration.active = consumed
}
