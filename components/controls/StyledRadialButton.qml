import qs.services
import Caelestia.Config
import QtQuick
import ".."

StyledRect {
    id: root
    property color basecolor: Colours.palette.m3secondaryContainer
    color: disabled ? Colours.palette.m3surfaceContainerLow : basecolor
    property color onColor: Colours.palette.m3onSurface
    property alias disabled: stateLayer.disabled
    property alias icon: icon.text

    property real implicitSize: Config.appearance.font.body.medium.size

    function onClicked(): void {
    }

    radius: Config.appearance.rounding.large
    implicitWidth: root.implicitSize
    implicitHeight: root.implicitSize

    MaterialIcon {
        id: icon
        color: parent.onColor
        font.pointSize: Config.appearance.font.label.large.size
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        opacity: icon.text && stateLayer.containsMouse ? 1 : 0
        Behavior on opacity {
            Anim {}
        }
    }

    StateLayer {
        id: stateLayer
        color: parent.onColor
        onClicked: {
            parent.onClicked();
        }
    }
}
