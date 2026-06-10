// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.2.0-20260610

pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Caelestia.Config
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    readonly property alias unlocking: unlockAnim.running

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    color: "transparent"

    Connections {
        function onUnlock(): void {
            unlockAnim.start();
        }

        target: root.lock
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
                target: content
                property: "scale"
                to: 0
                type: Anim.DefaultSpatial
            }
            Anim {
                target: content
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
                    target: content
                    property: "opacity"
                    to: 1
                }
                Anim {
                    target: content
                    property: "scale"
                    to: 1
                    type: Anim.DefaultSpatial
                }
                Anim {
                    target: lockBg
                    property: "radius"
                    to: Tokens.rounding.extraLarge * 1.5
                }
                Anim {
                    target: lockContent
                    property: "implicitWidth"
                    to: (root.screen?.height ?? 0) * Tokens.sizes.lock.heightMult * Tokens.sizes.lock.ratio
                    type: Anim.DefaultSpatial
                }
                Anim {
                    target: lockContent
                    property: "implicitHeight"
                    to: (root.screen?.height ?? 0) * Tokens.sizes.lock.heightMult
                    type: Anim.DefaultSpatial
                }
            }
        }
    }

    // ── Background layers ──────────────────────────────────────────────────────

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

    // ── Optional flanking side panels ──────────────────────────────────────────

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
            anchors.rightMargin: contentWidth / 2 + Tokens.spacing.extraExtraLarge * 2

            width: Math.min(300, parent.width / 4)
            height: contentHeight

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

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                WeatherInfo {
                    Layout.fillWidth: true
                    rootHeight: parent.height
                }

                Fetch {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    rootHeight: parent.height
                }

                Media {
                    Layout.fillWidth: true
                    lock: root
                }
            }
        }

        StyledRect {
            id: rightPanel

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.horizontalCenter
            anchors.leftMargin: contentWidth / 2 + Tokens.spacing.extraExtraLarge * 2

            width: Math.min(300, parent.width / 4)
            height: contentHeight

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

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                Resources {
                    Layout.fillWidth: true
                }

                NotifDock {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    lock: root
                }
            }
        }
    }

    // ── Main floating panel ────────────────────────────────────────────────────

    readonly property real contentWidth: (root.screen?.height ?? 0) * Tokens.sizes.lock.heightMult * Tokens.sizes.lock.ratio
    readonly property real contentHeight: (root.screen?.height ?? 0) * Tokens.sizes.lock.heightMult

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
            radius: parent.iconSize / 4 * Tokens.rounding.scale
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

        Content {
            id: content

            anchors.centerIn: parent
            width: root.contentWidth - Tokens.padding.extraLargeIncreased
            height: root.contentHeight - Tokens.padding.extraLargeIncreased

            lock: root
            opacity: 0
            scale: 0
        }
    }
}
