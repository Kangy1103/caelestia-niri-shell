import Caelestia.Config
import qs.services
import QtQuick

ColorAnimation {
    duration: Colours.transitioning ? 150 : Config.appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: TokenConfig.appearance.curves.standard
}
