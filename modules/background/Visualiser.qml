pragma ComponentBehavior: Bound

import qs.components
import qs.services
import CNS.Config
import CNS.Internal
import CNS.Services
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property ShellScreen screen
    required property Item wallpaper

    readonly property bool shouldBeActive: Config.background.visualiser.enabled && (!Config.background.visualiser.autoHide || Niri.getActiveWorkspaceWindows().length === 0) && !GameMode.enabled

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

        VisualiserBars {
            id: bars

            anchors.fill: parent
            anchors.margins: Config.border.thickness
            anchors.leftMargin: Visibilities.bars.get(root.screen).exclusiveZone + Config.appearance.spacing.small * Config.background.visualiser.spacing

            values: Cava.values
            primaryColor: Qt.alpha(Colours.palette.m3primary, 0.7)
            secondaryColor: Qt.alpha(Colours.palette.m3inversePrimary, 0.7)
            rounding: Config.appearance.rounding.small * Config.background.visualiser.rounding
            spacing: Config.appearance.spacing.small * Config.background.visualiser.spacing
            animationDuration: Tokens.anim.durations.small

            Timer {
                running: true
                interval: 16
                repeat: true
                onTriggered: parent.advance(0.016)
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
}
