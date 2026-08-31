# Phase 7 Launcher

Status: ready-for-agent
Label: ready-for-agent

## Problem Statement

QE still relies on Rofi for primary application launching. This leaves the
primary launcher outside QE's surface, service, state, and theme architecture,
while the existing Quickshell desktop-entry model does not provide usage-based
ranking or launcher-specific failure handling.

## Solution

Provide a QE launcher surface for valid, non-terminal desktop applications.
The launcher searches desktop-entry metadata, ranks results deterministically,
launches the structured main command, and records successful launches for
frequently-used ordering. It opens on the active monitor, remains available on
launch failure, and preserves Rofi as the explicit rollback path until the
`Super+R` cutover is accepted.

## User Stories

1. As a QE user, I want to open the launcher from the primary launcher shortcut, so that I can start applications without leaving the QE shell.
2. As a QE user, I want the launcher to open on the active monitor, so that it appears where I am working.
3. As a QE user, I want only valid graphical desktop applications listed, so that unusable entries do not clutter the launcher.
4. As a QE user, I want hidden and `NoDisplay` entries excluded, so that the launcher reflects the visible application catalog.
5. As a QE user, I want terminal entries excluded in v1, so that the launcher does not silently guess which terminal should execute them.
6. As a QE user, I want desktop entries with empty parsed commands excluded, so that selecting an entry always represents a structured main-command launch attempt.
7. As a QE user, I want the launcher to show all eligible applications when opened with an empty query, so that I can browse the complete catalog.
8. As a QE user, I want empty-query results ordered by successful launch frequency, so that commonly used applications are easiest to reach.
9. As a QE user, I want equal-frequency applications ordered by normalized name and stable desktop-entry ID, so that the list is deterministic.
10. As a QE user, I want to search by application name, so that I can find an application directly.
11. As a QE user, I want to search by generic name, keywords, and comment, so that metadata helps me find applications when I do not know their exact name.
12. As a QE user, I want Unicode-aware case-insensitive search, so that capitalization does not affect results.
13. As a QE user, I want collapsed whitespace and punctuation treated as separators, so that ordinary phrasing finds the same application consistently.
14. As a QE user, I want exact name matches ranked above prefix matches, so that the most direct result appears first.
15. As a QE user, I want prefix matches ranked above token or substring matches, so that broader matches remain useful without displacing direct matches.
16. As a QE user, I want search relevance to outrank usage frequency for a non-empty query, so that a relevant infrequently used application beats an unrelated favorite.
17. As a QE user, I want every query token to match at least one searchable field, so that specific searches do not return unrelated partial matches.
18. As a QE user, I want successful launches to increase an application's usage count, so that the launcher learns my usage pattern.
19. As a QE user, I want usage counts to survive QE restarts, so that frequently used ordering remains useful over time.
20. As a QE user, I want usage state separate from authored configuration, so that generated usage data does not alter my settings.
21. As a QE user, I want usage state bounded to 512 records, so that long-term use cannot cause unbounded state growth.
22. As a QE user, I want records for removed desktop entries pruned, so that stale applications do not remain in runtime state.
23. As a QE user, I want failed launches excluded from usage counts, so that usage ranking reflects actual successful starts.
24. As a QE user, I want a successful retry to count exactly once, so that repeated failures do not distort usage frequency.
25. As a QE user, I want malformed or incompatible usage state to degrade to empty usage data, so that state corruption does not prevent launching.
26. As a QE user, I want persistence failures to leave the current launch successful, so that a state-writing problem does not block application startup.
27. As a QE user, I want persistence failures reported as bounded diagnostics, so that I know counts may not survive restart without being overwhelmed by repeated errors.
28. As a QE user, I want the first ranked result selected when the launcher opens, so that I can launch a common application immediately.
29. As a QE user, I want arrow-key navigation, so that the launcher works with familiar keyboard controls.
30. As a QE user, I want vim-style navigation without losing ordinary letter input, so that I can search for applications containing `h`, `j`, `k`, or `l`.
31. As a QE user, I want `Alt+h`, `Alt+j`, `Alt+k`, and `Alt+l` to provide vim-style navigation, so that modified navigation does not become search input.
32. As a QE user, I want `Alt+j` and `Alt+k` to move through the v1 single-column list, so that navigation is predictable.
33. As a QE user, I want horizontal vim-style keys to be harmless in the v1 single-column layout, so that reserved future behavior does not cause accidental actions.
34. As a QE user, I want pointer selection and activation, so that I can use the launcher without a keyboard.
35. As a QE user, I want `Enter` to launch the selected application, so that keyboard activation is direct.
36. As a QE user, I want `Escape` to dismiss the launcher, so that I can leave it without launching anything.
37. As a QE user, I want the launcher to close after a successful launch, so that it does not obstruct the application I started.
38. As a QE user, I want the launcher to remain open after a failed launch, so that I can correct the problem or choose another application.
39. As a QE user, I want a launch failure to explain the actionable reason, so that I can understand why the selected application did not start.
40. As a QE user, I want to retry a failed launch, so that transient or correctable failures do not require reopening the launcher.
41. As a QE user, I want launch failures not to silently delegate to Rofi, so that launcher behavior remains predictable.
42. As a QE user, I want an empty-result state to preserve my query, so that I can edit it or dismiss the launcher without losing context.
43. As a QE user, I want activation with no result to be harmless, so that `Enter` or pointer actions cannot launch stale or unintended applications.
44. As a QE user, I want the results to refresh when desktop entries change, so that newly installed or removed applications are reflected without restarting QE.
45. As a QE user, I want my selection preserved when its stable desktop-entry ID remains available, so that catalog refreshes do not unexpectedly move focus.
46. As a QE user, I want a removed selection replaced safely by the first current result, so that refreshes never leave focus on stale data.
47. As a QE user, I want Rofi retained as an explicit fallback, so that I can recover primary launching if the QE launcher is disabled or cut over unsuccessfully.

