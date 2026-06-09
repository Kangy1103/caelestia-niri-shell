import Caelestia.Config
import QtQuick

NumberAnimation {
    duration: Config.appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: TokenConfig.appearance.curves.standard
}
