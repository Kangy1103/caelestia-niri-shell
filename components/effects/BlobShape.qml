// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260612

pragma ComponentBehavior: Bound

import QtQuick

Canvas {
    id: root

    property real progress: 0
    property color fillColor: "#ffffff"
    property real blobRadius: 200
    property real finalRadius: 28

    anchors.fill: parent
    renderStrategy: Canvas.Immediate
    renderTarget: Canvas.Image
    antialiasing: true

    onProgressChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        var w = width;
        var h = height;

        ctx.clearRect(0, 0, w, h);

        var t = Math.max(0, Math.min(1, root.progress));
        var r = Math.min(w / 2, h / 2, root.blobRadius - t * (root.blobRadius - root.finalRadius));
        r = Math.max(0, r);

        ctx.fillStyle = root.fillColor;
        ctx.beginPath();
        ctx.moveTo(r, 0);
        ctx.arcTo(w, 0, w, r, r);
        ctx.arcTo(w, h, w - r, h, r);
        ctx.arcTo(0, h, 0, h - r, r);
        ctx.arcTo(0, 0, r, 0, r);
        ctx.closePath();
        ctx.fill();
    }
}
