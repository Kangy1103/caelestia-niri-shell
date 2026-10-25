import qs.components
import CNS.Config
import Quickshell
import QtQuick

Item {
    id: root

    required property ScreenState screenState

    // Keep the panel visible while its state is opening, even before the
    // Loader has supplied an implicit height.
    visible: root.screenState.keybinds || height > 0
    implicitHeight: 0
    implicitWidth: contentLoader.item ? contentLoader.item.implicitWidth : 420
    height: implicitHeight
    width: implicitWidth

    states: State {
        name: "visible"
        when: root.screenState.keybinds

        PropertyChanges {
            root.implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 600
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
        anchors.fill: parent
        active: root.screenState.keybinds || root.visible
        sourceComponent: Content {
            wrapper: root
        }
    }
}
