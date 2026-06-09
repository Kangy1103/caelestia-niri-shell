import QtQuick
import Caelestia.Config
import qs.services

StyledText {
    property real fill
    property int grade: Colours.light ? 0 : -25
    property font fontStyle: Tokens.font.icon.small

    font.family: fontStyle.family
    font.pointSize: fontStyle.pointSize
    font.weight: fontStyle.weight
    font.italic: fontStyle.italic
    font.underline: fontStyle.underline
    font.variableAxes: ({
        "FILL": fill.toFixed(1),
        "GRAD": grade,
        "opsz": fontStyle.pointSize,
        "wght": fontStyle.weight
    })
}
