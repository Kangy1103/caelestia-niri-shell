// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260610

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities

    readonly property bool shouldBeActive: visibilities.clipboard

    property real offsetScale: shouldBeActive ? 0 : 1
    readonly property real nonAnimWidth: content.implicitWidth
    readonly property real nonAnimHeight: content.implicitHeight

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            implicitHeight = Qt.binding(() => content.implicitHeight);
        else
            implicitHeight = implicitHeight;
    }

    visible: offsetScale < 1
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 380
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
            wrapper: root
        }
    }
}
