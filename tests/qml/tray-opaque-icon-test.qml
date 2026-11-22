import QtQuick
import Quickshell
import "modules/bar" as Bar

// Renders tray icons through the real tint shader and reads pixels back: an
// icon drawn on an opaque square must not tint into a solid square.
ShellRoot {
    id: root

    property var grabs: []
    property var pending: []
    property int grabIndex: -1

    QtObject {
        id: opaqueIcon
        property string title: "Opaque"
        property string icon: Qt.resolvedUrl("fixtures/tray/opaque-background.png")
    }

    QtObject {
        id: alphaIcon
        property string title: "Alpha"
        property string icon: Qt.resolvedUrl("fixtures/tray/alpha-shaped.png")
    }

    FloatingWindow {
        visible: true
        implicitWidth: 120
        implicitHeight: 40
        color: "transparent"

        Bar.TrayHost {
            id: tray
            items: [opaqueIcon, alphaIcon]
        }

        Canvas {
            id: probe
            x: 80
            width: 36
            height: 26
            onImageLoaded: Qt.callLater(root.readPixels)
        }
    }

    function fail(message) {
        console.error(`TRAY_OPAQUE_ICON_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function grabNext() {
        grabIndex += 1;
        if (grabIndex >= 2)
            return checkPixels();
        const delegate = tray.itemAt(grabIndex);
        if (!delegate)
            return fail(`tray delegate ${grabIndex} was not created`);
        const ok = delegate.grabToImage(result => {
            root.grabs.push(result); // keep the grab alive while the canvas loads it
            probe.loadImage(result.url);
            // Grab URLs can load synchronously, in which case imageLoaded never fires.
            if (probe.isImageLoaded(result.url))
                Qt.callLater(root.readPixels);
        }, Qt.size(delegate.width, delegate.height));
        if (!ok)
            fail(`could not grab tray delegate ${grabIndex}`);
    }

    function readPixels() {
        const delegate = tray.itemAt(grabIndex);
        const url = grabs[grabIndex].url;
        const ctx = probe.getContext("2d");
        ctx.clearRect(0, 0, probe.width, probe.height);
        ctx.drawImage(url, 0, 0);
        const data = ctx.getImageData(0, 0, delegate.width, delegate.height);
        // Icon coordinates are relative to the centred 18 px icon.
        const left = Math.round(delegate.width / 2 - 9);
        const top = Math.round(delegate.height / 2 - 9);
        pending.push(function pixel(x, y) {
            const i = ((top + y) * data.width + left + x) * 4;
            return { r: data.data[i], g: data.data[i + 1], b: data.data[i + 2], a: data.data[i + 3] };
        });
        Qt.callLater(grabNext);
    }

    function near(value, expected, tolerance) {
        return Math.abs(value - expected) <= tolerance;
    }

    function matchesTint(p) {
        const tint = tray.itemAt(0).tintColor; // typed color; the token itself is a string
        return near(p.r, Math.round(tint.r * 255), 3) && near(p.g, Math.round(tint.g * 255), 3)
            && near(p.b, Math.round(tint.b * 255), 3);
    }

    function describe(p) {
        return `rgba(${p.r}, ${p.g}, ${p.b}, ${p.a})`;
    }

    function checkPixels() {
        const opaque = pending[0];
        const alpha = pending[1];

        const background = opaque(1, 1);
        if (background.a > 8)
            return fail(`opaque icon background was painted: ${describe(background)}`);
        const lit = opaque(9, 7);
        if (lit.a < 247 || !matchesTint(lit))
            return fail(`opaque icon lit mark was not fully tinted: ${describe(lit)}`);
        const dim = opaque(9, 14);
        if (!near(dim.a, 102, 16) || !matchesTint(dim))
            return fail(`opaque icon dim mark did not keep partial strength: ${describe(dim)}`);

        const corner = alpha(1, 1);
        if (corner.a > 8)
            return fail(`alpha icon transparent area was painted: ${describe(corner)}`);
        const mark = alpha(9, 9);
        if (mark.a < 247 || !matchesTint(mark))
            return fail(`alpha icon mark was not fully tinted by alpha: ${describe(mark)}`);

        console.log("TRAY_OPAQUE_ICON_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        interval: 400
        running: true
        onTriggered: root.grabNext()
    }

    Timer {
        interval: 6000
        running: true
        onTriggered: root.fail("test timed out")
    }
}
