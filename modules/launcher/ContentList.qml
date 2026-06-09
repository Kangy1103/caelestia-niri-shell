pragma ComponentBehavior: Bound

import "items"
import qs.components
import qs.services
import Caelestia.Config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var wrapper
    required property PersistentProperties visibilities
    required property var panels
    required property TextField search
    required property int padding
    required property int rounding

    readonly property bool showWallpapers: search.text.startsWith(`${Config.launcher.actionPrefix}wallpaper `)
    readonly property Item currentList: showWallpapers ? wallpaperList.item : appList.item
    readonly property string activeMode: showWallpapers ? "wallpapers" : (appList.item?.state ?? "apps")

    readonly property bool showClipPreview: activeMode === "clip" && Boolean(currentList?.currentItem?.modelData)

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    clip: true
    state: showWallpapers ? "wallpapers" : "apps"

    states: [
        State {
            name: "apps"

            PropertyChanges {
                root.implicitWidth: TokenConfig.sizes.launcher.itemWidth + (showClipPreview ? 300 + Config.appearance.spacing.large : 0)
                root.implicitHeight: Math.max(appList.implicitHeight > 0 ? appList.implicitHeight : empty.implicitHeight, showClipPreview ? 400 : 0)
                appList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "wallpapers"

            PropertyChanges {
                root.implicitWidth: Math.max(TokenConfig.sizes.launcher.itemWidth * 1.2, wallpaperList.implicitWidth)
                root.implicitHeight: TokenConfig.sizes.launcher.wallpaperHeight
                wallpaperList.active: true
            }
        }
    ]

    Behavior on state {
        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                from: 1
                to: 0
                duration: Config.appearance.anim.durations.small
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                from: 0
                to: 1
                duration: Config.appearance.anim.durations.small
            }
        }
    }

    Row {
        id: mainRow
        anchors.fill: parent
        spacing: Config.appearance.spacing.large

        Loader {
            id: appList

            active: false
            asynchronous: true

            height: parent.height
            width: TokenConfig.sizes.launcher.itemWidth

            sourceComponent: AppList {
                search: root.search
                visibilities: root.visibilities
            }
        }

        ClipPreview {
            id: clipPreview
            visible: root.showClipPreview
            modelData: root.currentList?.currentItem?.modelData
            list: appList.item
            height: parent.height
            width: 300
        }
    }

    Loader {
        id: wallpaperList

        active: false
        asynchronous: true

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: WallpaperList {
            search: root.search
            visibilities: root.visibilities
            panels: root.panels
            wrapper: root.wrapper
        }
    }

    Row {
        id: empty

        opacity: root.currentList?.count === 0 ? 1 : 0
        scale: root.currentList?.count === 0 ? 1 : 0.5

        spacing: Config.appearance.spacing.large
        padding: Config.appearance.padding.largeIncreased

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialIcon {
            text: root.state === "wallpapers" ? "wallpaper_slideshow" : "manage_search"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.headline.large.size

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: root.state === "wallpapers" ? qsTr("No wallpapers found") : qsTr("No results")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.body.large.size
                font.weight: 500
            }

            StyledText {
                text: root.state === "wallpapers" && Wallpapers.list.length === 0 ? qsTr("Try putting some wallpapers in %1").arg(Paths.shortenHome(Paths.wallsdir)) : qsTr("Try searching for something else")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.body.medium.size
            }
        }

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitWidth {
        enabled: root.visibilities.launcher

        Anim {
            duration: Config.appearance.anim.durations.large
            easing.bezierCurve: TokenConfig.appearance.curves.emphasizedDecel
        }
    }

    Behavior on implicitHeight {
        enabled: root.visibilities.launcher

        Anim {
            duration: Config.appearance.anim.durations.large
            easing.bezierCurve: TokenConfig.appearance.curves.emphasizedDecel
        }
    }
}
