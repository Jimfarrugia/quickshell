# Integration Boundaries and Degraded Behavior

Authoritative for external-boundary adapter rules, polling, failure isolation, stale-state behavior, and degraded operation. Read it with the relevant service contract when changing a native API, DBus/IPC/file/command integration, retry policy, or poller.

## Integration Boundaries

| Integration       | Live authority                   | Initial discovery                 | Ongoing updates                   | QE operations                      | Reconnect/failure policy                                                                                                       | Independent test boundary                                     |
| ----------------- | -------------------------------- | --------------------------------- | --------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------- |
| Hyprland          | Hyprland IPC                     | native singleton models; bounded monitor-layout helper query | socket events; explicit monitor-layout query on control-center load | typed dispatch adapter; validated monitor-profile apply | mark stale on disconnect; explicit refresh only for known API gaps; monitor profiles succeed only after live-topology confirmation | recorded events/models, helper fixtures, and live opt-in test |
| PipeWire          | PipeWire/WirePlumber             | `Pipewire.ready`, nodes/defaults  | libpipewire events                | defaults, volume, mute             | native adapter reconnects; clear stale object references                                                                       | mock node model and live audio test                           |
| NetworkManager    | NetworkManager                   | native Networking models; bounded `nmcli` IPv4 enrichment because 0.3.1 exposes only hardware addresses | DBus signals trigger native updates and active-interface address refresh; no polling | toggle/connect/disconnect/forget   | unavailable/degraded while daemon absent; cancel or supersede stale IPv4 lookups; the 0.3.1 native model may not re-enumerate devices after restart, so the dashboard exposes guarded QE restart recovery | fixture model plus isolated live test network and loopback IPv4 lookup |
| BlueZ             | BlueZ                            | DBus ObjectManager via native API | DBus object/property signals      | power/discover/pair/connect/forget | preserve no false connected state; repopulate on service return                                                                | mock devices and manual hardware test                         |
| UPower            | UPower and power-profiles-daemon | native singleton                  | DBus signals                      | profile selection                  | battery may remain absent on desktop; profile feature degrades separately                                                      | fixture devices and live read-only test                       |
| MPRIS             | player applications              | service watcher                   | DBus properties/signals           | capability-guarded controls        | remove vanished player; deterministic reselection                                                                              | mock player capabilities                                      |
| System tray       | status notifier services         | native singleton                  | DBus watcher/menu events          | activate/menu/scroll               | remove vanished items; malformed menu affects only item; do not instantiate the QE tray host in a second shell instance; once instantiated, 0.3.1 ownership is process-lifetime and returning ownership requires stopping QE | mock item delegate and live tray apps                         |
| Notifications     | sending apps                     | DBus service acquisition          | notification calls                | action/reply/dismiss               | cannot coexist with Dunst; ownership state visible                                                                             | `notify-send` acceptance suite in isolated session            |
| Brightness        | kernel backlight                 | helper structured read            | watcher or documented poll        | bounded set/step                   | timeout, malformed output, permission error; retain stale last value                                                           | helper fixtures and fake sysfs root                           |
| System metrics    | procfs/sysfs/filesystem          | adapter reads                     | documented polling                | read only                          | per-metric stale/error; no bar-wide failure                                                                                    | fixture roots and parser tests                                |
| Idle inhibit      | Wayland compositor               | protocol object                   | compositor state/lifetime         | enable/disable                     | requested state separate from active; surface loss disables                                                                    | compositor/manual protocol test                               |
| Session lock      | compositor                       | lock request and `secure`         | protocol events                   | unlock only after PAM success      | fail closed; no automatic reclaim after crash                                                                                  | nested/test compositor where possible plus manual checklist   |
| PAM               | configured PAM service           | `PamContext.start()`              | PAM conversation signals          | respond/cancel through context     | bounded attempts; generic UI errors; never log response                                                                        | test PAM profile if safely available; manual login-stack test |
| Desktop entries   | XDG application dirs             | `DesktopEntries.applications`     | native file monitoring            | structured launch                  | invalid entries omitted; launch failure visible                                                                                | fixture desktop files where API permits                       |
| Wallpaper         | Hyprpaper/`qe-wallpaper`         | compatibility state then QE state | IPC/file changes where observable | apply source immediately, then promote normalized LKG | helper success is not compositor proof; retain prior LKG and report unknown after failed compensation | temporary paths and image fixtures                            |
| External switcher | switcher-owned state             | versioned state/status            | result and optional file watch    | request apply                      | timeout/partial status; no QE rollback                                                                                         | fake target scripts and contract tests                        |
| Matugen           | generated command output         | on-demand generation              | wallpaper-triggered only          | generate staged set                | debounce, timeout, validate, keep LKG                                                                                          | golden wallpaper and expected schema fixtures                 |

### Command adapter rules

Every command boundary defines:

- executable discovery and missing-dependency behavior
- array-form arguments
- accepted input validation
- timeout and TERM-to-KILL grace period
- maximum stdout/stderr retained in diagnostics
- output schema and version
- exit-code meanings
- cancellation and supersession behavior
- whether retries are safe and idempotent

Commands do not run through `sh -c` unless shell semantics are the purpose of a
reviewed helper script. Secrets never appear in arguments when a native API can
avoid it, logs, state files, or diagnostic UI.

### Polling policy

Polling is allowed only for values lacking reliable events. Every poller must be
listed in the registry below, configured or constant with rationale, suspended
when not needed where practical, and expose staleness after failures.

