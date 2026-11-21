# ADR-021: Vim-style selector navigation convention

Status: Accepted by user

Decision: focused QE windows with selectable elements support lowercase `h`, `j`,
`k`, and `l` as aliases for left, down, up, and right arrow navigation. A
lowercase `q` is an alias for Escape when Escape dismisses the focused window.
Native arrow keys, Escape, and existing activation keys remain supported. A
surface with a text query field may use a documented modifier for vim-style
navigation; the Phase 7 launcher uses `Alt+h`, `Alt+j`, `Alt+k`, and `Alt+l`.

Context: the theme and wallpaper selectors use focused grid views and already
support keyboard navigation and Escape dismissal. The user requested a
consistent vim-style alternative for these selectors and future QE surfaces.

Rationale: the convention provides efficient keyboard navigation without
removing standard keyboard behavior or changing compositor-owned global
keybindings. Handling remains local to the focused selectable view, preserving
view-local interaction ownership.

Consequences: future selectable QE windows should expose the same aliases when
they provide arrow-key navigation or Escape dismissal. Uppercase or modified
vim keys are not aliases, so they remain available to controls that need them.

Affected areas: `modules/theme/ThemeSelector.qml`,
`modules/wallpaper/WallpaperSelector.qml`, and future selectable QE surfaces.

Revisit if: a future input method requires different modified vim keys, or a
shared keyboard-navigation component becomes justified by additional surfaces.
