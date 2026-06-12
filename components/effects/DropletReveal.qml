// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.2.0-20260612

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

Item {
    id: root

    property real progress: 1
    property real dropletRadius: 48
    property real finalRadius: 20

    readonly property alias contentItem: content
    default property alias contentData: content.data

    visible: progress < 1

    Item {
        id: content
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskSource: dropletMask
            maskEnabled: true
            maskSpreadAtMin: 1
            maskThresholdMin: 0.5
        }
    }

    DropletMask {
        id: dropletMask
        anchors.fill: parent
        progress: root.progress
        dropletRadius: root.dropletRadius
        finalRadius: root.finalRadius
    }
}
