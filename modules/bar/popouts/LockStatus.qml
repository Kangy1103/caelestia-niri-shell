// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260610


import QtQuick.Layouts
import CNS.Config
import qs.components
import qs.services

ColumnLayout {
    spacing: Config.appearance.spacing.small

    StyledText {
        text: qsTr("Capslock: %1").arg(Niri.capsLock ? "Enabled" : "Disabled")
    }

    StyledText {
        text: qsTr("Numlock: %1").arg(Niri.numLock ? "Enabled" : "Disabled")
    }
}
