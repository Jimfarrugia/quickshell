# Curated help reference catalog

## Status

Accepted by user on 2026-09-01; revised on 2026-09-01

## Context

QE needs a help surface for its keybindings and common commands. Hyprland owns
global keybindings, while QE owns the presentation surface and its IPC.

## Decision

Use the authored `config/help.json` catalog as the sole authority. It uses a
versioned `entries` array. Entries require
`id`, `category`, and `title`, and may contain display-only `shortcut` and
`command` strings. Categories are restricted to `keybindings` and `commands`.

Invalid entries are rejected individually. The help surface refreshes the
catalog on open, searches the whole grouped view, and never executes catalog
commands. Keybinding text is reference data only; Hyprland remains
authoritative. There is no repository default catalog or merge workflow.

## Consequences

- Help content can be edited without changing QE behavior or executing commands.
- Users control the complete help catalog, including removal of entries.
- The catalog can become stale when Hyprland configuration changes.
- A separate file keeps reference content independent from runtime state.
- Future live keybinding derivation can replace duplicated reference text.
