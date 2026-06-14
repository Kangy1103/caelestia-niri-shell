// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260614

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import CNS
import CNS.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.components.filedialog
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Web Wallpapers")
    isSubPage: true

    readonly property string scriptBaseDir: Qt.resolvedUrl("../../../../scripts/webWallpaper").toString().replace("file://", "")
    property string currentServer: "uhdpaper"
    readonly property string scriptDir: scriptBaseDir + "/" + currentServer

    property string keyword: ""
    property string resolution: {
        if (currentServer === "uhdpaper") return "2k";
        if (currentServer === "bing") return "UHD";
        return "1920x1080";
    }
    property bool loading: false
    property var wallpapers: []
    property var categoriesList: []

    property var wallhavenCategories: ["general", "anime"]
    property var wallhavenPurity: ["sfw"]
    property string wallhavenSort: "date_added"
    property string wallhavenRange: "1M"
    property string wallhavenColor: ""
    property bool showApiKey: false
    property bool isClearingApiKey: false
    property bool wallhavenHasApiKey: false
    property string _pendingDownloadSlug: ""

    property int currentApiPage: 1
    property int lastApiPage: 1

    property int currentPage: 0
    readonly property int itemsPerPage: Config.nexus.wallpapersPerRow * 4
    readonly property var paginatedWallpapers: wallpapers.slice(currentPage * itemsPerPage, (currentPage + 1) * itemsPerPage)

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        WebWallpaperFilters {
            Layout.fillWidth: true
            gridRoot: root
        }

        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: 400
            implicitHeight: Math.ceil(paginatedWallpapers.length / Config.nexus.wallpapersPerRow) * (root.cappedWidth / Config.nexus.wallpapersPerRow + Tokens.spacing.small)

            GridLayout {
                anchors.fill: parent
                visible: root.wallpapers.length > 0 && !root.loading

                columns: Config.nexus.wallpapersPerRow
                rowSpacing: Tokens.spacing.small
                columnSpacing: Tokens.spacing.large

                Repeater {
                    model: root.paginatedWallpapers
                    delegate: Item {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: width

                        WebWallpaperDelegate {
                            anchors.fill: parent
                            modelData: parent.modelData
                            isDownloading: downloadProcess.running && downloadProcess.currentSlug === parent.modelData.slug
                            onClicked: root.downloadAndSet(parent.modelData.slug)
                            onDownload: root.downloadOnly(parent.modelData.slug)
                        }
                    }
                }
            }

            StyledBusyIndicator {
                anchors.centerIn: parent
                visible: root.loading
            }

            StyledText {
                anchors.centerIn: parent
                text: qsTr("No wallpapers found — try searching for something")
                visible: root.wallpapers.length === 0 && !root.loading
                opacity: 0.6
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.medium
            visible: root.wallpapers.length > root.itemsPerPage && !root.loading
            spacing: Tokens.spacing.large

            IconButton {
                icon: "chevron_left"
                onClicked: {
                    if (root.currentPage > 0)
                        root.currentPage--;
                }
                enabled: root.currentPage > 0
                type: IconButton.Tonal
            }

            StyledText {
                text: qsTr("Page %1 of %2").arg(root.currentPage + 1).arg(Math.ceil(root.wallpapers.length / root.itemsPerPage))
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }

            IconButton {
                icon: "chevron_right"
                onClicked: {
                    if ((root.currentPage + 1) * root.itemsPerPage < root.wallpapers.length) {
                        root.currentPage++;
                    } else if (root.currentServer === "wallhaven" && root.currentApiPage < root.lastApiPage) {
                        root.currentApiPage++;
                        root.fetchWallpapers(false);
                        root.currentPage++;
                    }
                }
                enabled: ((root.currentPage + 1) * root.itemsPerPage < root.wallpapers.length) || (root.currentServer === "wallhaven" && root.currentApiPage < root.lastApiPage)
                type: IconButton.Tonal
            }
        }

        Process {
            id: listProcess

            stdout: StdioCollector {
                onStreamFinished: {
                    root.loading = false;
                    if (text) {
                        try {
                            let response = JSON.parse(text);
                            let newData = [];
                            if (root.currentServer === "wallhaven") {
                                root.lastApiPage = response.meta.last_page;
                                let rawData = response.data;
                                for (let i = 0; i < rawData.length; i++) {
                                    newData.push({ slug: rawData[i].id, url_thumb: rawData[i].thumbs.large });
                                }
                            } else {
                                newData = response;
                            }
                            if (root.currentApiPage === 1) root.wallpapers = newData;
                            else root.wallpapers = root.wallpapers.concat(newData);
                        } catch (e) { console.error("Failed to parse wallpaper list:", e, "Output was:", text); }
                    }
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    if (text) console.warn("List process error:", text);
                }
            }
        }

        Process {
            id: flareProcess

            stdout: StdioCollector {
                onStreamFinished: {
                    root.loading = false;
                    if (text) {
                        try {
                            root.wallpapers = JSON.parse(text);
                        } catch (e) { console.error("Failed to parse Flare list:", e); }
                    }
                }
            }
        }

        Process {
            id: categoryProcess
            stdout: StdioCollector {
                onStreamFinished: {
                    if (text) {
                        try {
                            const data = JSON.parse(text);
                            const list = [];
                            for (let key in data) list.push({name: key, query: data[key]});
                            root.categoriesList = list;
                        } catch (e) { console.error("Failed to parse categories:", e, "Output was:", text); }
                    }
                }
            }
        }

        Process {
            id: checkApiKeyProcess
            stdout: StdioCollector {
                onStreamFinished: {
                    if (text) {
                        root.wallhavenHasApiKey = text.indexOf("api_key                   ***") !== -1;
                    }
                }
            }
        }

        Process {
            id: configProcess
            stdout: StdioCollector {
                onStreamFinished: {
                    if (text && configProcess.exitCode === 0)
                        console.log("Wallhaven config updated:", text);
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    if (text && configProcess.exitCode !== 0)
                        console.warn("Config process error:", text);
                }
            }
            onExited: (code) => {
                if (code === 0) {
                    if (!root.isClearingApiKey) {
                        root.wallhavenHasApiKey = true;
                        Toaster.toast(qsTr("Wallhaven Config"), qsTr("Settings updated successfully"), "key");
                    } else {
                        root.wallhavenHasApiKey = false;
                    }
                } else {
                    Toaster.toast(qsTr("Wallhaven Config"), qsTr("Invalid API Key. Please check and try again."), "key_off");
                }
                root.isClearingApiKey = false;
            }
        }

        Process {
            id: downloadProcess
            property string currentSlug: ""

            stdout: StdioCollector {
                onStreamFinished: {
                    if (text) {
                        try {
                            const result = JSON.parse(text);
                            if (result.status === "success")
                                Wallpapers.setWallpaper(result.path);
                        } catch (e) { console.error("Failed to parse download result:", e, "Output was:", text); }
                    }
                    downloadProcess.currentSlug = "";
                }
            }
        }

        Process {
            id: downloadOnlyProcess
            property string currentSlug: ""

            stdout: StdioCollector {
                onStreamFinished: {
                    if (text) {
                        try {
                            const result = JSON.parse(text);
                            if (result.status === "success")
                                Toaster.toast(qsTr("Wallpaper saved"), result.path ? result.path.split("/").pop() : "", "download_done");
                        } catch (e) { console.error("Failed to parse download result:", e, "Output was:", text); }
                    }
                    downloadOnlyProcess.currentSlug = "";
                }
            }
        }

        FileDialog {
            id: saveDialog

            title: qsTr("Select save location")
            filterLabel: qsTr("Navigate to a folder and select any file — the wallpaper will be saved to that folder")
            filters: ["*"]
            onAccepted: path => {
                const dir = path.slice(0, path.lastIndexOf("/"));
                root._doDownloadOnly(root._pendingDownloadSlug, dir);
            }
        }

        Process {
            id: directDownloadProcess

            property string currentSlug: ""
            property string targetDir: ""
            property string targetFile: ""
            property bool isSet: false

            onExited: (exitCode) => {
                if (exitCode === 0) {
                    if (directDownloadProcess.isSet)
                        Wallpapers.setWallpaper(directDownloadProcess.targetFile);
                    else
                        Toaster.toast(qsTr("Wallpaper saved"), directDownloadProcess.targetFile.split("/").pop(), "download_done");
                } else {
                    console.warn("Direct download failed with code:", exitCode);
                }
                directDownloadProcess.currentSlug = "";
                directDownloadProcess.targetDir = "";
                directDownloadProcess.targetFile = "";
                directDownloadProcess.isSet = false;
            }
        }

        Process {
            id: redditProcess

            stdout: StdioCollector {
                onStreamFinished: {
                    root.loading = false;
                    if (text) {
                        try {
                            const data = JSON.parse(text);
                            const newData = [];
                            const children = data?.data?.children || [];
                            for (const child of children) {
                                const post = child.data;
                                const url = post.url || "";
                                if (!url) continue;
                                const urlLower = url.toLowerCase();
                                if (!urlLower.endsWith(".jpg") && !urlLower.endsWith(".jpeg") && !urlLower.endsWith(".png") && !urlLower.endsWith(".webp"))
                                    continue;
                                const thumb = post.thumbnail;
                                const isThumbUrl = thumb && (thumb.startsWith("http://") || thumb.startsWith("https://"));
                                newData.push({
                                    slug: post.title || post.id,
                                    url_thumb: isThumbUrl ? thumb : url,
                                    url_full: url,
                                    credit: `r/wallpapers · ${post.author}`
                                });
                            }
                            root.wallpapers = newData;
                        } catch (e) { console.error("Failed to parse Reddit response:", e); }
                    }
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    if (text) {
                        root.loading = false;
                        console.warn("Reddit request failed:", text);
                    }
                }
            }
        }
    }

    function fetchWallpapers(reset) {
        if (reset === undefined) reset = true;
        if (reset) {
            root.currentPage = 0;
            root.currentApiPage = 1;
            root.wallpapers = [];
        }
        root.loading = true;

        if (root.currentServer === "bing") {
            root.fetchBingWallpapers();
        } else if (root.currentServer === "nasa") {
            root.fetchNasaWallpapers();
        } else if (root.currentServer === "reddit") {
            root.fetchRedditWallpapers();
        } else if (root.currentServer === "flare") {
            root.fetchFlareWallpapers();
        } else {
            let cmd = "";
            if (root.currentServer === "uhdpaper") {
                cmd = `cd '${root.scriptDir}' && python3 main.py ${root.keyword ? "--keyword '" + root.keyword + "'" : ""} --pages 3 --list --json`;
            } else {
                let cats = root.wallhavenCategories.join(",");
                let purity = root.wallhavenPurity.join(",");
                let sort = root.wallhavenSort;
                let range = root.wallhavenRange;
                let color = root.wallhavenColor;
                cmd = `cd '${root.scriptDir}' && python3 main.py search ${root.keyword ? "'" + root.keyword + "'" : ""} --categories '${cats}' --purity '${purity}' --sort '${sort}' ${sort === "toplist" ? "--range " + range : ""} ${color ? "--colors " + color : ""} --resolution ${root.resolution} --page ${root.currentApiPage} --json`;
            }
            listProcess.exec({command: ["bash", "-c", cmd]});
        }
    }

    function fetchBingWallpapers() {
        Requests.get("https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=8&mkt=en-US", text => {
            root.loading = false;
            try {
                const data = JSON.parse(text);
                const newData = [];
                const imgs = data.images || [];
                for (const img of imgs) {
                    const thumbUrl = "https://www.bing.com" + img.url;
                    const fullUrl = thumbUrl.replace(/1920x1080/, "UHD");
                    newData.push({ slug: img.title || img.copyright || "Bing daily", url_thumb: thumbUrl, url_full: fullUrl });
                }
                root.wallpapers = newData;
            } catch (e) { console.error("Failed to parse Bing response:", e); }
        }, err => {
            root.loading = false;
            console.warn("Bing request failed:", err);
        });
    }

    function fetchNasaWallpapers() {
        Requests.get("https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY&count=10", text => {
            root.loading = false;
            try {
                const data = JSON.parse(text);
                const newData = [];
                for (const item of data) {
                    if (item.media_type !== "image") continue;
                    newData.push({ slug: item.title, url_thumb: item.url, url_full: item.hdurl || item.url });
                }
                root.wallpapers = newData;
            } catch (e) { console.error("Failed to parse NASA response:", e); }
        }, err => {
            root.loading = false;
            console.warn("NASA request failed:", err);
        });
    }

    function fetchRedditWallpapers() {
        redditProcess.command = ["curl", "-s",
            "-H", "User-Agent: caelestia-niri-shell/1.0",
            "https://old.reddit.com/r/wallpapers/hot.json?limit=50&raw_json=1"];
        redditProcess.running = true;
    }

    function fetchFlareWallpapers() {
        const keyword = root.keyword;
        const page = root.currentApiPage;
        const res = root.resolution;
        let cmd = `cd '${root.scriptBaseDir}/wallpaperflare' && python3 main.py --list --json --page ${page}`;
        if (keyword) cmd += ` --keyword '${keyword}'`;
        if (res) cmd += ` --resolution ${res}`;
        flareProcess.exec({command: ["bash", "-c", cmd]});
    }

    function fetchCategories() {
        if (root.currentServer !== "uhdpaper") return;
        categoryProcess.command = ["bash", "-c", `cd '${root.scriptDir}' && python3 main.py --categories --json`];
        categoryProcess.running = true;
    }

    function downloadAndSet(slug) {
        if (root.currentServer === "bing" || root.currentServer === "nasa" || root.currentServer === "reddit") {
            directDownloadProcess.currentSlug = slug;
            directDownloadProcess.isSet = true;
            directDownloadUrl();
        } else {
            downloadProcess.currentSlug = slug;
            let cmd = "";
            if (root.currentServer === "uhdpaper") {
                cmd = `cd '${root.scriptDir}' && python3 main.py --slug '${slug}' --res ${root.resolution} --output ${Paths.wallsdir} --json`;
            } else if (root.currentServer === "flare") {
                cmd = `cd '${root.scriptBaseDir}/wallpaperflare' && python3 main.py --slug '${slug}' --output ${Paths.wallsdir} --json`;
            } else {
                cmd = `cd '${root.scriptDir}' && python3 main.py download '${slug}' --dir ${Paths.wallsdir} --json`;
            }
            downloadProcess.command = ["bash", "-c", cmd];
            downloadProcess.running = true;
        }
    }

    function downloadOnly(slug) {
        root._pendingDownloadSlug = slug;
        if (root.currentServer === "bing" || root.currentServer === "nasa" || root.currentServer === "reddit") {
            directDownloadProcess.currentSlug = slug;
            directDownloadProcess.isSet = false;
            directDownloadProcess.targetDir = Paths.wallsdir;
            directDownloadUrl();
        } else {
            saveDialog.open();
        }
    }

    function _doDownloadOnly(slug, dir) {
        if (root.currentServer === "bing" || root.currentServer === "nasa" || root.currentServer === "reddit") {
            directDownloadProcess.currentSlug = slug;
            directDownloadProcess.isSet = false;
            directDownloadProcess.targetDir = dir;
            directDownloadUrl();
        } else {
            downloadOnlyProcess.currentSlug = slug;
            let cmd = "";
            if (root.currentServer === "uhdpaper") {
                cmd = `cd '${root.scriptDir}' && python3 main.py --slug '${slug}' --res ${root.resolution} --output '${dir}' --json`;
            } else if (root.currentServer === "flare") {
                cmd = `cd '${root.scriptBaseDir}/wallpaperflare' && python3 main.py --slug '${slug}' --output '${dir}' --json`;
            } else {
                cmd = `cd '${root.scriptDir}' && python3 main.py download '${slug}' --dir '${dir}' --json`;
            }
            downloadOnlyProcess.command = ["bash", "-c", cmd];
            downloadOnlyProcess.running = true;
        }
    }

    function directDownloadUrl() {
        const slug = directDownloadProcess.currentSlug;
        const wp = root.wallpapers.find(w => w && w.slug === slug);
        if (!wp || !wp.url_full) {
            console.warn("No URL found for wallpaper:", slug);
            return;
        }
        const ext = wp.url_full.endsWith(".png") ? ".png" : ".jpg";
        const filename = slug.replace(/[/:*?"<>|]/g, "_").slice(0, 80) + ext;
        directDownloadProcess.targetFile = (directDownloadProcess.targetDir || Paths.wallsdir) + "/" + filename;
        directDownloadProcess.command = ["curl", "-L", "-o", directDownloadProcess.targetFile, wp.url_full];
        directDownloadProcess.running = true;
    }

    function saveApiKey(key) {
        root.isClearingApiKey = false;
        configProcess.command = ["bash", "-c", `cd '${root.scriptDir}' && python3 main.py config set api_key ${key}`];
        configProcess.running = true;
    }

    function clearApiKey() {
        root.isClearingApiKey = true;
        configProcess.command = ["bash", "-c", `cd '${root.scriptDir}' && python3 main.py config set api_key ""`];
        configProcess.running = true;
    }

    function checkApiKey() {
        checkApiKeyProcess.command = ["bash", "-c", `cd '${root.scriptBaseDir}/wallhaven' && python3 main.py config show`];
        checkApiKeyProcess.running = true;
    }

    Component.onCompleted: {
        fetchCategories();
        fetchWallpapers();
        checkApiKey();
    }
}
