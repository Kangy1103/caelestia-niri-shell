// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260615

import QtQuick
import Quickshell
import CNS.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.notepad
    property real offsetScale: shouldBeActive ? 0 : 1

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            implicitHeight = Qt.binding(() => content.implicitHeight)
    }

    visible: offsetScale < 1
    anchors.topMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight || 200
    implicitWidth: content.implicitWidth || 680
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
        }
    }
}
