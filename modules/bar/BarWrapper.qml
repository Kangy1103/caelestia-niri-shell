pragma ComponentBehavior: Bound

import qs.components
import Caelestia.Config
import "popouts" as BarPopouts
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts

    readonly property int padding: Math.max(Config.appearance.padding.small, Config.border.thickness)
    readonly property int contentWidth: TokenConfig.sizes.bar.innerWidth + padding * 2
    readonly property int exclusiveZone: Config.bar.persistent || visibilities.bar ? contentWidth : Config.border.thickness
    readonly property bool shouldBeVisible: Config.bar.persistent || visibilities.bar || isHovered
    property bool isHovered

    function checkPopout(y: real): void {
        content.item?.checkPopout(y);
    }

    function handleWheel(y: real, angleDelta: point): void {
        content.item?.handleWheel(y, angleDelta);
    }

    visible: width > Config.border.thickness
    implicitWidth: Config.border.thickness

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitWidth: root.contentWidth
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
                easing.bezierCurve: TokenConfig.appearance.curves.emphasizedAccel
            }
        }
    ]

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        active: root.shouldBeVisible || root.visible

        sourceComponent: Bar {
            width: root.contentWidth
            screen: root.screen
            visibilities: root.visibilities
            popouts: root.popouts
        }
    }
}
