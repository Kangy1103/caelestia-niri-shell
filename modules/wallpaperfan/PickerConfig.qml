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

    // How a wallpaper that doesn't match the screen's aspect is drawn.
    //  crop — fill the screen, cropping the overflow (what the shell has
    //         always done; a 16:9 wallpaper on a 21:9 screen loses top and
    //         bottom, and a portrait one is magnified into a narrow strip).
    //  fit  — show the whole wallpaper, letterboxed.
    //  blur — the whole wallpaper, centred, over a blurred, scaled copy of
    //         itself filling the gaps. Fills without cropping or distorting.
    property string wallpaperFit: "crop"

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
            wallpaperDir,
            wallpaperFit
        });
    }

    function apply(d: var): void {
        if (!d || d.version !== 1)
            return;
        wallpaperLivePreview = d.wallpaperLivePreview ?? wallpaperLivePreview;
        wallpaperAnimateChoice = d.wallpaperAnimateChoice ?? wallpaperAnimateChoice;
        wallhavenSorting = d.wallhavenSorting ?? wallhavenSorting;
        // An earlier build stored these as the source's "110"/"100" bitmask and
        // the category chips wrote "0"/"1" over the real characters, leaving
        // values like "10neral,anime" and "010" — which no search could satisfy.
        // Anything outside the vocabulary is dropped rather than passed on.
        wallhavenPurity = normaliseList(d.wallhavenPurity, ["sfw", "sketchy", "nsfw"], wallhavenPurity);
        wallhavenOrder = normalise(d.wallhavenOrder, ["asc", "desc"], wallhavenOrder);
        wallhavenCategories = normaliseList(d.wallhavenCategories, ["general", "anime", "people"], wallhavenCategories);
        wallhavenTopRange = d.wallhavenTopRange ?? wallhavenTopRange;
        // Aspect band, and a WxH minimum the API understands.
        wallhavenRatios = normalise(d.wallhavenRatios, ["", "ultrawide", "widescreen", "square", "portrait"], wallhavenRatios);
        wallhavenAtleast = normalise(d.wallhavenAtleast, ["", "1920x1080", "2560x1440", "3840x2160", "5120x2880"], wallhavenAtleast);
        wallpaperDir = d.wallpaperDir ?? wallpaperDir;
        wallpaperFit = normalise(d.wallpaperFit, ["crop", "fit", "blur"], wallpaperFit);
    }

    // Keeps `value` only if it is one of `allowed`, else the fallback.
    function normalise(value: var, allowed: var, fallback: string): string {
        return allowed.indexOf(value) >= 0 ? value : fallback;
    }

    // The comma-separated form, with any unrecognised or empty entry dropped.
    // A bitmask like "010" shares no characters with the vocabulary, so it is
    // discarded wholesale; nothing valid survives it by accident.
    function normaliseList(value: var, allowed: var, fallback: string): string {
        if (typeof value !== "string")
            return fallback;
        const kept = value.split(",").map(s => s.trim()).filter(s => allowed.indexOf(s) >= 0);
        return kept.length > 0 ? kept.join(",") : fallback;
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
    onWallpaperFitChanged: writeTimer.restart()
}
