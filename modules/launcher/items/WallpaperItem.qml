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
    required property PersistentProperties visibilities

    readonly property bool isVideo: Wallpapers.isPathVideo(modelData.path)

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: image.width + Config.appearance.padding.large * 2
    implicitHeight: image.height + label.height + Config.appearance.spacing.small / 2 + Config.appearance.padding.largeIncreased + Config.appearance.padding.medium

    StateLayer {
        radius: Config.appearance.rounding.large

        onClicked: {
            Wallpapers.setWallpaper(root.modelData.path);
            root.visibilities.launcher = false;
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
        y: Config.appearance.padding.largeIncreased
        color: Colours.tPalette.m3surfaceContainer
        radius: Config.appearance.rounding.large

        implicitWidth: TokenConfig.sizes.launcher.wallpaperWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            text: root.isVideo ? "movie" : "image"
            color: Colours.tPalette.m3outline
            fontStyle: Tokens.font.icon.size(Config.appearance.font.headline.large.size * 2).weight(600).build()
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
            fontStyle: Tokens.font.icon.size(Config.appearance.font.headline.large.size * 2).build()
            visible: root.isVideo
        }
    }

    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Config.appearance.spacing.small / 2
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Config.appearance.padding.medium * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: root.modelData.relativePath
        font.pointSize: Config.appearance.font.body.medium.size
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {}
    }
}
