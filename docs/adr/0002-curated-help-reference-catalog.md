# Curated help reference catalog

## Status

Accepted by user on 2026-09-01

## Context

QE needs a help surface for its keybindings and common commands. Hyprland owns
global keybindings, while QE owns the presentation surface and its IPC.

## Decision

Use a repository-provided `defaults/help.json` catalog and a separate authored
`config/help.json` catalog. Both use a versioned `entries` array. Entries require
`id`, `category`, and `title`, and may contain display-only `shortcut` and
`command` strings. Categories are restricted to `keybindings` and `commands`.

User entries override repository entries by stable ID and may add entries;
repository defaults cannot be removed in v1. Invalid entries are rejected
individually. The help surface refreshes the catalog on open, searches the whole
grouped view, and never executes catalog commands. Keybinding text is reference
data only; Hyprland remains authoritative.

## Consequences

- Help content can be edited without changing QE behavior or executing commands.
- The catalog can become stale when Hyprland configuration changes.
- A separate file keeps reference content independent from runtime state.
- Future live keybinding derivation can replace duplicated reference text.
