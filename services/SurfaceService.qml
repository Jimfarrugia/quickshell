pragma Singleton

import Quickshell

Singleton {
    property bool themeSelectorVisible: false

    function openThemeSelector() { themeSelectorVisible = true; }
    function closeThemeSelector() { themeSelectorVisible = false; }
    function toggleThemeSelector() { themeSelectorVisible = !themeSelectorVisible; }
}
