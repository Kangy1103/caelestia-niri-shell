pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Caelestia.Config
import Caelestia.Services
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property ShellScreen screen
    required property Item wallpaper

    readonly property bool onTargetOutput: !Config.background.visualiser.output || Config.background.visualiser.output === screen.name
    readonly property bool shouldBeActive: Config.background.visualiser.enabled && onTargetOutput && (!Config.background.visualiser.autoHide || Niri.getActiveWorkspaceWindows().length === 0) && !GameMode.enabled

    opacity: shouldBeActive ? 1 : 0

    Loader {
        anchors.fill: parent
        active: opacity > 0 && Config.background.visualiser.blur

        sourceComponent: MultiEffect {
            source: root.wallpaper
            maskSource: wrapper
            maskEnabled: true
            blurEnabled: true
            blur: 1
            blurMax: 32
            autoPaddingEnabled: false
        }
    }

    Item {
        id: wrapper

        anchors.fill: parent
        visible: opacity > 0
        clip: true
        layer.enabled: visible

        Item {
            id: content

            anchors.fill: parent
            anchors.margins: Config.border.thickness
            anchors.leftMargin: Visibilities.bars.get(root.screen).exclusiveZone + Config.appearance.spacing.small * Config.background.visualiser.spacing

            Side {
                content: content
            }
            Side {
                content: content
                isRight: true
            }

            Behavior on anchors.leftMargin {
                Anim {}
            }
        }

        ServiceRef {
            service: Cava.provider
        }
    }

    Behavior on opacity {
        Anim {}
    }

    component Side: Repeater {
        id: side

        required property Item content
        property bool isRight

        model: Config.services.visualiserBars

        ClippingRectangle {
            id: bar

            required property int modelData
            property real value: Math.max(0, Math.min(1, Cava.values[side.isRight ? modelData : side.count - modelData - 1]))

            x: modelData * ((side.content.width * 0.4) / Config.services.visualiserBars) + (side.isRight ? side.content.width * 0.6 : 0)
            implicitWidth: (side.content.width * 0.4) / Config.services.visualiserBars - Config.appearance.spacing.small * Config.background.visualiser.spacing

            y: side.content.height - height
            implicitHeight: bar.value * side.content.height * 0.4

            color: "transparent"
            topLeftRadius: Config.appearance.rounding.small * Config.background.visualiser.rounding
            topRightRadius: Config.appearance.rounding.small * Config.background.visualiser.rounding

            Rectangle {
                topLeftRadius: parent.topLeftRadius
                topRightRadius: parent.topRightRadius

                gradient: Gradient {
                    orientation: Gradient.Vertical

                    GradientStop {
                        position: 0
                        color: Qt.alpha(Colours.palette.m3primary, 0.7)

                        Behavior on color {
                            CAnim {}
                        }
                    }
                    GradientStop {
                        position: 1
                        color: Qt.alpha(Colours.palette.m3inversePrimary, 0.7)

                        Behavior on color {
                            CAnim {}
                        }
                    }
                }

                anchors.left: parent.left
                anchors.right: parent.right
                y: parent.height - height
                implicitHeight: side.content.height * 0.4
            }

            Behavior on value {
                Anim {
                    duration: Tokens.anim.durations.small
                }
            }
        }
    }
}
