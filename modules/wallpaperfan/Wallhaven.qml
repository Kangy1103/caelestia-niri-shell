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
    readonly property string script: `${Quickshell.shellPath("scripts/webWallpaper/wallhaven")}/main.py`

    property string currentSearchText: ""
    property string _pendingDownloadPath: ""
    property string downloadingWallpaperId: ""
    property real downloadProgress: 0
    property string downloadError: ""

    // Set by the picker once a download lands, so it can set the wallpaper.
    // CNS: the source calls its own engine here; Wallpapers does it instead.
    property var setWallpaperPath: null

    // Where a result is (or would be) saved.
    function savePathFor(wallpaper): string {
        const ext = wallpaper.fullUrl.split(".").pop().split("?")[0] || "jpg";
        return `${root.wallpaperDir}/${wallpaper.id}.${ext}`;
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
    // The source keeps these in SettingsConfig and re-fetches on each change;
    // here they are session state, with re-fetch left to the caller.
    property string categories: "general,anime"
    property string purity: "sfw"
    property string sorting: "date_added"
    property string order: "desc"
    property string topRange: ""
    property string resolution: ""
    property string color: ""

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
            "--dir", wallpaperDir, "--json"
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
    property var savedPaths: []

    function cyclePurity(): void {
        const all = ["sfw", "sfw,sketchy", "sfw,sketchy,nsfw"];
        purity = all[(all.indexOf(purity) + 1) % all.length];
        fetchWallhaven(true);
    }

    function cycleSort(): void {
        const all = ["date_added", "relevance", "toplist", "favorites", "random"];
        sorting = all[(all.indexOf(sorting) + 1) % all.length];
        topRange = sorting === "toplist" ? "1M" : "";
        fetchWallhaven(true);
    }

    function cycleOrder(): void {
        order = order === "desc" ? "asc" : "desc";
        fetchWallhaven(true);
    }

    function cycleRange(): void {
        const all = ["1d", "3d", "1w", "1M", "3M", "6M", "1y"];
        topRange = all[(all.indexOf(topRange) + 1) % all.length];
        fetchWallhaven(true);
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
                    const incoming = (payload.data ?? []).map(item => ({
                        id: item.id,
                        thumbUrl: item.thumbs?.large ?? "",
                        fullUrl: item.path ?? "",
                        resolution: item.resolution ?? "",
                        colors: item.colors ?? [],
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