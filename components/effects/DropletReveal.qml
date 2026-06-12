// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260612

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Item {
    id: root

    property real progress: 1
    property real dropletRadius: 40
    property real finalRadius: 20

    readonly property alias contentItem: content
    default property alias contentData: content.data

    property Item source: null

    visible: progress < 1

    Item {
        id: content
        anchors.fill: parent
    }

    ShaderEffect {
        id: shader
        anchors.fill: parent
        mesh: Qt.size(1, 1)
        fragmentShader: Quickshell.shellPath("assets/shaders/droplet.frag.qsb")

        property Item source: root.source || content
        property real progress: root.progress
        property real dropletRadius: root.dropletRadius
        property real finalRadius: root.finalRadius
        property real iWidth: width
        property real iHeight: height
    }
}
