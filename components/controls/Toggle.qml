import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

IconButton {
    id: root

    isToggle: true
    radius: stateLayer.pressed ? Tokens.rounding.medium / 2 : internalChecked ? Tokens.rounding.medium : Tokens.rounding.large
    inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    radiusAnim.type: Anim.FastSpatial

    Behavior on Layout.preferredWidth {
        Anim {
            type: Anim.FastSpatial
        }
    }
}
