import qs.components
import Caelestia.Config
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities

    visible: width > 0
    implicitWidth: 0
    implicitHeight: content.implicitHeight

    states: State {
        name: "visible"
        when: root.visibilities.session && Config.session.enabled

        PropertyChanges {
            root.implicitWidth: content.implicitWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
                duration: Config.appearance.anim.durations.normal
                easing.bezierCurve: TokenConfig.appearance.curves.emphasizedDecel
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                duration: Config.appearance.anim.durations.small
                easing.bezierCurve: root.visibilities.osd ? TokenConfig.appearance.curves.emphasizedDecel : TokenConfig.appearance.curves.emphasizedAccel
            }
        }
    ]

    Content {
        id: content

        visibilities: root.visibilities
    }
}
