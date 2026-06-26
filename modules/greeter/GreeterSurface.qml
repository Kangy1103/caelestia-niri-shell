// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260621

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        property var modelData

        screen: modelData
        anchors { left: true; right: true; top: true; bottom: true }
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"

        GreeterContent {
            anchors.fill: parent
            screenName: root.screen?.name ?? ""
        }
    }
}
