pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.globals

Singleton {
    id: root

    readonly property var player: MprisController.activePlayer

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/flokshell/coverart"
    readonly property string scriptPath: Quickshell.shellDir + "/scripts/coverart.py"

    // "" when nothing resolved — callers fall back rather than show stale art.
    property string artPath: ""
    property string artOrigin: "none"  // artUrl | embedded | sidecar | online | none
    property bool resolving: false

    readonly property bool hasArt: root.artPath !== ""

    // Browsers publish no desktopEntry, so fall through to identity and the
    // dbus name before giving up.
    readonly property string playerIcon: {
        const p = root.player;
        if (!p)
            return "";
        const name = (p.desktopEntry ?? "") !== "" ? p.desktopEntry : ((p.identity ?? "") !== "" ? p.identity : (p.dbusName ?? "").replace("org.mpris.MediaPlayer2.", "").split(".")[0]);
        if (name === "")
            return "";
        return Quickshell.iconPath(AppSearch.getCachedIcon(name), true);
    }

    readonly property string fallbackMode: Config.media?.coverArtFallback ?? "appIcon"

    // "" means draw a placeholder, not an image.
    readonly property string source: {
        if (root.hasArt)
            return "file://" + root.artPath;
        if (root.fallbackMode === "appIcon" && root.playerIcon !== "")
            return root.playerIcon;
        if (root.fallbackMode === "wallpaper")
            return root.wallpaperPath;
        return "";
    }

    readonly property bool usingFallback: !root.hasArt && root.source !== ""
    readonly property bool showPlaceholder: root.source === ""

    readonly property string wallpaperPath: {
        if (!GlobalStates.wallpaperManager)
            return "";
        const frame = GlobalStates.wallpaperManager.getLockscreenFramePath(GlobalStates.wallpaperManager.currentWallpaper);
        return frame ? "file://" + frame : "";
    }

    // Anything that can change the artwork; nothing that changes per second.
    readonly property string trackKey: {
        const p = root.player;
        if (!p)
            return "";
        return [p.dbusName ?? "", p.trackArtUrl ?? "", root.trackUrl, p.trackTitle ?? "", p.trackArtist ?? "", p.trackAlbum ?? ""].join("\u001f");
    }

    readonly property string trackUrl: {
        const meta = root.player?.metadata ?? null;
        return meta ? (meta["xesam:url"] ?? "") : "";
    }

    onTrackKeyChanged: {
        root.artPath = "";
        root.artOrigin = "none";
        if (root.trackKey === "")
            return;
        debounce.restart();
    }

    // MPRIS delivers one track change as several property updates.
    Timer {
        id: debounce
        interval: 200
        repeat: false
        onTriggered: root.resolve()
    }

    function resolve() {
        const p = root.player;
        if (!p) {
            return;
        }

        const request = {
            "artUrl": p.trackArtUrl ?? "",
            "trackUrl": root.trackUrl,
            "title": p.trackTitle ?? "",
            "artist": p.trackArtist ?? "",
            "album": p.trackAlbum ?? "",
            "embedded": Config.media?.coverArtEmbedded ?? true,
            "online": Config.media?.coverArtOnline ?? false
        };

        resolver.running = false;
        resolver.command = ["python3", root.scriptPath, root.cacheDir, JSON.stringify(request)];
        root.resolving = true;
        resolver.running = true;
    }

    Process {
        id: resolver

        stdout: StdioCollector {
            onStreamFinished: {
                root.resolving = false;
                if (text.trim() === "")
                    return;
                try {
                    const result = JSON.parse(text);
                    root.artPath = result.ok ? result.path : "";
                    root.artOrigin = result.source ?? "none";
                } catch (e) {
                    root.artPath = "";
                    root.artOrigin = "none";
                }
            }
        }

        onExited: root.resolving = false
    }
}
