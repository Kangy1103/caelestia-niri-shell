import ".."
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

IconButton {
    id: root

    radius: stateLayer.pressed ? Config.appearance.rounding.small / 2 : internalChecked ? Config.appearance.rounding.small : Config.appearance.rounding.large
    inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    toggle: true
    radiusAnim.duration: Config.appearance.anim.durations.expressiveFastSpatial
    radiusAnim.easing.bezierCurve: TokenConfig.appearance.curves.expressiveFastSpatial

    Behavior on Layout.preferredWidth {
        Anim {
            duration: Config.appearance.anim.durations.expressiveFastSpatial
            easing.bezierCurve: TokenConfig.appearance.curves.expressiveFastSpatial
        }
    }
}
