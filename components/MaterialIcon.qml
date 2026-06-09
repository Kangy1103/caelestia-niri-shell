import qs.services
import Caelestia.Config

StyledText {
    property real fill
    property int grade: Colours.light ? 0 : -25

    font.family: Config.appearance.font.icon.family
    font.pointSize: Config.appearance.font.body.large.size
    font.variableAxes: ({
            FILL: fill.toFixed(1),
            GRAD: grade,
            opsz: fontInfo.pixelSize,
            wght: fontInfo.weight
        })
}
