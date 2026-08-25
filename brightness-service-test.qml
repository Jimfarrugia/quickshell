import QtQuick
import Quickshell
import "services" as Services
import "modules/bar" as Bar
import "tests/fixtures/qml" as Fixtures

ShellRoot {
  id: root

  Fixtures.FakeBrightnessIntegration { id: fakeIntegration }
  Bar.BrightnessModule { id: brightnessModule; visible: false }

  function fail(message) {
    console.error(`BRIGHTNESS_SERVICE_TEST_FAILED: ${message}`);
    Qt.quit();
  }

  function runChecks() {
    if (!Services.ConfigService.hasLoaded) {
      retryTimer.restart();
      return;
    }

    Services.BrightnessService.integration = fakeIntegration;
    Services.BrightnessService.__confirmedPercent = 50;
    Services.BrightnessService.__confirmedDeviceName = "intel_backlight";
    Services.BrightnessService.__confirmedDeviceClass = "backlight";
    Services.BrightnessService.__confirmedDeviceMaxBrightness = 1060;
    if (brightnessModule.textColor.toString() !== Services.ThemeService.theme.tokens.on_surface_variant.toString())
      return fail("brightness text did not use the standard secondary text color");
    if (brightnessModule.hoverText !== "")
      return fail("brightness module unexpectedly exposed hover content");

    // Icon thresholds.
    const iconCases = [
      [0, "brightness_low"], [29, "brightness_low"], [30, "brightness_medium"],
      [70, "brightness_medium"], [71, "brightness_high"], [100, "brightness_high"]
    ];
    for (let index = 0; index < iconCases.length; index++) {
      if (brightnessModule.iconForPercentage(iconCases[index][0]) !== iconCases[index][1])
        return fail(`icon threshold failed at ${iconCases[index][0]}%`);
    }

    // Clamp: values below 1 become 1, above 100 become 100.
    Services.BrightnessService.setBrightness(0);
    if (Services.BrightnessService.pendingPercent !== 1)
      return fail(`clamp 0 -> 1 failed, got ${Services.BrightnessService.pendingPercent}`);

    fakeIntegration.emitSetFinished({ ok: true, name: "intel_backlight", brightness: 11, maxBrightness: 1060, percent: 1 });
    if (Services.BrightnessService.confirmedPercent !== 1)
      return fail(`confirmed percent was not clamped to 1, got ${Services.BrightnessService.confirmedPercent}`);

    Services.BrightnessService.setBrightness(150);
    if (Services.BrightnessService.pendingPercent !== 100)
      return fail(`clamp 150 -> 100 failed, got ${Services.BrightnessService.pendingPercent}`);

    fakeIntegration.emitSetFinished({ ok: true, name: "intel_backlight", brightness: 1060, maxBrightness: 1060, percent: 100 });
    if (Services.BrightnessService.confirmedPercent !== 100)
      return fail(`confirmed percent was not clamped to 100`);

    // Confirmed-vs-pending: pending is visible; confirmed retained until set confirms.
    Services.BrightnessService.setBrightness(42);
    if (Services.BrightnessService.confirmedPercent !== 100)
      return fail("confirmedPercent changed before set confirmation");
    if (Services.BrightnessService.pendingPercent !== 42 || Services.BrightnessService.operation !== "pending")
      return fail("pending state was not published");
    if (brightnessModule.displayPercent !== 42)
      return fail("module did not show pending percent");
    if (brightnessModule.iconColor.toString() !== Services.ThemeService.theme.tokens.secondary.toString())
      return fail("pending brightness request changed the normal icon color");

    // A background read is external state, not confirmation of the pending request.
    fakeIntegration.emitRead({ ok: true, name: "intel_backlight", brightness: 636, maxBrightness: 1060, percent: 60 });
    if (Services.BrightnessService.confirmedPercent !== 60
        || Services.BrightnessService.pendingPercent !== 42
        || Services.BrightnessService.operation !== "pending")
      return fail("background read incorrectly confirmed or cleared a pending request");

    fakeIntegration.emitSetFinished({ ok: true, name: "intel_backlight", brightness: 445, maxBrightness: 1060, percent: 42 });
    if (Services.BrightnessService.confirmedPercent !== 42 || Services.BrightnessService.pendingPercent !== -1)
      return fail("confirmed state was not updated from successful set result");
    if (Services.BrightnessService.operation !== "idle")
      return fail("operation did not return to idle after set confirmation");

    // Operation failure: confirmed retained, pending cleared, operation failed.
    Services.BrightnessService.setBrightness(80);
    fakeIntegration.emitSetFinished({ ok: false, error: "permission denied" });
    if (Services.BrightnessService.confirmedPercent !== 42)
      return fail("confirmedPercent changed after failed set");
    if (Services.BrightnessService.pendingPercent !== -1)
      return fail("pendingPercent was not cleared after failed set");
    if (Services.BrightnessService.operation !== "failed")
      return fail("operation was not marked failed");

    // A command that cannot start must not leave pending state behind.
    fakeIntegration.acceptSet = false;
    Services.BrightnessService.setBrightness(70);
    if (Services.BrightnessService.pendingPercent !== -1 || Services.BrightnessService.operation !== "failed")
      return fail("failed command start left a pending request");
    fakeIntegration.acceptSet = true;

    // Coalescing: rapid requests while a set is running retain the latest desired value.
    Services.BrightnessService.setBrightness(50);
    fakeIntegration.setRunning = true;
    Services.BrightnessService.setBrightness(51);
    Services.BrightnessService.setBrightness(52);
    Services.BrightnessService.setBrightness(53);
    if (Services.BrightnessService.pendingPercent !== 53)
      return fail(`coalesced pending percent was ${Services.BrightnessService.pendingPercent}, expected 53`);
    fakeIntegration.setRunning = false;
    fakeIntegration.emitSetFinished({ ok: true, name: "intel_backlight", brightness: 530, maxBrightness: 1060, percent: 50 });
    if (Services.BrightnessService.pendingPercent !== 53)
      return fail("coalesced next request was not dispatched");
    fakeIntegration.emitSetFinished({ ok: true, name: "intel_backlight", brightness: 562, maxBrightness: 1060, percent: 53 });
    if (Services.BrightnessService.confirmedPercent !== 53)
      return fail("coalesced request did not confirm");

    // Wheel step method: positive raises, negative lowers by 5%.
    Services.BrightnessService.wheelStep(120);
    if (Services.BrightnessService.pendingPercent !== 58)
      return fail(`wheel up did not raise by 5%, got ${Services.BrightnessService.pendingPercent}`);
    fakeIntegration.emitSetFinished({ ok: true, name: "intel_backlight", brightness: 615, maxBrightness: 1060, percent: 58 });
    Services.BrightnessService.wheelStep(-120);
    if (Services.BrightnessService.pendingPercent !== 53)
      return fail(`wheel down did not lower by 5%, got ${Services.BrightnessService.pendingPercent}`);
    fakeIntegration.emitSetFinished({ ok: true, name: "intel_backlight", brightness: 562, maxBrightness: 1060, percent: 53 });

    // Polling read updates confirmed state without pending.
    fakeIntegration.emitRead({ ok: true, name: "intel_backlight", brightness: 600, maxBrightness: 1060, percent: 57 });
    if (Services.BrightnessService.confirmedPercent !== 57)
      return fail("polling read did not update confirmed percent");

    // Inactive lifecycle: disabling brightness stops adapter activity.
    const disabled = JSON.stringify({
      schemaVersion: 1,
      bar: {
        enabled: true,
        brightnessEnabled: false,
        metrics: { cpu: false, memory: false, disk: false, temperature: false, order: [] }
      }
    });
    Services.ConfigService.applyText(disabled);
    if (Services.BrightnessService.consumed)
      return fail("brightness should not be consumed when disabled");
    if (fakeIntegration.active)
      return fail("integration should stop when brightness is disabled");
    if (Services.BrightnessService.availability !== "unavailable")
      return fail("availability should be unavailable when disabled");
    const callsBeforeUnavailableStep = fakeIntegration.setCallCount;
    Services.BrightnessService.wheelStep(120);
    if (fakeIntegration.setCallCount !== callsBeforeUnavailableStep)
      return fail("wheel input reached the integration while brightness was unavailable");

    console.log("BRIGHTNESS_SERVICE_TEST_PASSED");
    Qt.quit();
  }

  Timer {
    id: retryTimer
    interval: 50
    repeat: false
    onTriggered: root.runChecks()
  }

  Timer {
    interval: 4000
    running: true
    onTriggered: root.fail("test timed out")
  }

  Component.onCompleted: Qt.callLater(runChecks)
}
