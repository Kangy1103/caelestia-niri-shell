// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.3.1-20260605

pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    property bool isIdle: false
    property int idleThresholdSeconds: 1800
    // Relative to idleThresholdSeconds. Total idle time before screen-off is idleThreshold + screenOffDelay.
    property int screenOffDelaySeconds: 1800

    signal idleChanged(bool idle)

    function setThreshold(seconds: int): void {
        idleThresholdSeconds = seconds;
        idleMonitor.timeout = seconds;
        console.log("IdleService: threshold updated to", seconds);
    }

    IdleMonitor {
        id: idleMonitor
        timeout: root.idleThresholdSeconds
        enabled: true
        respectInhibitors: false

        onIsIdleChanged: {
            const wasIdle = root.isIdle;
            root.isIdle = isIdle;

            if (wasIdle !== root.isIdle) {
                root.idleChanged(root.isIdle);
            }

            if (isIdle) {
                screenOffTimer.start();
            } else {
                screenOffTimer.stop();
                turnScreensOn();
            }
        }
    }

    Timer {
        id: screenOffTimer
        interval: root.screenOffDelaySeconds * 1000
        onTriggered: Quickshell.execDetached([
            "sh", "-c",
            "niri msg -j outputs | jq -r '.[].name' | while IFS= read -r name; do niri msg output \"$name\" off; done"
        ])
    }

    function turnScreensOn(): void {
        Quickshell.execDetached([
            "sh", "-c",
            "niri msg -j outputs | jq -r '.[].name' | while IFS= read -r name; do niri msg output \"$name\" on; done"
        ]);
    }

    // Workaround for Quickshell 0.3.0 IdleMonitor race condition
    Timer {
        interval: 3000
        running: true
        repeat: false
        onTriggered: {
            if (!idleMonitor.enabled) {
                idleMonitor.enabled = false;
                idleMonitor.enabled = true;
            }
        }
    }
}
