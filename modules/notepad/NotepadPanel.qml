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
            const visibilities = Visibilities.getForActive()
            if (visibilities) visibilities.notepad = true
        }

        function close(): void {
            const visibilities = Visibilities.getForActive()
            if (visibilities) visibilities.notepad = false
        }

        function toggle(): void {
            const visibilities = Visibilities.getForActive()
            if (visibilities) visibilities.notepad = !visibilities.notepad
        }
    }

    LoggingCategory {
        id: lc
        name: "caelestia.qml.notepad"
        defaultLogLevel: LoggingCategory.Info
    }
}
