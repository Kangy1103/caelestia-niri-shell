pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Caelestia.Config
import qs.modules.nexus
import Quickshell
import Quickshell.Wayland
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property real offsetScale

    readonly property real nonAnimWidth: isDetached || hasCurrent ? children.find(c => c.shouldBeActive)?.implicitWidth ?? content.implicitWidth : 0
    readonly property real nonAnimHeight: children.find(c => c.shouldBeActive)?.implicitHeight ?? content.implicitHeight

    readonly property alias popoutState: popoutState
    property alias currentName: popoutState.currentName
    property alias hasCurrent: popoutState.hasCurrent
    property real currentCenter

    property string detachedMode
    property string queuedMode
    readonly property bool isDetached: detachedMode.length > 0

    readonly property QtObject dummy: QtObject {}
    property int animLength: dummy.Tokens.anim.durations.expressiveDefaultSpatial
    property var animCurve: dummy.Tokens.anim.expressiveDefaultSpatial

    PopoutState {
        id: popoutState

        onDetachRequested: mode => root.detach(mode)
    }

    function setAnims(detach: bool): void {
        const type = `expressive${detach ? "Slow" : "Default"}Spatial`;
        animLength = dummy.Tokens.anim.durations[type];
        animCurve = dummy.Tokens.anim[type];
    }

    function detach(mode: string): void {
        setAnims(true);
        if (mode === "winfo") {
            detachedMode = mode;
        } else {
            queuedMode = mode;
            detachedMode = "any";
        }
        setAnims(false);
        focus = true;
    }

    function close(): void {
        hasCurrent = false;
        detachedMode = "";
    }

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    focus: hasCurrent
    Keys.onEscapePressed: {
        // Forward escape to password popout if active, otherwise close
        if (currentName === "wirelesspassword" && content.item) {
            const passwordPopout = content.item.children.find(c => c.name === "wirelesspassword");
            if (passwordPopout && passwordPopout.item) {
                passwordPopout.item.closeDialog();
                return;
            }
        }
        close();
    }

    Keys.onPressed: event => {
        // Don't intercept keys when password popout is active - let it handle them
        if (currentName === "wirelesspassword") {
            event.accepted = false;
        }
    }

    // TODO: Implement focus grab for Niri when available

    Binding {
        when: root.isDetached || (root.hasCurrent && root.currentName === "wirelesspassword")

        target: QsWindow.window
        property: "WlrLayershell.keyboardFocus"
        value: WlrKeyboardFocus.OnDemand
    }

    Comp {
        id: content

        shouldBeActive: root.hasCurrent && !root.detachedMode
        asynchronous: true
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        sourceComponent: Content {
            wrapper: root
        }
    }

    Comp {
        shouldBeActive: root.detachedMode === "any"
        asynchronous: true
        anchors.centerIn: parent

        sourceComponent: Nexus {
            nState.screen: root.screen
            nState.isWindow: false
            onClose: root.close()
        }
    }

    property real animX: x
    property real animY: y

    Behavior on animX {
        Anim {
            duration: root.animLength
            easing: root.animCurve
        }
    }

    Behavior on animY {
        enabled: root.implicitWidth > 0

        Anim {
            duration: root.animLength
            easing: root.animCurve
        }
    }

    transform: Translate {
        x: root.animX - root.x
        y: root.animY - root.y
    }

    Behavior on implicitWidth {
        Anim {
            duration: root.animLength
            easing: root.animCurve
        }
    }

    Behavior on implicitHeight {
        enabled: root.offsetScale < 1

        Anim {
            duration: root.animLength
            easing: root.animCurve
        }
    }

    component Comp: Loader {
        id: comp

        property bool shouldBeActive

        asynchronous: true
        active: false
        opacity: 0

        states: State {
            name: "active"
            when: comp.shouldBeActive

            PropertyChanges {
                comp.opacity: 1
                comp.active: true
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        property: "active"
                    }
                    Anim {
                        type: Anim.DefaultEffects
                        property: "opacity"
                    }
                }
            },
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
                        type: Anim.DefaultEffects
                        property: "opacity"
                    }
                    PropertyAction {
                        property: "active"
                    }
                }
            }
        ]
    }
}
