pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

// Wallhaven results for the picker, driven by CNS's own bundled client
// (scripts/webWallpaper/wallhaven). Search and download both return JSON, so
// nothing here needs its own HTTP client or Python daemon.
//
// CNS: the source talks to Wallhaven's HTTP API itself and writes the file
// itself; this keeps that behaviour but swaps the transport for the bundled
// client and, on commit, hands the saved path to CNS's Wallpapers service
// rather than setting it here. The property and function names are the
// source's, so modules/wallpaper/Wallpaper.qml ports across unchanged.
Scope {
    id: root

    readonly property string wallpaperDir: Paths.wallsdir
    // The picker supplies its settings; the filter state is read off these
    // rather than kept here, so the chips and the search agree.
    required property var config
    readonly property string script: `${Quickshell.shellPath("scripts/webWallpaper/wallhaven")}/main.py`

    property string currentSearchText: ""
    property string _pendingDownloadPath: ""
    property string downloadingWallpaperId: ""
    property real downloadProgress: 0
    property string downloadError: ""

    // Set by the picker once a download lands, so it can set the wallpaper.
    // CNS: the source calls its own engine here; Wallpapers does it instead.
    property var setWallpaperPath: null

    // Wallhaven's own tree, kept out of the top level of the wallpaper folder so
    // it doesn't crowd the local listing: <walls>/wallhaven/<category>/.
    readonly property string downloadRoot: `${wallpaperDir}/wallhaven`

    // The subfolder a result belongs in, from the category the search reported
    // (general / anime / people).
    function saveDirFor(wallpaper): string {
        const cat = (wallpaper?.category ?? "").trim();
        return `${root.downloadRoot}/${cat !== "" ? cat : "general"}`;
    }

    // Where a result is (or would be) saved. Must match the downloader's own
    // naming — it writes "wallhaven-<id>.<ext>" — or isSaved() never matches
    // and the same wallpaper is fetched again every time.
    function savePathFor(wallpaper): string {
        const ext = (wallpaper?.fullUrl ?? "").split(".").pop().split("?")[0] || "jpg";
        return `${root.saveDirFor(wallpaper)}/wallhaven-${wallpaper.id}.${ext}`;
    }

    // ── Online / Wallhaven ───────────────────────────────────────────────
    // A result: { id, thumbUrl, fullUrl, resolution, colors, favorites, fileSize }
    property list<var> onlineWallpapers: []
    property bool isFetchingOnline: false
    property int onlinePage: 1
    property bool hasMorePages: false
    property bool _discardFetch: false
    property string onlineError: ""

    // ── Filters ─────────────────────────────────────────────────────────
    // These live in PickerConfig, which is what the picker's filter chips
    // write to. They used to be duplicated here as plain properties, which
    // silently did nothing: the chips updated the config while buildArgs()
    // went on reading these stale copies, so no filter ever changed a search.
    readonly property string categories: config.wallhavenCategories
    readonly property string purity: config.wallhavenPurity
    readonly property string sorting: config.wallhavenSorting
    readonly property string order: config.wallhavenOrder
    readonly property string topRange: config.wallhavenTopRange
    // Minimum resolution, as WxH. Persisted as wallhavenAtleast; this used to
    // read wallhavenResolution, which PickerConfig does not persist, so the
    // setting never survived a restart and never reached a search.
    readonly property string resolution: config.wallhavenAtleast
    readonly property string color: config.wallhavenColor
    // Aspect band: "", "ultrawide", "widescreen" or "portrait".
    readonly property string aspect: config.wallhavenRatios

    // Wallhaven accepts a ratios= parameter but ignores it on the public API
    // (verified: ratios=21:9 returns portrait results), so the band is applied
    // to each result as it arrives instead. Bands are on width/height.
    function aspectMatches(ratioText: string): bool {
        if (root.aspect === "")
            return true;
        const parts = String(ratioText ?? "").split(":");
        const r = parts.length === 2 ? parseFloat(parts[0]) / parseFloat(parts[1]) : NaN;
        if (isNaN(r))
            return true;
        switch (root.aspect) {
            case "ultrawide": return r >= 2.0;
            case "widescreen": return r >= 1.4 && r < 2.0;
            case "square": return r >= 0.95 && r < 1.4;
            case "portrait": return r < 0.95;
            default: return true;
        }
    }

    function buildArgs(page: int): array {
        const args = [
            "search",
            "--json",
            "--categories", categories,
            "--purity", purity,
            "--sort", sorting,
            "--order", order,
            "--page", String(page),
            "-n", "24"
        ];
        if (currentSearchText.trim() !== "")
            args.push(currentSearchText.trim());
        if (sorting === "toplist" && topRange !== "")
            args.push("--range", topRange);
        if (resolution !== "")
            args.push("--resolution", resolution);
        if (color !== "")
            args.push("--colors", color);
        return args;
    }

    function fetchWallhaven(resetPage: bool): void {
        if (isFetchingOnline)
            return;
        if (resetPage) {
            onlinePage = 1;
            hasMorePages = false;
            onlineError = "";
            onlineWallpapers = [];
        }
        if (!resetPage && !hasMorePages)
            return;

        isFetchingOnline = true;
        search.command = ["python3", script].concat(buildArgs(onlinePage));
        search.running = true;
    }

    function fetchNextPage(): void {
        if (!hasMorePages || isFetchingOnline)
            return;
        onlinePage++;
        fetchWallhaven(false);
    }

    // A filter changed. Only worth re-running when the Wallhaven source is
    // actually on screen — otherwise it fires a request nobody is looking at,
    // and the picker resets the list when it opens anyway.
    function refetch(): void {
        if (onlineActive && !isFetchingOnline)
            refetchTimer.restart();
    }

    // Whether the picker is currently showing Wallhaven results.
    property bool onlineActive: false

    // Back to a blank search (the picker calls this when it's destroyed, so it
    // opens fresh). A fetch in flight is stopped and its result dropped.
    function resetSearch(): void {
        _discardFetch = true;
        if (isFetchingOnline) {
            search.running = false;
            isFetchingOnline = false;
        }
        // Before the list: emptying it looks like reaching its end to the
        // picker, which would fetch the next page.
        hasMorePages = false;
        currentSearchText = "";
        onlineWallpapers = [];
        onlinePage = 1;
        onlineError = "";
        downloadError = "";
    }

    function updateSearch(searchText: string): void {
        currentSearchText = searchText;
        fetchWallhaven(true);
    }

    // The source re-fetches whenever a filter changes. Without this the chips
    // only repainted: the list stayed exactly as the last search left it.
    // Batched so a burst of changes (categories toggling off, then on) is one
    // request, and ignored while a fetch is already in flight.
    Timer {
        id: refetchTimer
        interval: 120
        onTriggered: root.fetchWallhaven(true)
    }

    Connections {
        target: root.config

        function onWallhavenSortingChanged(): void { root.refetch(); }
        function onWallhavenPurityChanged(): void { root.refetch(); }
        function onWallhavenOrderChanged(): void { root.refetch(); }
        function onWallhavenCategoriesChanged(): void { root.refetch(); }
        function onWallhavenTopRangeChanged(): void { root.refetch(); }
        function onWallhavenAtleastChanged(): void { root.refetch(); }
        function onWallhavenRatiosChanged(): void { root.refetch(); }
    }

    // Downloads one result into CNS's wallpaper folder. The saved path is
    // handed to the picker, which sets it once the download lands.
    function downloadAndSetWallpaper(wallpaper): void {
        if (!wallpaper || _pendingDownloadPath.length > 0)
            return;
        _pendingDownloadPath = savePathFor(wallpaper);
        downloadingWallpaperId = wallpaper.id;
        downloadProgress = 0;
        downloadError = "";
        downloadProcess.command = [
            "python3", script, "download", wallpaper.id,
            // Into its category folder, not the top of the wallpaper tree.
            "--dir", saveDirFor(wallpaper), "--json"
        ];
        downloadProcess.running = true;
    }

    // The picker's helper for "this one saved before?" — the file is already
    // in the wallpaper folder under this id.
    function isSaved(wallpaper): bool {
        return onlineWallpapers.some(w => w.id === wallpaper.id)
            && savePathFor(wallpaper).length > 0
            && savedPaths.indexOf(wallpaper.id) !== -1;
    }

    // Ids known to exist on disk, filled in by the picker from Wallpapers.list.
    // Which results are already on disk, so the picker can badge them and skip
    // re-downloading. This was declared and never filled in, so isSaved() was
    // permanently false. Results are filed as <wallhaven>/<category>/
    // wallhaven-<id>.<ext>, so the scan looks one level into each category.
    // FileView can't help: this build of Quickshell's FileView is file-only,
    // with no directory model.
    property var savedPaths: []

    function refreshSaved(): void {
        savedScan.running = true;
    }

    Component.onCompleted: refreshSaved()

    Process {
        id: savedScan

        command: ["sh", "-c",
            `find "${root.downloadRoot}" -maxdepth 2 -type f -name 'wallhaven-*' -printf '%f\\n' 2>/dev/null`]

        stdout: StdioCollector {
            onStreamFinished: {
                root.savedPaths = text.trim().split("\n")
                    .filter(n => n.startsWith("wallhaven-"))
                    .map(n => n.substring("wallhaven-".length).split(".")[0])
                    .filter(n => n.length > 0);
            }
        }
    }





    Process {
        id: search

        stdout: StdioCollector {
            onStreamFinished: {
                if (root._discardFetch) {
                    root._discardFetch = false;
                    return;
                }
                root.isFetchingOnline = false;
                if (!text.trim())
                    return;
                try {
                    const payload = JSON.parse(text);
                    // The API's own ratios filter is a no-op, so drop results
                    // outside the chosen band here.
                    const incoming = (payload.data ?? [])
                        .filter(item => root.aspectMatches(item.ratio))
                        .map(item => ({
                        id: item.id,
                        thumbUrl: item.thumbs?.large ?? "",
                        fullUrl: item.path ?? "",
                        resolution: item.resolution ?? "",
                        colors: item.colors ?? [],
                        // Kept so saveDirFor() can file the download by category.
                        category: item.category ?? "",
                        favorites: item.favorites ?? 0,
                        fileSize: item.file_size ?? 0
                    }));
                    const first = root.onlinePage === 1;
                    root.onlineWallpapers = first ? incoming : root.onlineWallpapers.concat(incoming);
                    const last = payload.meta?.last_page ?? root.onlinePage;
                    root.hasMorePages = root.onlinePage < last;
                    if (first && incoming.length === 0)
                        root.onlineError = qsTr("No results");
                } catch (e) {
                    root.onlineError = qsTr("Could not read the search results");
                    console.warn("wallpaper wallhaven:", e);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    root.isFetchingOnline = false;
                    root.onlineError = qsTr("Wallhaven search failed");
                    console.warn("wallpaper wallhaven:", text.trim());
                }
            }
        }
    }

    Process {
        id: downloadProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim())
                    return;
                try {
                    const payload = JSON.parse(text);
                    const results = Array.isArray(payload) ? payload : payload.results ?? [];
                    const saved = results.find(entry => entry?.ok)?.path ?? payload.path ?? "";
                    if (saved) {
                        // CNS: the source sets the wallpaper through its own
                        // engine; hand the saved path to the picker instead.
                        if (root.setWallpaperPath)
                            root.setWallpaperPath(saved);
                        root._pendingDownloadPath = "";
                        // This one is on disk now, so the badge should show.
                        root.refreshSaved();
                    } else {
                        root.downloadError = qsTr("Download failed");
                    }
                } catch (e) {
                    root.downloadError = qsTr("Could not read the download result");
                    console.warn("wallpaper wallhaven:", e);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    root.downloadError = text.trim();
                    console.warn("wallpaper wallhaven:", text.trim());
                }
            }
        }

        onExited: {
            root.downloadingWallpaperId = "";
            root.downloadProgress = 0;
            root._pendingDownloadPath = "";
        }
    }
}