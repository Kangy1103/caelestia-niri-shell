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
        when: root.visibilities.keybinds

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
                duration: Tokens.anim.durations.small
                easing: Tokens.anim.emphasizedDecel
            }
        },
        Transition {
            from: "visible"
            to: ""
            Anim {
                target: root
                property: "implicitHeight"
                duration: Tokens.anim.durations.small / 2
                easing: Tokens.anim.emphasizedAccel
            }
        }
    ]

    Content {
        id: content
        wrapper: root
        visibilities: root.visibilities
    }
}
