import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: root

    readonly property var players: Mpris.players.values
    readonly property string availability: players.length > 0 ? "available" : "unavailable"
    readonly property string freshness: "current"
    readonly property var lastUpdated: new Date()
    readonly property var lastError: null
    readonly property string operation: "idle"

    function selectedPlayer() {
        const current = players;
        for (const player of current) {
            if (player.canControl && player.isPlaying) return player;
        }
        for (const player of current) {
            if (player.canControl) return player;
        }
        return current.length > 0 ? current[0] : null;
    }

    function call(method) {
        const player = selectedPlayer();
        if (!player || !player.canControl || !player[method]) return false;
        if (method === "next" && !player.canGoNext) return false;
        if (method === "previous" && !player.canGoPrevious) return false;
        if (method === "togglePlaying" && !player.canTogglePlaying) return false;
        player[method]();
        return true;
    }

    function next() { return call("next"); }
    function previous() { return call("previous"); }
    function togglePlaying() { return call("togglePlaying"); }
    function selectedDescription() {
        const player = selectedPlayer();
        if (!player) return "No media player";
        const title = player.trackTitle || "Unknown track";
        const artist = player.trackArtist || player.identity || "Unknown player";
        return `${title} - ${artist}`;
    }
}
