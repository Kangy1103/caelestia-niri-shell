pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    required property Item wallpaper
    required property real absX
    required property real absY

    property real scale: Config.background.desktopClock.scale
    readonly property bool bgEnabled: Config.background.desktopClock.background.enabled
    readonly property bool blurEnabled: bgEnabled && Config.background.desktopClock.background.blur && !GameMode.enabled
    readonly property bool invertColors: Config.background.desktopClock.invertColors
    readonly property bool useLightSet: Colours.light ? !invertColors : invertColors
    readonly property color safePrimary: useLightSet ? Colours.palette.m3primaryContainer : Colours.palette.m3primary
    readonly property color safeSecondary: useLightSet ? Colours.palette.m3secondaryContainer : Colours.palette.m3secondary
    readonly property color safeTertiary: useLightSet ? Colours.palette.m3tertiaryContainer : Colours.palette.m3tertiary

    implicitWidth: layout.implicitWidth + (Config.appearance.padding.largeIncreased * 4 * root.scale)
    implicitHeight: layout.implicitHeight + (Config.appearance.padding.largeIncreased * 2 * root.scale)

    Item {
        id: clockContainer

        anchors.fill: parent

        layer.enabled: Config.background.desktopClock.shadow.enabled
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Colours.palette.m3shadow
            shadowOpacity: Config.background.desktopClock.shadow.opacity
            shadowBlur: Config.background.desktopClock.shadow.blur
        }

        Loader {
            anchors.fill: parent
            active: root.blurEnabled

            sourceComponent: MultiEffect {
                source: ShaderEffectSource {
                    sourceItem: root.wallpaper
                    sourceRect: Qt.rect(root.absX, root.absY, root.width, root.height)
                }
                maskSource: backgroundPlate
                maskEnabled: true
                blurEnabled: true
                blur: 1
                blurMax: 64
                autoPaddingEnabled: false
            }
        }

        StyledRect {
            id: backgroundPlate

            visible: root.bgEnabled
            anchors.fill: parent
            radius: Config.appearance.rounding.large * root.scale
            opacity: Config.background.desktopClock.background.opacity
            color: Colours.palette.m3surface

            layer.enabled: root.blurEnabled
        }

        RowLayout {
            id: layout

            anchors.centerIn: parent
            spacing: Config.appearance.spacing.largeIncreased * root.scale

            RowLayout {
                spacing: Config.appearance.spacing.small

                StyledText {
                    text: Time.hourStr
                    font.pointSize: Config.appearance.font.headline.large.size * 3 * root.scale
                    font.weight: Font.Bold
                    color: root.safePrimary
                }

                StyledText {
                    text: ":"
                    font.pointSize: Config.appearance.font.headline.large.size * 3 * root.scale
                    color: root.safeTertiary
                    opacity: 0.8
                    Layout.topMargin: -Config.appearance.padding.largeIncreased * 1.5 * root.scale
                }

                StyledText {
                    text: Time.minuteStr
                    font.pointSize: Config.appearance.font.headline.large.size * 3 * root.scale
                    font.weight: Font.Bold
                    color: root.safeSecondary
                }

                Loader {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Config.appearance.padding.largeIncreased * 1.4 * root.scale

                    active: Config.services.useTwelveHourClock
                    visible: active

                    sourceComponent: StyledText {
                        text: Time.amPmStr
                        font.pointSize: Config.appearance.font.title.medium.size * root.scale
                        color: root.safeSecondary
                    }
                }
            }

            StyledRect {
                Layout.fillHeight: true
                Layout.preferredWidth: 4 * root.scale
                Layout.topMargin: Config.appearance.spacing.largeIncreased * root.scale
                Layout.bottomMargin: Config.appearance.spacing.largeIncreased * root.scale
                radius: Config.appearance.rounding.full
                color: root.safePrimary
                opacity: 0.8
            }

            ColumnLayout {
                spacing: 0

                StyledText {
                    text: Time.format("MMMM").toUpperCase()
                    font.pointSize: Config.appearance.font.title.medium.size * root.scale
                    font.letterSpacing: 4
                    font.weight: Font.Bold
                    color: root.safeSecondary
                }

                StyledText {
                    text: Time.format("dd")
                    font.pointSize: Config.appearance.font.headline.large.size * root.scale
                    font.letterSpacing: 2
                    font.weight: Font.Medium
                    color: root.safePrimary
                }

                StyledText {
                    text: Time.format("dddd")
                    font.pointSize: Config.appearance.font.body.large.size * root.scale
                    font.letterSpacing: 2
                    color: root.safeSecondary
                }
            }
        }
    }

    Behavior on scale {
        Anim {
            duration: Tokens.anim.durations.expressiveDefaultSpatial
            easing: Tokens.anim.expressiveDefaultSpatial
        }
    }

    Behavior on implicitWidth {
        Anim {
            duration: Tokens.anim.durations.small
        }
    }
}
