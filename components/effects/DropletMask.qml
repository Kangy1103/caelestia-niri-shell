// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260612

pragma ComponentBehavior: Bound

import QtQuick

Canvas {
    id: root

    property real progress: 1
    property real dropletRadius: 48
    property real finalRadius: 20

    anchors.fill: parent
    renderTarget: Canvas.FramebufferObject
    antialiasing: true

    onProgressChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onDropletRadiusChanged: requestPaint()
    onFinalRadiusChanged: requestPaint()

    function smoothstep(edge0, edge1, x) {
        const v = Math.max(0, Math.min(1, (x - edge0) / (edge1 - edge0)));
        return v * v * (3 - 2 * v);
    }

    onPaint: {
        var ctx = getContext("2d");
        var w = width;
        var h = height;

        ctx.clearRect(0, 0, w, h);

        if (root.progress >= 1.0) return;

        ctx.fillStyle = "#000000";
        ctx.fillRect(0, 0, w, h);

        var t = 1.0 - root.progress;
        var dr = root.dropletRadius;
        var fr = root.finalRadius;

        var riseT = smoothstep(0.0, 0.45, t);
        var riseCY = (1 - riseT) * (h - dr) + riseT * (h * 0.5 - dr * 0.1);

        var expandT = smoothstep(0.45, 1.0, t);
        var bubbleCY = (1 - expandT) * riseCY + expandT * (h * 0.5);

        var bubbleHW = (1 - expandT) * dr * 1.2 + expandT * (w * 0.5 - fr);
        var bubbleHH = (1 - expandT) * dr * 1.3 + expandT * (h * 0.5 - fr);
        var cornerR = Math.max(0, (1 - expandT) * dr + expandT * fr);

        var neckT = smoothstep(0.12, 0.45, t);
        var neckW = dr * 1.8 * (1 - neckT);
        var neckTop = bubbleCY + bubbleHH;
        var neckH = Math.max(0, h - neckTop);

        ctx.fillStyle = "#ffffff";

        if (neckW > 0.5 && neckH > 0.5) {
            ctx.fillRect(w * 0.5 - neckW, neckTop, neckW * 2, neckH);
        }

        var x = w * 0.5 - bubbleHW;
        var y = bubbleCY - bubbleHH;
        var bw = bubbleHW * 2;
        var bh = bubbleHH * 2;
        var r = Math.min(cornerR, Math.min(bw * 0.5, bh * 0.5));

        ctx.beginPath();
        if (r <= 0.5) {
            ctx.rect(x, y, bw, bh);
        } else {
            ctx.moveTo(x + r, y);
            ctx.arcTo(x + bw, y, x + bw, y + r, r);
            ctx.arcTo(x + bw, y + bh, x + bw - r, y + bh, r);
            ctx.arcTo(x, y + bh, x, y + bh - r, r);
            ctx.arcTo(x, y, x + r, y, r);
            ctx.closePath();
        }
        ctx.fill();
    }
}
