# ADR-038: Plugin-independent monitor-scoped workspace bars

Status: Accepted by user on 2026-09-05; per-monitor scale extension accepted on
2026-09-05

Decision: instantiate the workspace bar once per Qt screen and show only
positive-ID Hyprland workspaces that are active or occupied and whose confirmed
compositor monitor corresponds to that screen. Empty workspaces remain hidden
from the bar by design but remain available through compositor-owned keybindings.
The policy is implemented through `CompositorService`; the integration adapter
resolves the Qt screen with the native Hyprland monitor API and exposes the
reactive monitor model so topology changes reevaluate the mapping. The bar does
not depend on a workspace-range or monitor-splitting plugin.

Context: a Hyprland workspace plugin may assign ranges and persistence rules to
monitors, but those rules are optional external configuration. QE must continue
to render valid monitor-scoped workspace state if the plugin is removed or
replaced. The native Quickshell workspace model is retained instead of copied
into JavaScript records so workspace events and native object lifetime remain
reactive and safe.

Rationale: monitor identity belongs at the compositor integration boundary, and
visibility policy belongs in the domain service rather than in presentation QML.
Keeping the native model avoids introducing a snapshot model whose active,
occupancy, or monitor properties could become stale and preserves native
workspace activation.

Alternatives considered: show all positive-ID workspaces on every bar; show empty
persistent workspaces; create a normalized `ScriptModel` snapshot immediately;
make QE depend on the external workspace plugin.

Consequences: removing the external plugin changes workspace placement and
persistence, but does not invalidate QE's monitor mapping or workspace bar. A
future normalized model requires a separate decision covering reactivity,
object replacement, and name-based activation.

Affected areas: `CompositorService`, `HyprlandIntegration`, the bar workspace
module, injected compositor fixtures, and multi-monitor validation.

Related decisions: ADR-009 (bar as first vertical slice) and ADR-011 (native
integration before commands).
