pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

// The wallpaper picker's own settings.
//
// The source keeps these on a SettingsConfig singleton. CNS has no equivalent
// and they are not worth a GlobalConfig node each, so they live here, persisted
// to the shell's state directory alongside the other picker's files.
//
// `wallpaperCommand` from the source is deliberately absent: that is the
// wallpaper engine's setter, and CNS sets wallpapers through its own Wallpapers
// service instead.
Scope {
    id: root

    // ── Persisted ───────────────────────────────────────────────────────
    property bool wallpaperLivePreview: true
    property bool wallpaperAnimateChoice: true
    property string wallhavenSorting: "date_added"
    property string wallhavenPurity: "sfw"
    property string wallhavenOrder: "desc"
    property string wallhavenCategories: "general,anime"
    property string wallhavenTopRange: ""
    property string wallhavenAtleast: ""
    property string wallhavenRatios: ""
    property string wallpaperDir: Paths.wallsdir

    // The API key is CNS's own, read from the bundled client's config.
    readonly property string wallhavenApiKey: _apiKey

    // ── Not persisted ───────────────────────────────────────────────────
    // Only the picker touches these; they are here so the two files that need
    // them agree on one source.
    property string wallhavenResolution: ""
    property string wallhavenColor: ""

    readonly property string storePath: `${Paths.state}/wallpaper-picker.json`

    function toJSON(): string {
        return JSON.stringify({
            version: 1,
            wallpaperLivePreview,
            wallpaperAnimateChoice,
            wallhavenSorting,
            wallhavenPurity,
            wallhavenOrder,
            wallhavenCategories,
            wallhavenTopRange,
            wallhavenAtleast,
            wallhavenRatios,
            wallpaperDir
        });
    }

    function apply(d: var): void {
        if (!d || d.version !== 1)
            return;
        wallpaperLivePreview = d.wallpaperLivePreview ?? wallpaperLivePreview;
        wallpaperAnimateChoice = d.wallpaperAnimateChoice ?? wallpaperAnimateChoice;
        wallhavenSorting = d.wallhavenSorting ?? wallhavenSorting;
        wallhavenPurity = d.wallhavenPurity ?? wallhavenPurity;
        wallhavenOrder = d.wallhavenOrder ?? wallhavenOrder;
        wallhavenCategories = d.wallhavenCategories ?? wallhavenCategories;
        wallhavenTopRange = d.wallhavenTopRange ?? wallhavenTopRange;
        wallhavenAtleast = d.wallhavenAtleast ?? wallhavenAtleast;
        wallhavenRatios = d.wallhavenRatios ?? wallhavenRatios;
        wallpaperDir = d.wallpaperDir ?? wallpaperDir;
    }

    Timer {
        id: writeTimer

        interval: 400
        repeat: false
        onTriggered: store.setText(root.toJSON())
    }

    FileView {
        id: store

        path: root.storePath
        printErrors: false

        onLoaded: {
            try {
                root.apply(JSON.parse(text()));
            } catch (e) {
                console.warn("wallpaper picker settings:", e);
            }
        }
    }

    property string _apiKey: ""

    // The Wallhaven key lives in the bundled client's own config, which is
    // where the Nexus Web Wallpaper page already expects it.
    FileView {
        id: apiKeyFile

        path: `${Quickshell.env("XDG_CONFIG_HOME") || `${Paths.home}/.config`}/caelestia-niri-shell/wallhaven`
        printErrors: false

        onLoaded: {
            const m = text().match(/api_key\s*=\s*"([^"]*)"/);
            root._apiKey = m ? m[1] : "";
        }
    }

    // Any change is worth writing back.
    onWallpaperLivePreviewChanged: writeTimer.restart()
    onWallpaperAnimateChoiceChanged: writeTimer.restart()
    onWallhavenSortingChanged: writeTimer.restart()
    onWallhavenPurityChanged: writeTimer.restart()
    onWallhavenOrderChanged: writeTimer.restart()
    onWallhavenCategoriesChanged: writeTimer.restart()
    onWallhavenTopRangeChanged: writeTimer.restart()
    onWallhavenAtleastChanged: writeTimer.restart()
    onWallhavenRatiosChanged: writeTimer.restart()
    onWallpaperDirChanged: writeTimer.restart()
}