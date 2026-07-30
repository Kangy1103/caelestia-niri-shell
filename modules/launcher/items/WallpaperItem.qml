import qs.components
import qs.components.effects
import qs.components.images
import qs.services
import CNS.Config
import CNS.Models
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property FileSystemEntry modelData
    readonly property ScreenState screenState: ShellState.forScreen(screen)

    readonly property bool isVideo: Wallpapers.isPathVideo(modelData.path)

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: image.width + Tokens.padding.large * 2
    implicitHeight: image.height + label.height + Tokens.spacing.small / 2 + Tokens.padding.largeIncreased + Tokens.padding.medium

    StateLayer {
        radius: Tokens.rounding.large

        onClicked: {
            Wallpapers.setWallpaper(root.modelData.path);
            root.screenState.launcher = false;
        }
    }

    Elevation {
        anchors.fill: image
        radius: image.radius
        opacity: root.PathView.isCurrentItem ? 1 : 0
        level: 4

        Behavior on opacity {
            Anim {}
        }
    }

    StyledClippingRect {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.largeIncreased
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large

        implicitWidth: TokenConfig.sizes.launcher.wallpaperWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            text: root.isVideo ? "movie" : "image"
            color: Colours.tPalette.m3outline
            fontStyle: Tokens.font.icon.size(Tokens.font.headline.large.pointSize * 2).weight(600).build()
}

        CachingImage {
            path: Wallpapers.getColorSource(root.modelData.path)
            smooth: !root.PathView.view.moving
            sourceSize.width: image.implicitWidth * 2
            sourceSize.height: image.implicitHeight * 2

            anchors.fill: parent
        }

        // Play symbol overlay for videos
        MaterialIcon {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: fontStyle.pointSize * 0.1 // Adjust for play icon visual centering
            text: "play_arrow"
            color: "white"
            fontStyle: Tokens.font.icon.size(Tokens.font.headline.large.pointSize * 2).build()
            visible: root.isVideo
        }
    }

    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Tokens.spacing.small / 2
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Tokens.padding.medium * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: root.modelData.relativePath
        font.pointSize: Tokens.font.body.medium.pointSize
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {}
    }
}
