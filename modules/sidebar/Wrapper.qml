pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components

Item {
    id: root

    required property PersistentProperties visibilities
    readonly property Props props: Props {}

    visible: width > 0
    implicitWidth: 0
    implicitHeight: root.parent ? root.parent.height : 0

    states: State {
        name: "visible"
        when: root.visibilities.sidebar

        PropertyChanges {
            root.implicitWidth: TokenConfig.sizes.sidebar.width
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"
            Anim {
                properties: "implicitWidth"
                duration: Config.appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: TokenConfig.appearance.curves.emphasizedDecel
            }
        },
        Transition {
            from: "visible"
            to: ""
            Anim {
                properties: "implicitWidth"
                duration: Config.appearance.anim.durations.small
                easing.type: Easing.BezierSpline
                easing.bezierCurve: TokenConfig.appearance.curves.emphasizedAccel
            }
        }
    ]

    Item {
        id: contentArea

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        anchors.bottomMargin: 0
        anchors.topMargin: 0

        width: root.width - anchors.margins * 2
        clip: true
        opacity: Math.min(1, root.width / (TokenConfig.sizes.sidebar.width * 0.6))

        Loader {
            id: content

            anchors.fill: parent
            active: root.visibilities.sidebar || root.width > 0

            sourceComponent: Content {
                implicitWidth: contentArea.width
                props: root.props
                visibilities: root.visibilities
            }
        }
    }
}
