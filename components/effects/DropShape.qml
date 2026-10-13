// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.2.0-20260612

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real shapeProgress: 0
    property color fillColor: "#ffffff"

    anchors.fill: parent

    function lerp(a, b, t) { return a + (b - a) * t; }

    readonly property real t: Math.max(0, Math.min(1, root.shapeProgress))
    readonly property real w: width
    readonly property real h: height
    readonly property real cx: w / 2
    readonly property real cy: h / 2

    readonly property real dropTop: cy - h / 2
    readonly property real dropBottom: cy + h / 2
    readonly property real dropWideX: cx + w * 0.4
    readonly property real dropNarrowX: cx + w * 0.05
    readonly property real dropBulgeY: dropTop + h * 0.3

    readonly property real rectLeft: cx - w / 2
    readonly property real rectRight: cx + w / 2
    readonly property real rectTop: dropTop
    readonly property real rectBottom: dropBottom
    readonly property real rectR: Math.min(w, h, 200 - t * 172) / 2

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            fillColor: root.fillColor
            strokeColor: "transparent"
            joinStyle: ShapePath.RoundJoin

            property real lt: Math.max(0, root.t * root.t)
            property real st: root.t

            startX: root.cx
            startY: root.dropTop

            PathCubic {
                x: root.lerp(root.dropWideX, root.rectRight, parent.st)
                y: root.lerp(root.dropBulgeY, root.rectTop, parent.st)
                control1X: root.lerp(root.cx + root.w * 0.5, root.rectRight, parent.st)
                control1Y: root.lerp(root.dropTop + root.h * 0.1, root.rectTop, parent.st)
                control2X: root.lerp(root.dropWideX, root.rectRight, parent.st)
                control2Y: root.lerp(root.dropBulgeY, root.rectTop, parent.st)
            }

            PathCubic {
                x: root.lerp(root.cx, root.cx, parent.st)
                y: root.lerp(root.dropBottom, root.rectBottom, parent.st)
                control1X: root.lerp(root.dropNarrowX, root.rectRight, parent.st)
                control1Y: root.lerp(root.dropBottom - 15, root.rectBottom, parent.st)
                control2X: root.cx
                control2Y: root.lerp(root.dropBottom, root.rectBottom, parent.st)
            }

            PathCubic {
                x: root.lerp(root.cx - root.w * 0.05, root.rectLeft, parent.st)
                y: root.lerp(root.dropBottom - 15, root.rectBottom, parent.st)
                control1X: root.cx
                control1Y: root.lerp(root.dropBottom, root.rectBottom, parent.st)
                control2X: root.lerp(root.cx - root.w * 0.05, root.rectLeft, parent.st)
                control2Y: root.lerp(root.dropBottom - 15, root.rectBottom, parent.st)
            }

            PathCubic {
                x: root.lerp(root.cx - root.w * 0.4, root.rectLeft, parent.st)
                y: root.lerp(root.dropBulgeY, root.rectTop, parent.st)
                control1X: root.lerp(root.cx - root.w * 0.05, root.rectLeft, parent.st)
                control1Y: root.lerp(root.dropBulgeY, root.rectTop, parent.st)
                control2X: root.lerp(root.cx - root.w * 0.5, root.rectLeft, parent.st)
                control2Y: root.lerp(root.dropTop + root.h * 0.1, root.rectTop, parent.st)
            }

            PathCubic {
                x: root.cx
                y: root.dropTop
                control1X: root.lerp(root.cx - root.w * 0.4, root.rectLeft, parent.st)
                control1Y: root.lerp(root.dropTop, root.rectTop, parent.st)
                control2X: root.cx
                control2Y: root.dropTop
            }
        }
    }
}
