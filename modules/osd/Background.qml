import qs.components
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property Wrapper wrapper
    readonly property real rounding: Config.border.rounding
    readonly property bool flatten: wrapper.width < rounding * 2
    readonly property real roundingX: flatten ? wrapper.width / 2 : rounding

    readonly property bool active: wrapper.shouldBeActive

    strokeWidth: root.active ? -1 : 0
    fillColor: root.active ? Colours.palette.m3surface : "transparent"

    PathArc {
        relativeX: -root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
    }
    PathLine {
        relativeX: -(root.wrapper.width - root.roundingX * 2)
        relativeY: 0
    }
    PathArc {
        relativeX: -root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.rounding * 2
    }
    PathArc {
        relativeX: root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }
    PathLine {
        relativeX: root.wrapper.width - root.roundingX * 2
        relativeY: 0
    }
    PathArc {
        relativeX: root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
    }

    Behavior on fillColor {
        CAnim {}
    }
}
