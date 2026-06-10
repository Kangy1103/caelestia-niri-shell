import qs.components
import Caelestia.Config
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth

    states: State {
        name: "visible"
        when: root.visibilities.calendar

        PropertyChanges {
            root.implicitHeight: content.implicitHeight
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"
            Anim {
                target: root
                property: "implicitHeight"
                duration: Config.appearance.anim.durations.normal
                easing.bezierCurve: TokenConfig.appearance.curves.emphasizedDecel
            }
        },
        Transition {
            from: "visible"
            to: ""
            Anim {
                target: root
                property: "implicitHeight"
                duration: Config.appearance.anim.durations.small
                easing.bezierCurve: TokenConfig.appearance.curves.emphasizedAccel
            }
        }
    ]

    Content {
        id: content
        visibilities: root.visibilities
    }
}
