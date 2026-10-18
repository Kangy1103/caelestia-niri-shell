pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.components.filedialog
import qs.services
import CNS.Config
import qs.utils
import CNS
import QtQuick
import QtQuick.Effects
import QtMultimedia

Item {
    id: root

    property string source: Wallpapers.current
    property Item current: one

    anchors.fill: parent

    Connections {
        target: GameMode
        function onEnabledChanged(): void {
            if (GameMode.enabled) {
                if (root.current && root.current.item && root.current.item.isVideo) {
                    player.pause();
                }
            } else {
                if (root.current && root.current.item && root.current.item.isVideo) {
                    player.play();
                }
            }
        }
    }

    Component.onCompleted: {
    }

    // Delayed initial load to ensure CachingImageManager is ready
    Timer {
        id: initialLoadTimer
        interval: 200
        running: root.source !== ""
        onTriggered: {
            if (root.source && one.path === "" && two.path === "") {
                one.path = root.source;
            }
        }
    }

    onSourceChanged: {
        if (!source)
            current = null;
        else if (current === one)
            two.update();
        else
            one.update();
    }

    Loader {
        anchors.fill: parent

        active: !root.source
        asynchronous: true

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.extraExtraLarge

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.size(Tokens.font.headline.large.pointSize * 5).build()
}

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Tokens.font.headline.large.pointSize * 2
                        font.bold: true
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.largeIncreased * 2
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.extraSmall * 2

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: qsTr("Select a wallpaper")
                            filterLabel: qsTr("Image or Video files")
                            filters: Images.validImageExtensions.concat(["mp4", "mkv", "webm", "mov", "avi", "m4v"])
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary

                            onClicked: {
                                dialog.open();
                            }
                        }

                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent

                            text: qsTr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font.pointSize: Tokens.font.title.medium.pointSize
                        }
                    }
                }
            }
        }
    }

    Img {
        id: one
    }

    Img {
        id: two
    }

    component Img: Item {
        id: item

        property string path: ""

        function update(): void {
            if (path === root.source) {
                root.current = item;
            } else {
                path = root.source;
            }
        }

        anchors.fill: parent
        opacity: 0
        // CNS: while the wallpaper picker has a chosen card in the middle of
        // this screen it draws its own crossfade, so the wallpaper underneath
        // must appear straight away rather than animating behind the card.
        scale: Wallpapers.showPreview || Wallpapers.pickerCovers === screen.name ? 1 : 0.8

        readonly property bool isVideo: Wallpapers.isPathVideo(path)

        Connections {
            target: Wallpapers
            function onFrameReady(p): void {
                if (p === item.path && item.isVideo) {
                    const old = frameFallback.path;
                    frameFallback.path = "";
                    frameFallback.path = old;
                }
            }
        }

        onPathChanged: {
            const video = Wallpapers.isPathVideo(path);
            if (video && path !== "") {
                if (root.current === item) {
                    player.play();
                } else {
                    root.current = item;
                }
            }
        }

        // Show the extracted frame for videos as a still image fallback
        CachingImage {
            id: frameFallback
            anchors.fill: parent
            path: {
                if (!item.isVideo || item.path === "") return "";
                const src = Wallpapers.getColorSource(item.path);
                return CUtils.exists(src) ? src : "";
            }

            // RAM Optimization: Ensure we don't load more than screen resolution
            sourceSize.width: root.width
            sourceSize.height: root.height

            visible: item.isVideo
            opacity: 1
            z: 1
        }

        // A scaled, blurred copy of the wallpaper filling the whole screen. Only
        // shown in "blur" fit mode, behind the wallpaper drawn whole, so a
        // wallpaper whose aspect doesn't match the screen fills the gaps
        // instead of being letterboxed black.
        CachingImage {
            id: blurFill

            anchors.fill: parent
            path: !item.isVideo && Wallpapers.wallpaperFit === "blur" ? item.path : ""
            fillMode: Image.PreserveAspectCrop
            visible: opacity > 0.01
            opacity: status === Image.Ready ? 1 : 0
            z: 1

            sourceSize.width: root.width
            sourceSize.height: root.height

            layer.enabled: opacity > 0.01
            // CNS's own blur idiom (see LockSurface): MultiEffect with a
            // blurMax ceiling rather than a fixed radius.
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1
                blurMax: 64
            }

            Behavior on opacity {
                NumberAnimation { duration: 220 }
            }
        }

        CachingImage {
            id: img
            anchors.fill: parent
            path: !item.isVideo ? item.path : ""
            // "crop" fills the screen and loses the overflow; "fit" and
            // "blur" show the wallpaper whole, so nothing is cut off.
            fillMode: Wallpapers.wallpaperFit === "crop" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
            visible: !item.isVideo
            opacity: status === Image.Ready ? 1 : 0
            z: 2
            onStatusChanged: {
                if (status === Image.Ready && !item.isVideo) {
                    root.current = item;
                    // CNS: tell the wallpaper picker this wallpaper is really
                    // on screen now, so it can close instead of guessing.
                    Wallpapers.drawn = item.path;
                }
            }
        }

        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            visible: item.isVideo
            fillMode: Wallpapers.wallpaperFit === "crop" ? VideoOutput.PreserveAspectCrop : VideoOutput.PreserveAspectFit
            z: 3
        }

        MediaPlayer {
            id: player
            videoOutput: videoOutput
            loops: MediaPlayer.Infinite

            onErrorOccurred: (error, errorString) => console.error("MediaPlayer Error:", errorString)
            onMediaStatusChanged: {
                if (mediaStatus === MediaPlayer.LoadedMedia && root.current === item && item.isVideo) {
                    player.play();
                    // CNS: a video's frames are up once its media is loaded; the
                    // picker waits on drawn for this path the same way.
                    Wallpapers.drawn = item.path;
                }
            }

            audioOutput: AudioOutput {
                muted: true
            }
        }

        states: [
            State {
                name: "visible"
                when: root.current === item

                PropertyChanges {
                    item.opacity: 1
                    item.scale: 1
                    player.source: item.isVideo ? (item.path.startsWith("/") ? "file://" + item.path : item.path) : ""
                }

                StateChangeScript {
                    script: {
                        if (item.isVideo) {
                            Qt.callLater(() => player.play());
                        }
                    }
                }
            },
            State {
                name: "hidden"
                when: root.current !== item

                PropertyChanges {
                    item.opacity: 0
                    item.scale: Wallpapers.showPreview || Wallpapers.pickerCovers === screen.name ? 1 : 0.8
                }

                StateChangeScript {
                    script: {
                        if (item.isVideo) {
                            player.stop();
                            player.source = "";
                        }
                    }
                }
            }
        ]

        transitions: Transition {
            Anim {
                target: item
                properties: "opacity,scale"
            }
        }
    }
}
