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
graphical application; the launcher starts these through the configured terminal
emulator.

**Help surface**:
A standalone transient QE surface for browsing and searching the curated help
reference.

**Reference catalog**:
User-authored help data that describes QE keybindings and common QE commands;
it is the sole authority for displayed help content and is not live system
state.

**Help entry**:
A single labeled item in the reference catalog describing a keybinding or QE
command.

**Dashboard**:
A transient QE surface for interacting with one system capability, such as
audio, Bluetooth, or network state.
_Avoid_: Popup, application window

**Dashboard shell**:
The shared presentation and placement boundary that hosts feature-specific
dashboard content.
_Avoid_: Dashboard window

**Dashboard action**:
A stable QE action identifier that requests a dashboard operation, such as
opening or toggling a dashboard, through the shared surface-routing contract.
_Avoid_: Dashboard command, shell command

**Source module**:
The bar module associated with a dashboard and used as its primary launch
point; its bar position determines the dashboard's anchored side.
_Avoid_: Trigger widget, dashboard button

**Known Bluetooth device**:
A Bluetooth device whose confirmed BlueZ state is paired or bonded.

**Discovered Bluetooth device**:
A currently observed Bluetooth device that is not confirmed paired or bonded;
it is not persisted by QE.

**Interactive Bluetooth pairing**:
A pairing flow requiring a PIN, passkey, numeric confirmation, or authorization
prompt that QE cannot handle through the installed native API and therefore
keeps available through Blueman.

**Personal Wi-Fi management**:
QE-owned inspection and operation of ordinary Wi-Fi connections, including
enable/disable, connect, disconnect, and forget; wired networking is inspection-
only in the initial network dashboard.

**Visible SSID row**:
A dashboard representation of one currently observed Wi-Fi network identity;
distinct saved profiles behind that identity remain separate and selectable.

**Ephemeral PSK prompt**:
A local dashboard prompt whose password is passed directly to the native
connection API for one operation and is neither persisted nor logged by QE.

**Unsupported network profile**:
A network configuration or authentication flow outside the initial native
personal Wi-Fi boundary, such as enterprise/EAP, VPN, proxy, hidden-network
creation, or arbitrary profile editing; it remains available through
`nm-connection-editor`.

**Active network device**:
The default or currently relevant NetworkManager device selected for the
dashboard's primary controls; other devices are not independently managed in
the initial dashboard.

**Saved network profile**:
A NetworkManager connection setting associated with a visible SSID. Multiple
saved profiles may belong to one visible SSID and remain distinct choices.

**Default active device**:
The NetworkManager-selected device QE uses for primary dashboard controls when
multiple devices are present; the dashboard does not add user device selection
in the initial version.

**Inline authentication retry**:
A failed Wi-Fi authentication remains represented as disconnected with a
redacted failure reason and offers another ephemeral PSK prompt in the same
dashboard row.

**Personal Wi-Fi profile**:
An ordinary open or PSK NetworkManager profile that QE may connect to or create
through the native API; it excludes enterprise, VPN, proxy, hidden-network, and
arbitrary edited profiles.

**Supersedable network intent**:
A newer request for the same network target or radio control that invalidates an
older pending request; only the newest request may be treated as confirmed.

**Normalized network security**:
QE's display categories for native Wi-Fi security details: Open, Personal,
Enterprise, WEP/Legacy, or Unknown. Only Open and Personal are connectable in
the initial dashboard.

**NetworkManager unavailable state**:
The dashboard state in which NetworkManager has disappeared or has not supplied
current data; actionable network controls are disabled and no stale network list
is presented as current.

**Connection attempt**:
A single native request to connect to a personal Wi-Fi profile or SSID. Its PSK,
when needed, exists only for that attempt and is not a profile edit.

**NetworkManager-owned credential update**:
When a saved personal Wi-Fi profile is retried with a new PSK, NetworkManager
may update that profile through its native API; QE does not retain ownership of,
persist, or log the credential.
