pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.components.filedialog
import qs.services
import Caelestia.Config
import qs.utils
import Caelestia
import QtQuick
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
                spacing: Config.appearance.spacing.extraExtraLarge

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.size(Config.appearance.font.headline.large.size * 5).build()
}

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Config.appearance.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Config.appearance.font.headline.large.size * 2
                        font.bold: true
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Config.appearance.padding.largeIncreased * 2
                        implicitHeight: selectWallText.implicitHeight + Config.appearance.padding.extraSmall * 2

                        radius: Config.appearance.rounding.full
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
                            font.pointSize: Config.appearance.font.title.medium.size
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
        scale: Wallpapers.showPreview ? 1 : 0.8

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

        CachingImage {
            id: img
            anchors.fill: parent
            path: !item.isVideo ? item.path : ""
            visible: !item.isVideo
            opacity: status === Image.Ready ? 1 : 0
            z: 2
            onStatusChanged: {
                if (status === Image.Ready && !item.isVideo) {
                    root.current = item;
                }
            }
        }

        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            visible: item.isVideo
            fillMode: VideoOutput.PreserveAspectCrop
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
                    item.scale: Wallpapers.showPreview ? 1 : 0.8
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
