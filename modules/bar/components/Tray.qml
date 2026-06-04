import qs.components
import qs.services
import qs.config
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick

StyledRect {
    id: root

    readonly property alias items: items

    clip: true
    visible: width > 0 && height > 0 // To avoid warnings about being visible with no size

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: layout.implicitHeight + (Config.bar.tray.background ? Appearance.padding.md : Appearance.padding.xs) * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.tray.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Appearance.rounding.full

    Column {
        id: layout

        anchors.centerIn: parent
        spacing: Appearance.spacing.sm

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: SystemTray.items
            TrayItem {}
        }
    }

    Behavior on implicitWidth {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    Behavior on implicitHeight {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    // Refresh tray items after startup — recovers icons that don't
    // automatically re-register with the StatusNotifierWatcher on reload
    Timer {
        interval: 3000
        running: true
        onTriggered: refreshTrayProcess.running = true
    }

    Process {
        id: refreshTrayProcess
        command: ["bash", "/home/kangy/.config/quickshell/caelestia-niri-shell/scripts/refresh-tray.sh"]
    }
}
