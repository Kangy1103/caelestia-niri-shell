// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.2.0-20260604

pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    property bool isIdle: false
    property int idleThresholdSeconds: 300

    signal idleChanged(bool idle)

    function setThreshold(seconds: int): void {
        idleThresholdSeconds = seconds;
        idleMonitor.timeout = seconds;
    }

    IdleMonitor {
        id: idleMonitor
        timeout: root.idleThresholdSeconds
        enabled: true
        respectInhibitors: true

        onIsIdleChanged: {
            const wasIdle = root.isIdle;
            root.isIdle = isIdle;

            if (wasIdle !== root.isIdle) {
                root.idleChanged(root.isIdle);
            }
        }
    }
}
