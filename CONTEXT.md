# Quickshell Environment

This context defines the domain language for the Quickshell Environment (QE),
the persistent desktop shell and its user-facing surfaces.

## Language

**Launcher**:
A transient QE surface for finding and starting eligible desktop applications.
_Avoid_: Application menu, Rofi replacement

**Desktop entry**:
An application registration discovered from the XDG desktop-entry catalogs.
_Avoid_: App shortcut, Exec string

**Eligible application**:
A desktop entry that is presented by the launcher because it is a visible
application entry with a usable main command.

**Main command**:
The structured command associated with a desktop entry's primary launch action;
desktop actions and raw `Exec` strings are not main commands.

**Active monitor**:
The monitor containing the currently focused desktop context when a transient
surface is opened.

**Launch failure**:
A failure to start the selected application's main command, reported in the
launcher without silently switching to another launcher.

**Launch count**:
The number of successful main-command launches recorded for an eligible
application.

**Usage record**:
QE-owned persisted data associating a stable desktop-entry ID with its launch
count.

**Search relevance**:
The match quality between a query and an application's normalized name,
generic name, keywords, or comment.

**Terminal entry**:
A desktop entry marked for execution inside a terminal rather than as a normal
graphical application; terminal entries are not eligible for the v1 launcher.
