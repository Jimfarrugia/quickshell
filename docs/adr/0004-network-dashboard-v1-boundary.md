# Network dashboard v1 boundary

Status: Accepted by user on 2026-09-03

Phase 10 manages personal Wi-Fi through Quickshell's native NetworkManager API:
open and PSK connections, radio enable/disable, connect/disconnect/forget, and
inline selection of distinct saved profiles. Wired networking is read-only;
enterprise/EAP, VPN, proxy, hidden-network creation, arbitrary profile editing,
and unsupported authentication remain in `nm-connection-editor`. A retry PSK
may update a NetworkManager-owned saved profile, but QE never persists or logs
the credential. Because Quickshell 0.3.1 exposes no default-route device, QE
uses a deterministic connected-device priority rather than adding an `nmcli` or
new DBus adapter solely for device selection.

Consequences: the dashboard uses one active-device presentation, scans only
while open with an explicit refresh action, serializes mutations, and treats
only same-target newer intent as superseding. NetworkManager loss, stale data,
timeouts, and failures remain explicit and preserve confirmed state.