Expected pollers are clock display cadence, CPU/memory, temperature, disk
capacity, MPRIS playback position while active, and potentially brightness if
sysfs watching proves unreliable. Network, Bluetooth, audio, battery,
workspaces, tray, and notifications must use native events.

## Polling Registry

This registry is authoritative for intentional QE polling. Update it before adding or changing a poller. Historical validation-phase labels are retained only as provenance for existing pollers; new entries should name the validating subsystem or test group instead of a project phase.

| Poller | Missing event source | Interval | Active consumer lifecycle | Cost control | Stale behavior | Validation provenance |
| --- | --- | --- | --- | --- | --- | --- |
| Clock display | Wall-clock labels need periodic recomputation | align to minute boundary by default; 1 second only when configured to display seconds | enabled while a visible clock consumer exists | one shared timer for all clock views | system clock itself is not cached; missed tick recomputes on next tick | bar/clock validation |
| CPU usage | procfs counters do not emit change events | 2 seconds | enabled while bar/control-center CPU metric is configured and process is active | one shared read; suspend when no consumer | stale after two failed reads; retain last value with stale marker | system-metrics/bar validation |
| Memory usage | procfs does not emit change events | 2 seconds | enabled while a memory metric consumer is configured | share cadence with CPU where implementation remains clear | stale after two failed reads; retain last value | system-metrics/bar validation |
| Thermal sensor | hwmon values do not provide a reliable portable event stream | 5 seconds | enabled while a temperature consumer is configured | discover stable sensor once; read only selected sensor files | stale after three failed reads; remove invalid sensor and rediscover | system-metrics/bar validation |
| Disk capacity | filesystem capacity has no suitable change signal | 30 seconds | enabled while a disk metric consumer is configured | query configured mount points only | stale after three failed reads; retain last value | system-metrics/bar validation |
| MPRIS position | Quickshell MPRIS position does not advance continuously | 1 second | only while a position consumer is visible and selected player is playing | stop immediately when paused, player vanishes, or view hides | reset from next player event; hide progress if player state is unavailable | media/OSD validation |
| Brightness fallback | no native Quickshell API; sysfs watcher reliability is unverified | 2 seconds with dashboard/OSD visible; 10 seconds for a configured persistent bar value | only if watcher/operation events cannot satisfy active consumers | one device read; no poll when brightness is not displayed | stale after three failed reads; requested operations still force immediate confirmation read | brightness/bar/OSD validation |
| AI provider quota | usage endpoints do not provide a local event source; system resume is a separate logind event | 5 minutes while a bar or dashboard consumer exists, plus an immediate resume-triggered cycle | one singleton adapter/poller and resume watcher shared by all monitors; stop at zero consumers | sequential provider requests remain one logical pending cycle, bounded response/auth reads, coalesced manual/resume requests, manual retry of QE-generated timeout/network backoff, provider backoff with `Retry-After` respected; pre-sleep cancellation prevents false failures | retain last-known values and mark stale after 15 minutes; one-minute local age refresh does not contact providers | AI quota validation |

Existing polling budget:

- Pollers add less than 0.5 percentage points of average CPU use over a
  five-minute idle comparison on the development machine.
- No consumer-scoped poller runs when it has zero enabled consumers.
- No undocumented poller is accepted.
- Native event-driven integrations do not receive fallback pollers merely to
  mask a reconnection defect.

## Failure and Degraded Behavior

| Failure                              | Required behavior                                                                                                                 |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| Missing optional executable          | integration unavailable; hide destructive controls, retain explanatory status                                                     |
| Native daemon unavailable at startup | shell starts; module shows unavailable; adapter waits for native reconnection or documented backoff                               |
| Permission denied                    | operation fails visibly; do not repeatedly prompt or retry without user action                                                    |
| Timeout                              | terminate operation safely, mark outcome unknown where side effects may have occurred, then refresh live state                    |
| Malformed structured output          | reject entire result; retain confirmed/LKG state; capture bounded diagnostic detail                                               |
| Missing/invalid config               | retain last-known-good in process or use safe defaults at cold start; expose persistent diagnostic                                |
| Missing/invalid active theme         | fall back through configured default to emergency palette; do not rewrite authored theme                                          |
| Event subscription disconnect        | mark state stale immediately; reconnect through native mechanism or bounded exponential backoff with jitter                       |
| External subsystem restart           | discard invalid object references and repopulate from fresh discovery                                                             |
| Missing screen-to-monitor mapping    | omit monitor-scoped workspace entries while keeping the bar and other modules usable                                             |
| Partial theme apply                  | QE remains successful if its phase committed; external status is partial and retryable per target                                 |
| Wallpaper generation failure         | keep previous generated `Wallpaper`; retain newly selected wallpaper if wallpaper apply itself succeeded; show generation failure |
| Requested change unconfirmed         | clear pending on timeout, report failure/unknown, refresh authority; never silently commit intent                                 |
| Optional module failure              | module degrades independently; persistent shell remains running                                                                   |
| Notification ownership conflict      | do not claim readiness; keep staged migration mode and identify current owner                                                     |
| Lock authentication failure          | remain securely locked; clear secret response; apply bounded retry delay without revealing account details                        |
| Lock process crash after secure      | compositor remains locked; document TTY/session recovery; never attempt unauthenticated unlock                                    |

Retries are limited to transient discovery/reconnection. User operations are not
blindly retried unless idempotence is proven. Backoff state is adapter-owned.
