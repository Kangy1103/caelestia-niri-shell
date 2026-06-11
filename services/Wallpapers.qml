pragma Singleton

import Caelestia.Config
import qs.utils
import Caelestia
import Caelestia.Models
import Quickshell
import Quickshell.Io
import QtQuick

Searcher {
    id: root

    readonly property string stateDir: `${Paths.state}/wallpaper`
    readonly property string currentNamePath: `${stateDir}/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear
    property bool initialized: false

    property string _pendingWallpaper: ""

    signal frameReady(string path)

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        const entries = wallpapers.entries;
        if (entries.length === 0) return;
        const randomIndex = Math.floor(Math.random() * entries.length);
        setWallpaper(entries[randomIndex].path);
    }

    function setWallpaper(path: string): void {
        if (isPathVideo(path)) {
            const framePath = getColorSource(path);
            if (CUtils.exists(framePath)) {
                applyWallpaper(path);
            } else {
                _pendingWallpaper = path;

                extractFrameProcess.command = [
                    "bash", "-c",
                    "mkdir -p \"$(dirname \"$2\")\" && (ffmpeg -y -ss 0 -hwaccel auto -loglevel error -i \"$1\" -an -vframes 1 -update 1 \"$2\" || ffmpeg -y -ss 0 -hwaccel none -loglevel error -i \"$1\" -an -vframes 1 -update 1 \"$2\")",
                    "--", path, framePath
                ];

                extractFrameProcess.running = true;
            }
        } else {
            applyWallpaper(path);
        }
    }

    function applyWallpaper(path: string): void {
        actualCurrent = path;
        ensureStateDir.running = true;

        Qt.callLater(() => {
            runColorGeneration(path);
        });
    }

    Process {
        id: extractFrameProcess

        onExited: (exitCode) => {
            if (exitCode === 0) {
                const path = root._pendingWallpaper;
                root.frameReady(path);
                root.applyWallpaper(path);
            } else {
                console.error("Frame extraction failed with code:", exitCode);
                root.applyWallpaper(root._pendingWallpaper);
            }
            root._pendingWallpaper = "";
        }

        stderr: SplitParser {
            onRead: data => {
                if (data.includes("Error") || data.includes("failed"))
                    console.warn("Extraction error:", data);
            }
        }
    }

    function isPathVideo(path: string): bool {
        if (!path) return false;
        const p = path.toString().toLowerCase();
        return p.endsWith(".mp4") || p.endsWith(".mkv") || p.endsWith(".webm") ||
               p.endsWith(".mov") || p.endsWith(".avi") || p.endsWith(".m4v");
    }

    function getColorSource(path: string): string {
        if (!isPathVideo(path)) return path;
        const hash = Qt.md5(path.toString());
        return `${Paths.state}/generated/video_frames/${hash}.png`;
    }

    function variantToMatugenType(variant) {
        const variantMap = {
            "content": "scheme-content",
            "expressive": "scheme-expressive",
            "fidelity": "scheme-fidelity",
            "fruitsalad": "scheme-fruit-salad",
            "monochrome": "scheme-monochrome",
            "neutral": "scheme-neutral",
            "rainbow": "scheme-rainbow",
            "tonalspot": "scheme-tonal-spot",
            "vibrant": "scheme-vibrant"
        };
        return variantMap[variant] || "scheme-tonal-spot";
    }

    function runColorGeneration(imagePath, variant) {
        variant = variant || "";
        if (!imagePath) return;
        try {
            const scriptPath = Qt.resolvedUrl("../scripts/colors/switchwall.sh").toString().replace("file://", "");
            const mode = Colours.light ? "light" : "dark";
            const schemeType = variantToMatugenType(variant || Schemes.currentVariant || "tonalspot");
            colorGenProcess.command = ["bash", scriptPath, "--mode", mode, "--type", schemeType, imagePath];
            colorGenProcess.running = true;
        } catch (e) {
            console.warn("Failed to run color generation:", e);
            try {
                matugenProcess.command = ["matugen", "image", imagePath, "--source-color-index", "0"];
                matugenProcess.running = true;
            } catch (e2) {
                console.warn("Failed to run matugen:", e2);
            }
        }
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;
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

    function loadFromConfig(): void {
        if (!actualCurrent && GlobalConfig.paths.wallpaper) {
            const path = Paths.absolutePath(GlobalConfig.paths.wallpaper);
            setWallpaper(path);
        }
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    Timer {
        interval: 100
        running: true
        onTriggered: root.loadFromConfig()
    }

    IpcHandler {
        target: "wallpaper"

        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }
    }

    Process {
        id: ensureStateDir

        command: ["mkdir", "-p", root.stateDir]

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                stateFile.watchChanges = false;
                stateFile.setText(root.actualCurrent);
                stateFile.watchChanges = true;
            } else {
                console.warn("Wallpapers: Failed to create state directory:", root.stateDir);
            }
        }
    }

    Process {
        id: matugenProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Matugen exited with code:", exitCode);
            }
        }

        stderr: SplitParser {
            onRead: data => console.warn("Matugen error:", data)
        }
    }

    Process {
        id: colorGenProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Color generation exited with code:", exitCode);
            }
        }

        stdout: SplitParser {
            onRead: data => {}
        }

        stderr: SplitParser {
            onRead: data => {
                if (!data.includes("theme updated") && !data.includes("SVG colors"))
                    console.warn("Color gen error:", data);
            }
        }
    }

    FileView {
        id: stateFile
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
            }
            root.setWallpaper(wall);
            root.previewColourLock = false;
            root.initialized = true;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            root.initialized = true;
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp", "*.webp", "*.mp4", "*.webm", "*.mkv"]
    }
}