## Implementation Decisions

- Build a `LauncherService` that owns desktop-entry eligibility, usage state, structured launching, launch outcomes, and launcher-facing diagnostics.
- Build pure ranking and normalization utilities rather than placing search or ranking logic in the QML surface.
- Consume Quickshell `DesktopEntries` and use the parsed structured main command with its working directory. Never execute raw desktop `Exec` strings through a shell.
- Treat an entry as eligible only when it is a visible application entry with a non-empty parsed main command and it is not marked `Terminal=true`.
- Support the main desktop-entry command only. Desktop actions are out of scope for v1.
- Normalize search text with Unicode case-folding, collapsed whitespace, and punctuation as separators. Do not transliterate or remove accents in v1.
- Search normalized application name, generic name, keywords, and comment. Require every query token to match at least one searchable field.
- For non-empty queries, rank search relevance first. Within relevance, prioritize application name over generic name, keywords, and comment; within a field, exact matches outrank prefix matches, which outrank token or substring matches.
- For empty queries, rank by successful launch count, normalized application name, and stable desktop-entry ID.
- Persist usage in QE-owned versioned XDG state separate from authored configuration. The state document is `launcher-usage.json`, with an `entries` object mapping stable desktop-entry IDs to `launchCount` records.
- Retain at most 512 usage records and prune records whose desktop-entry IDs no longer exist after the desktop-entry model loads and before persistence writes when needed.
- Increment usage only when the structured launch operation reports success. Failed attempts do not increment the count.
- Keep the in-memory count updated when a launch succeeds even if persistence fails. Report persistence failure as a bounded non-blocking diagnostic and do not claim the count survived restart.
- Treat missing, malformed, or incompatible usage state as empty usage data, retain normal launcher operation, and report a bounded diagnostic.
- Keep failed-launch entries selected and the launcher open. Show the bounded actionable reason and a retry action; allow normal selection changes and dismissal.
- Close the launcher after successful launch. Refresh results safely if an entry disappears during activation.
- Use a single-column launcher surface on the active monitor. Focus the query field on open and select the first ranked result.
- Support arrow keys, `Enter`, pointer selection/activation, and `Escape`. Support `Alt+h/j/k/l` as modified vim-style navigation; `Alt+j/k` move vertically in v1 and `Alt+h/l` are harmless no-ops.
- Route surface visibility through the existing service-owned transient-surface and namespaced IPC conventions. Do not let the presentation layer own IPC handlers, external commands, output parsing, or usage persistence.
- Keep Rofi available as the explicit rollback path and migrate `Super+R` only after launcher acceptance.

## Testing Decisions

- Prefer external behavior at the `LauncherService` contract seam. Use deterministic desktop-entry fixtures and a fake structured-launch boundary rather than testing implementation details.
- Unit-test pure normalization and ranking behavior, including Unicode case-folding, whitespace and punctuation handling, field priority, exact/prefix/token matches, all-token matching, empty-query ordering, usage ties, and stable desktop-entry-ID ties.
- Test eligibility for hidden, `NoDisplay`, terminal, empty-command, valid, and changed desktop entries.
- Test usage-state loading, version validation, malformed state fallback, missing state, 512-record bounding, stale-record pruning, successful increments, failed-launch non-increments, retry behavior, and persistence failure diagnostics.
- Test launcher-service behavior for successful structured launch, working-directory forwarding, launch failure, retry, selection retention, removed selection, no-result activation, and desktop-entry refresh.
- Add QML surface tests for active-monitor placement, initial focus and selection, single-column keyboard navigation, modified vim keys, pointer activation, dismissal, close-on-success, and stay-open-on-failure behavior.
- Follow existing project conventions for JavaScript utility tests, QML service tests, fixture-driven malformed-state tests, diagnostics assertions, and timeout-bounded shell smoke tests.
- Validate the launcher with the Phase 7 desktop-entry fixture matrix, keyboard-only and multi-monitor/manual focus tests, missing-executable/launch-failure tests, `qmllint`, relevant JavaScript tests, relevant QML tests, and the persistent-shell smoke test.
- Test Rofi rollback by restoring `Super+R` to `rofi -show drun` and confirming QE launcher disablement does not remove the fallback.

## Out of Scope

- Replacing specialized Rofi script-mode tools.
- File search, calculator results, arbitrary command execution, plugin frameworks, or shell command parsing.
- Desktop actions such as “New Window” or “Private Window”.
- Terminal application launching through a configured terminal emulator.
- Usage decay, automatic reset, recency weighting, or cross-device synchronization.
- Transliteration or accent removal.
- Multi-column grid layout in v1.
- Automatic fallback to Rofi after an individual QE launch failure.
- Help-surface implementation, help JSON schema, or help catalog authoring.
- Final Phase 7 `Super+R` cutover before acceptance and rollback testing.

## Further Notes

- The launcher surface follows the existing `SurfaceService` ownership and
  namespaced transient-surface IPC convention.
- Hyprland remains authoritative for the actual `Super+R` binding until cutover;
  Rofi remains the documented rollback command.
- The persisted usage document is generated runtime state and must not be added
  to user-authored configuration or treated as confirmed external application
  state.
- The current Quickshell version provides structured desktop-entry commands but
  does not provide usage-based sorting, so usage tracking is a QE responsibility.
