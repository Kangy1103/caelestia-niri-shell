// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260615

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Scope {
    id: root

    IpcHandler {
        target: "notepad"

        function open(): void {
            const screenState = ShellState.forActive()
            if (screenState) screenState.notepad = true
        }

        function close(): void {
            const screenState = ShellState.forActive()
            if (screenState) screenState.notepad = false
        }

        function toggle(): void {
            const screenState = ShellState.forActive()
            if (screenState) screenState.notepad = !screenState.notepad
        }
    }

    LoggingCategory {
        id: lc
        name: "caelestia.qml.notepad"
        defaultLogLevel: LoggingCategory.Info
    }
}
