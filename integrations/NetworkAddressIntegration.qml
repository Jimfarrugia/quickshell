import QtQuick
import Quickshell

QtObject {
    id: root

    property string ipv4Address: ""
    property string requestedInterface: ""
    property string activeInterface: ""
    property string availability: "unknown"
    property string freshness: "unknown"
    property var lastUpdated: null
    property var lastError: null
    property string operation: "idle"

    function refresh(interfaceName) {
        if (!/^[A-Za-z0-9_.:-]+$/.test(interfaceName)) {
            clear();
            return false;
        }
        requestedInterface = interfaceName;
        ipv4Address = "";
        availability = "unknown";
        freshness = "unknown";
        if (runner.running) {
            if (activeInterface !== interfaceName) runner.cancel();
            return true;
        }
        return startLookup(interfaceName);
    }

    function startLookup(interfaceName) {
        activeInterface = interfaceName;
        operation = "pending";
        runner.command = ["nmcli", "--terse", "--get-values", "IP4.ADDRESS", "device", "show", interfaceName];
        return runner.start();
    }

    function clear() {
        ipv4Address = "";
        requestedInterface = "";
        if (runner.running) runner.cancel();
        availability = "unknown";
        freshness = "unknown";
        operation = "idle";
        lastError = null;
    }

    function parseAddress(output) {
        const lines = output.split("\n");
        for (let index = 0; index < lines.length; index++) {
            const address = lines[index].trim().split("/")[0];
            const octets = address.split(".");
            if (octets.length !== 4) continue;
            let valid = true;
            for (let part = 0; part < octets.length; part++) {
                if (!/^\d{1,3}$/.test(octets[part]) || Number(octets[part]) > 255) valid = false;
            }
            if (valid) return address;
        }
        return "";
    }

    property CommandRunner runner: CommandRunner {
        id: runner
        timeoutMs: 2000
        maxStdoutBytes: 4096
        maxStderrBytes: 4096
        onFinished: result => {
            const completedInterface = root.activeInterface;
            root.activeInterface = "";
            if (root.requestedInterface !== completedInterface) {
                if (root.requestedInterface.length > 0)
                    Qt.callLater(() => root.startLookup(root.requestedInterface));
                else root.operation = "idle";
                return;
            }
            root.lastUpdated = new Date();
            if (result.success) {
                root.ipv4Address = root.parseAddress(result.stdout);
                root.availability = root.ipv4Address.length > 0 ? "available" : "degraded";
                root.freshness = "current";
                root.operation = "succeeded";
                root.lastError = root.ipv4Address.length > 0 ? null : {
                    code: "NETWORK_IPV4_MISSING",
                    boundary: "network-address",
                    summary: "Connected network device has no IPv4 address",
                    detail: root.requestedInterface,
                    timestamp: new Date().toISOString(),
                    retryable: true,
                    operationId: result.operationId
                };
            } else {
                root.ipv4Address = "";
                root.availability = "degraded";
                root.freshness = "unknown";
                root.operation = "failed";
                root.lastError = {
                    code: "NETWORK_IPV4_LOOKUP_FAILED",
                    boundary: "network-address",
                    summary: "Failed to read network IPv4 address",
                    detail: result.stderr || result.errorCode || "unknown failure",
                    timestamp: new Date().toISOString(),
                    retryable: true,
                    operationId: result.operationId
                };
            }
        }
    }
}
