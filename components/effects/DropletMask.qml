// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.2.0-20260612

pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property real progress: 1
    property real dropletRadius: 48
    property real finalRadius: 20
    property real screenBottomOffset: 0

    visible: false
    layer.enabled: true

    readonly property real t: Math.max(0, 1.0 - root.progress)
    readonly property real virtualBottom: height + screenBottomOffset
    readonly property real riseF: Math.min(1, Math.max(0, t / 0.45))
    readonly property real expandF: Math.min(1, Math.max(0, (t - 0.45) / 0.55))
    readonly property real neckF: Math.min(1, Math.max(0, (t - 0.12) / 0.33))

    readonly property real ssRise: riseF * riseF * (3 - 2 * riseF)
    readonly property real ssExpand: expandF * expandF * (3 - 2 * expandF)
    readonly property real ssNeck: neckF * neckF * (3 - 2 * neckF)

    readonly property real bubbleCY: {
        var riseCY = (1 - ssRise) * (virtualBottom - dropletRadius) + ssRise * (height * 0.5 - dropletRadius * 0.1);
        return (1 - ssExpand) * riseCY + ssExpand * (height * 0.5);
    }

    readonly property real bubbleHW: (1 - ssExpand) * dropletRadius * 1.2 + ssExpand * (width * 0.5 - finalRadius)
    readonly property real bubbleHH: (1 - ssExpand) * dropletRadius * 1.3 + ssExpand * (height * 0.5 - finalRadius)
    readonly property real cornerR: Math.max(0, (1 - ssExpand) * dropletRadius + ssExpand * finalRadius)

    readonly property real bubbleX: width * 0.5 - bubbleHW
    readonly property real bubbleY: bubbleCY - bubbleHH
    readonly property real bubbleW: bubbleHW * 2
    readonly property real bubbleH: bubbleHH * 2

    readonly property real neckTop: bubbleY + bubbleH
    readonly property real neckW: dropletRadius * 1.8 * (1 - ssNeck)
    readonly property real neckH: Math.max(0, virtualBottom - neckTop)
    readonly property real neckY: neckTop

    Rectangle {
        color: "#ffffff"
        width: neckW
        height: neckH
        x: (parent.width - neckW) / 2
        y: neckY
        visible: neckW > 0.5 && neckH > 0.5
    }

    Rectangle {
        id: bubble
        color: "#ffffff"
        x: bubbleX
        y: bubbleY
        width: bubbleW
        height: bubbleH
        radius: Math.min(cornerR, Math.min(bubbleW / 2, bubbleH / 2))
    }
}
