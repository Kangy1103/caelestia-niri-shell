// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260610


import QtQuick

QtObject {
    property string currentName
    property bool hasCurrent
    property bool blockWorkspacePopout: false

    signal detachRequested(mode: string)
}
