import qs.components
import CNS.Config
import Quickshell
import QtQuick

Item {
    id: root

    required property ScreenState screenState

    visible: height > 0
    implicitHeight: 0
    implicitWidth: contentLoader.item ? contentLoader.item.implicitWidth : 0

    states: State {
        name: "visible"
        when: root.screenState.keybinds

        PropertyChanges {
            root.implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0
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

    Loader {
        id: contentLoader
        active: root.screenState.keybinds || root.visible
        sourceComponent: Content {
            wrapper: root
        }
    }
}
