// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260612

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

ShaderEffect {
    id: root

    property color dropletColor: "transparent"
    property real progress: 1
    property real dropletRadius: 40
    property real finalRadius: 20

    property real iWidth: width
    property real iHeight: height

    visible: progress < 1
    mesh: Qt.size(1, 1)
    fragmentShader: Quickshell.shellPath("assets/shaders/dropletBg.frag.qsb")
}
