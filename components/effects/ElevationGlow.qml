import qs.services
import CNS.Config
import QtQuick
import QtQuick.Effects

RectangularShadow {
    property int level
    property real dp: [0, 1, 3, 6, 8, 12][level]

    color: Qt.alpha(Colours.palette.m3onBackground, 0.2)
    blur: (dp * 5) ** 0.7
    spread: -dp * 0.3 + (dp * 0.1) ** 2
    // offset.y: dp / 2
    radius: Config.appearance.rounding.small

    Behavior on dp {
        NumberAnimation {
            duration: Tokens.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing: Tokens.anim.standard
        }
    }
}
