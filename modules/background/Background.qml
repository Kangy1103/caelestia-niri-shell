pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import CNS.Config
import Quickshell
import Quickshell.Wayland
import QtQuick

Loader {
    active: Config.background.enabled

    sourceComponent: Variants {
        model: Quickshell.screens

        StyledWindow {
            id: win

            required property var modelData

            screen: modelData
            name: "background"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: Config.background.wallpaperEnabled ? WlrLayer.Background : WlrLayer.Bottom
            color: Config.background.wallpaperEnabled ? "black" : "transparent"
            surfaceFormat.opaque: false

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Item {
                id: behindClock

                readonly property bool isFocusedScreen: win.modelData.name === Niri.focusedMonitorName

                anchors.fill: parent

                Loader {
                    id: wallpaperLoader

                    anchors.fill: parent
                    active: Config.background.wallpaperEnabled

                    sourceComponent: Wallpaper {}
                }

                Loader {
                    anchors.fill: parent
                    active: Config.background.visualiser.enabled

                    sourceComponent: Visualiser {
                        anchors.fill: parent
                        screen: win.modelData
                        wallpaper: wallpaperLoader
                    }
                }
            }


        }
    }
}
