import ".."
import "../effects"
import qs.services
import Caelestia.Config
import QtQuick

StyledRect {
    required property int extra

    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.margins: Config.appearance.padding.medium

    color: Colours.palette.m3tertiary
    radius: Config.appearance.rounding.small

    implicitWidth: count.implicitWidth + Config.appearance.padding.medium * 2
    implicitHeight: count.implicitHeight + Config.appearance.padding.extraSmall * 2

    opacity: extra > 0 ? 1 : 0
    scale: extra > 0 ? 1 : 0.5

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        opacity: parent.opacity
        z: -1
        level: 2
    }

    StyledText {
        id: count

        anchors.centerIn: parent
        animate: parent.opacity > 0
        text: qsTr("+%1").arg(parent.extra)
        color: Colours.palette.m3onTertiary
    }

    Behavior on opacity {
        Anim {
            duration: Config.appearance.anim.durations.expressiveFastSpatial
        }
    }

    Behavior on scale {
        Anim {
            duration: Config.appearance.anim.durations.expressiveFastSpatial
            easing.bezierCurve: TokenConfig.appearance.curves.expressiveFastSpatial
        }
    }
}
