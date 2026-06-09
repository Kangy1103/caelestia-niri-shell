import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

IconButton {
    id: root

    radius: stateLayer.pressed ? Appearance.rounding.small / 2 : internalChecked ? Appearance.rounding.small : Appearance.rounding.normal
    inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    toggle: true
    radiusAnim.duration: Appearance.anim.durations.expressiveFastSpatial
    radiusAnim.easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial

    Behavior on Layout.preferredWidth {
        Anim {
            duration: Appearance.anim.durations.expressiveFastSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
        }
    }
}
