// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260612

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

PanelWindow {
    id: geom

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: geom.destroy()
    }

    MouseArea {
        anchors.fill: parent
        z: 1
        onPressed: (mouse) => {
            geomRect.visible = true
            geomRect.anchorX = mouse.x
            geomRect.anchorY = mouse.y

            geomRect.anchor1X = mouse.x
            geomRect.anchor1Y = mouse.y
            geomRect.anchor2X = mouse.x
            geomRect.anchor2Y = mouse.y
        }
        onPositionChanged: (mouse) => {
            geomRect.anchor1X = Math.min(geomRect.anchorX, mouse.x)
            geomRect.anchor1Y = Math.min(geomRect.anchorY, mouse.y)

            geomRect.anchor2X = Math.max(geomRect.anchorX, mouse.x)
            geomRect.anchor2Y = Math.max(geomRect.anchorY, mouse.y)
        }
        onReleased: (mouse) => {
            geomRect.visible = false
            var scale = geom.screen ? geom.screen.devicePixelRatio : 1.0
            var sx = geom.screen ? geom.screen.x : 0
            var sy = geom.screen ? geom.screen.y : 0
            var gx = Math.round((sx + geomRect.anchor1X) * scale)
            var gy = Math.round((sy + geomRect.anchor1Y) * scale)
            var gw = Math.round(geomRect.anchorDx * scale)
            var gh = Math.round(geomRect.anchorDy * scale)
            var cmd = "d=~/Pictures/cachyos-screenshots && mkdir -p \"$d\" && f=\"$d/Screenshot from $(date '+%Y-%m-%d %H-%M-%S').png\" && grim -g \"" + gx + "," + gy + " " + gw + "x" + gh + "\" \"$f\" && wl-copy < \"$f\""
            Quickshell.execDetached(["sh", "-c", cmd])
            geom.destroy()
        }
    }

    Rectangle {
        id: geomRect
        anchors.fill: parent

        color: "transparent"
        property int anchorX: 0
        property int anchorY: 0

        property int anchor1X: parent.width/2
        property int anchor1Y: parent.height/2
        property int anchor2X: parent.width/2
        property int anchor2Y: parent.height/2

        property int anchorDx: anchor2X - anchor1X
        property int anchorDy: anchor2Y - anchor1Y

        property int borderWidth: 6

        onAnchor1XChanged: canvas.requestPaint()
        onAnchor1YChanged: canvas.requestPaint()
        onAnchor2XChanged: canvas.requestPaint()
        onAnchor2YChanged: canvas.requestPaint()

        Canvas {
            id: canvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.fillStyle = Colours.m3surface
                ctx.globalAlpha = 0.8
                ctx.fillRect(0, 0, parent.width, parent.height)
                ctx.globalAlpha = 1
                ctx.fillStyle = Colours.m3primary
                ctx.fillRect(geomRect.anchor1X-geomRect.borderWidth, geomRect.anchor1Y-geomRect.borderWidth, geomRect.anchorDx+geomRect.borderWidth*2, geomRect.anchorDy+geomRect.borderWidth*2)

                ctx.beginPath()
                ctx.arc(geomRect.anchor1X, geomRect.anchor1Y, geomRect.borderWidth*4, 0, 2 * Math.PI)
                ctx.fill()

                ctx.beginPath()
                ctx.arc(geomRect.anchor2X, geomRect.anchor1Y, geomRect.borderWidth*4, 0, 2 * Math.PI)
                ctx.fill()

                ctx.beginPath()
                ctx.arc(geomRect.anchor1X, geomRect.anchor2Y, geomRect.borderWidth*4, 0, 2 * Math.PI)
                ctx.fill()

                ctx.beginPath()
                ctx.arc(geomRect.anchor2X, geomRect.anchor2Y, geomRect.borderWidth*4, 0, 2 * Math.PI)
                ctx.fill()

                ctx.clearRect(geomRect.anchor1X, geomRect.anchor1Y, geomRect.anchorDx, geomRect.anchorDy)
            }
        }

        Rope {
            anchors.fill: parent
            color: "transparent"
            anchorX: 0
            anchorY: 0
            pullX: geomRect.anchor1X
            pullY: geomRect.anchor1Y
        }

        Rope {
            anchors.fill: parent
            color: "transparent"
            anchorX: parent.width
            anchorY: 0
            pullX: geomRect.anchor2X
            pullY: geomRect.anchor1Y
        }

        Rope {
            anchors.fill: parent
            color: "transparent"
            anchorX: 0
            anchorY: parent.height
            pullX: geomRect.anchor1X
            pullY: geomRect.anchor2Y
        }

        Rope {
            anchors.fill: parent
            color: "transparent"
            anchorX: parent.width
            anchorY: parent.height
            pullX: geomRect.anchor2X
            pullY: geomRect.anchor2Y
        }
    }
}
