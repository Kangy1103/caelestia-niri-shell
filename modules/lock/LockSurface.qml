// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260610

pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Caelestia.Config
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    readonly property alias unlocking: unlockAnim.running

    readonly property real panelScale: Math.min(1, (root.screen?.height ?? 1080) / 1080)
    readonly property int panelWidth: Math.round(420 * panelScale)
    readonly property int panelHeight: Math.round(600 * panelScale)
    readonly property int panelRadius: Config.appearance.rounding.large * 1.5

    color: "transparent"
    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    Connections {
        target: root.lock

        function onUnlock(): void {
            unlockAnim.start();
        }
    }

    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            Anim {
                target: lockContent
                properties: "implicitWidth,implicitHeight"
                to: lockContent.iconSize
                type: Anim.DefaultSpatial
            }
            Anim {
                target: lockBg
                property: "radius"
                to: lockContent.iconSize / 4 * Tokens.rounding.scale
                type: Anim.DefaultSpatial
            }
            Anim {
                target: centerPanel
                property: "scale"
                to: 0
                type: Anim.DefaultSpatial
            }
            Anim {
                target: centerPanel
                property: "opacity"
                to: 0
                type: Anim.StandardSmall
            }
            Anim {
                target: lockIcon
                property: "opacity"
                to: 1
                type: Anim.StandardLarge
            }
            Anim {
                target: background
                property: "opacity"
                to: 0
                type: Anim.StandardLarge
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: Tokens.anim.durations.small
                }
                Anim {
                    target: lockContent
                    property: "opacity"
                    to: 0
                }
            }
        }
        PropertyAction {
            target: root.lock
            property: "locked"
            value: false
        }
    }

    ParallelAnimation {
        id: initAnim

        running: true

        Anim {
            target: background
            property: "opacity"
            to: 1
            type: Anim.StandardLarge
        }
        Anim {
            target: wallpaperFallback
            property: "opacity"
            to: 0
            type: Anim.StandardLarge
        }
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: lockContent
                    property: "scale"
                    to: 1
                    type: Anim.FastSpatial
                }
                Anim {
                    target: lockContent
                    property: "rotation"
                    to: 360
                    type: Anim.FastSpatial
                }
            }
            ParallelAnimation {
                Anim {
                    target: lockIcon
                    property: "rotation"
                    to: 360
                    easing.bezierCurve: TokenConfig.appearance.curves.standardDecel
                }
                Anim {
                    target: lockIcon
                    property: "opacity"
                    to: 0
                }
                Anim {
                    target: centerPanel
                    property: "opacity"
                    to: 1
                }
                Anim {
                    target: centerPanel
                    property: "scale"
                    to: 1
                    type: Anim.DefaultSpatial
                }
                Anim {
                    target: lockBg
                    property: "radius"
                    to: root.panelRadius
                    type: Anim.DefaultSpatial
                }
                Anim {
                    target: lockContent
                    property: "implicitWidth"
                    to: root.panelWidth
                    type: Anim.DefaultSpatial
                }
                Anim {
                    target: lockContent
                    property: "implicitHeight"
                    to: root.panelHeight
                    type: Anim.DefaultSpatial
                }
            }
        }
    }

    Rectangle {
        id: solidFallback
        anchors.fill: parent
        color: Colours.palette.m3surface
        z: 0
    }

    Image {
        id: wallpaperFallback
        anchors.fill: parent
        source: {
            const path = Wallpapers.current || Config.paths.wallpaper || "";
            if (!path) return "";
            const source = Wallpapers.getColorSource(path);
            return source.startsWith("/") ? "file://" + source : source;
        }
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.screen.width
        sourceSize.height: root.screen.height
        opacity: 1
        z: 1

        visible: status === Image.Ready || status === Image.Loading

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            blurMultiplier: 1
        }

        onStatusChanged: {
            if (status === Image.Error) { }
        }
    }

    ScreencopyView {
        id: background

        anchors.fill: parent
        captureSource: root.screen
        opacity: 0
        z: 2

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            blurMultiplier: 1
        }
    }

    Rectangle {
        id: dimScrim
        anchors.fill: parent
        z: 3
        color: Qt.alpha("#000000", 0.2)
    }

    Item {
        id: extrasLayer
        anchors.fill: parent
        z: 4
        visible: Config.lock.showExtras
        opacity: 0

        ParallelAnimation {
            id: extrasShowAnim
            running: false

            Anim {
                target: extrasLayer
                property: "opacity"
                to: 1
                type: Anim.Standard
            }
            Anim {
                target: leftPanel
                property: "x"
                from: Tokens.spacing.extraExtraLarge
                to: 0
                type: Anim.DefaultSpatial
            }
            Anim {
                target: rightPanel
                property: "x"
                from: -Tokens.spacing.extraExtraLarge
                to: 0
                type: Anim.DefaultSpatial
            }
        }

        Connections {
            target: initAnim
            function onFinished(): void {
                extrasShowAnim.start();
            }
        }

        StyledRect {
            id: leftPanel

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.horizontalCenter
            anchors.rightMargin: root.panelWidth / 2 + Tokens.spacing.extraExtraLarge * 2

            width: Math.min(Math.round(300 * root.panelScale), parent.width / 4)
            height: root.panelHeight

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer
            opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 16
                shadowVerticalOffset: 4
                shadowHorizontalOffset: 0
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.4)
            }

            Content {
                anchors.fill: parent
                anchors.margins: 0
                lock: root
                showLeft: true
                showRight: false
            }
        }

        StyledRect {
            id: rightPanel

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.horizontalCenter
            anchors.leftMargin: root.panelWidth / 2 + Tokens.spacing.extraExtraLarge * 2

            width: Math.min(Math.round(300 * root.panelScale), parent.width / 4)
            height: root.panelHeight

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer
            opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 16
                shadowVerticalOffset: 4
                shadowHorizontalOffset: 0
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.4)
            }

            Content {
                anchors.fill: parent
                anchors.margins: 0
                lock: root
                showLeft: false
                showRight: true
            }
        }
    }

    Item {
        id: lockContent

        readonly property int iconSize: lockIcon.implicitHeight + Tokens.padding.largeIncreased * 4

        anchors.centerIn: parent
        implicitWidth: iconSize
        implicitHeight: iconSize
        z: 5

        rotation: 180
        scale: 0

        StyledRect {
            id: lockBg

            anchors.fill: parent
            color: Colours.palette.m3surfaceContainer
            radius: lockContent.iconSize / 4 * Tokens.rounding.scale
            opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 36
                shadowVerticalOffset: 8
                shadowHorizontalOffset: 0
                shadowBlur: 0.7
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.45)
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: lockBg.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.5)
            z: 1
        }

        MaterialIcon {
            id: lockIcon

            anchors.centerIn: parent
            text: "lock"
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.size(Config.appearance.font.headline.large.size * 4).weight(Font.Bold).build()
            rotation: 180
        }

        Center {
            id: centerPanel

            anchors.fill: parent
            anchors.margins: Tokens.padding.largeIncreased

            lock: root
            opacity: 0
            scale: 0
        }
    }
}
