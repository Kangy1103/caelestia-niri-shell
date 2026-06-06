// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260606

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Internal
import qs.config
import qs.services
import "lock"

Scope {
    id: root

    required property Lock lock

    /// Disables idle monitoring when any media player is actively playing.
    readonly property bool enabled: !Config.general.idle.inhibitWhenAudio
        || !Players.list.some(p => p.isPlaying)

    function handleIdleAction(action: var): void {
        if (!action) return;

        if (action === "lock")
            root.lock.lock.locked = true;
        else if (action === "unlock")
            root.lock.lock.locked = false;
        else if (action === "dpms off")
            turnScreensOff();
        else if (action === "dpms on")
            turnScreensOn();
        else if (typeof action === "string")
            NiriIpc.action(action);
        else
            Quickshell.execDetached(action);
    }

    function turnScreensOff(): void {
        Quickshell.execDetached([
            "sh", "-c",
            "niri msg -j outputs | jq -r '.[].name' | while IFS= read -r name; do niri msg output \"$name\" off; done"
        ]);
    }

    function turnScreensOn(): void {
        Quickshell.execDetached([
            "sh", "-c",
            "niri msg -j outputs | jq -r '.[].name' | while IFS= read -r name; do niri msg output \"$name\" on; done"
        ]);
    }

    // TODO: Uncomment when LogindManager C++ plugin is ported from upstream
    // LogindManager {
    //     onAboutToSleep: {
    //         if (Config.general.idle.lockBeforeSleep)
    //             root.lock.lock.locked = true;
    //     }
    //     onLockRequested: root.lock.lock.locked = true
    //     onUnlockRequested: root.lock.lock.unlock()
    // }

    Variants {
        model: Config.general.idle.timeouts

        IdleMonitor {
            required property var modelData

            enabled: root.enabled && (modelData.enabled ?? true)
            timeout: modelData.timeout
            respectInhibitors: modelData.respectInhibitors ?? true

            onIsIdleChanged: root.handleIdleAction(
                isIdle ? modelData.idleAction : modelData.returnAction)
        }
    }
}
