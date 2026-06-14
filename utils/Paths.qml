pragma Singleton

import CNS.Config
import CNS
import Quickshell

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string pictures: Quickshell.env("XDG_PICTURES_DIR") || `${home}/Pictures`

    readonly property string data: `${Quickshell.env("XDG_DATA_HOME") || `${home}/.local/share`}/caelestia`
    readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`}/caelestia`
    readonly property string cache: `${Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`}/caelestia`
    readonly property string config: `${Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`}/caelestia-niri-shell`

    readonly property string imagecache: `${cache}/imagecache`
    readonly property string notifimagecache: `${imagecache}/notifs`
    readonly property string notificationsData: `${data}/notifications.json`
    readonly property string eventsData: `${data}/events.json`
    readonly property string wallsdir: {
        const env = Quickshell.env("CAELESTIA_WALLPAPERS_DIR");
        if (env) return env;
        const configured = absolutePath(GlobalConfig.paths.wallpaperDir);
        if (CUtils.exists(configured)) return configured;
        const mediaWallpapers = "/mnt/Media/Images/Wallpapers";
        if (CUtils.exists(mediaWallpapers)) return mediaWallpapers;
        return configured;
    }

    readonly property var wallpaperSourceDirs: {
        const env = Quickshell.env("CAELESTIA_WALLPAPERS_SOURCE_DIRS");
        const dirs = [];
        if (env) {
            const parts = env.split(":");
            for (const p of parts) {
                const trimmed = p.trim();
                if (trimmed && CUtils.exists(trimmed) && trimmed !== wallsdir)
                    dirs.push(trimmed);
            }
        }
        return dirs;
    }
    readonly property string recsdir: Quickshell.env("CAELESTIA_RECORDINGS_DIR") || `${Quickshell.env("XDG_VIDEOS_DIR") || `${home}/Videos`}/Recordings`
    readonly property string libdir: Quickshell.env("CAELESTIA_LIB_DIR") || "/usr/lib/caelestia"

    function toLocalFile(path: url): string {
        path = Qt.resolvedUrl(path);
        return path.toString() ? CUtils.toLocalFile(path) : "";
    }

    function absolutePath(path: string): string {
        return toLocalFile(path.replace("~", home));
    }

    function shortenHome(path: string): string {
        return path.replace(home, "~");
    }
}
