pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import CNS.Config
import CNS.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        Quickshell.execDetached(["cns", "wallpaper", "-r", ...smartArg]);
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        Quickshell.execDetached(["cns", "wallpaper", "-f", path, ...smartArg]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["cns", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["cns", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }

    Process {
        id: getPreviewColoursProc

        command: ["cns", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }

    // CNS: video-wallpaper detection. main's Wallpapers.qml had this; the sync
    // took upstream's version, which has no video support, but
    // modules/background/Wallpaper.qml still calls it for both `isVideo` and
    // the video-frame colour source.
    function isPathVideo(path: string): bool {
        if (!path)
            return false;
        const p = path.toString().toLowerCase();
        return p.endsWith(".mp4") || p.endsWith(".mkv") || p.endsWith(".webm") || p.endsWith(".mov") || p.endsWith(".avi") || p.endsWith(".m4v");
    }

    function getColorSource(path: string): string {
        if (!isPathVideo(path))
            return path;
        const hash = Qt.md5(path.toString());
        return `${Paths.state}/generated/video_frames/${hash}.png`;
    }
}
