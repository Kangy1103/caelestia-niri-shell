pragma ComponentBehavior: Bound

import qs.components
import qs.components.filedialog
import Caelestia.Config
import qs.utils
import qs.services
import Quickshell
import QtQuick
import Caelestia

Item {
    id: root

    required property PersistentProperties visibilities
    readonly property PersistentProperties state: PersistentProperties {
        property int currentTab

        readonly property FileDialog facePicker: FileDialog {
            title: qsTr("Select a profile picture")
            filterLabel: qsTr("Image files")
            filters: Images.validImageExtensions
            onAccepted: path => {
                if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                    Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
                else
                    Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
            }
        }
    }

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth

    property real targetHeight: 0

    onImplicitHeightChanged: {
        if (implicitHeight > 0)
            targetHeight = implicitHeight;
    }

    states: [
        State {
            name: "open"
            when: root.visibilities.dashboard && Config.dashboard.enabled
            PropertyChanges {
                target: root
                implicitHeight: content.implicitHeight
            }
        }
    ]

    transitions: [
        Transition {
            from: ""
            to: "open"

            Anim {
                target: root
                property: "implicitHeight"
                duration: Config.appearance.anim.durations.large
                easing.bezierCurve: TokenConfig.appearance.curves.emphasizedDecel
            }
        },
        Transition {
            from: "open"
            to: ""

            Anim {
                target: root
                property: "implicitHeight"
                duration: Config.appearance.anim.durations.normal
                easing.bezierCurve: TokenConfig.appearance.curves.emphasizedAccel
            }
        }
    ]

    Item {
        id: contentWrapper

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: content.implicitWidth
        height: root.height
        clip: true
        opacity: root.targetHeight > 0 ? Math.min(1, root.height / (root.targetHeight * 0.6)) : 0

        Loader {
            id: content

            anchors.fill: parent
            active: (root.visibilities.dashboard && Config.dashboard.enabled) || root.height > 0

            sourceComponent: Content {
                visibilities: root.visibilities
                state: root.state
            }
        }
    }
}
