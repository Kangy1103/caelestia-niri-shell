// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.2.0-20260610

pragma ComponentBehavior: Bound

import "lock"
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import CNS.Config
import CNS.Services
import qs.services

Scope {
    id: root

    required property Lock lock
    readonly property bool hasPlayer: Players.list.some(p => p.isPlaying)
    readonly property bool isCharging: !UPower.onBattery
    readonly property bool enabled: {
        if (!GlobalConfig.general.idle.inhibitWhenAudio)
            return !GlobalConfig.general.idle.inhibitWhenCharging || !isCharging || !hasPlayer;
        return (!hasPlayer || !GlobalConfig.general.idle.inhibitWhenAudio) && (!isCharging || !GlobalConfig.general.idle.inhibitWhenCharging);
    }

    function handleIdleAction(action: var): void {
        if (!action)
            return;

        if (action === "lock")
            lock.lock.locked = true;
        else if (action === "unlock")
            lock.lock.locked = false;
        else if (typeof action === "string")
            Quickshell.execDetached(action.split(" "));
        else if (!SessionManager.exec(action))
            Quickshell.execDetached(action);
    }

    SessionManager {
        onAboutToSleep: {
            if (GlobalConfig.general.idle.lockBeforeSleep)
                root.lock.lock.locked = true;
        }
        onLockRequested: root.lock.lock.locked = true
        onUnlockRequested: root.lock.lock.unlock()
    }

    Variants {
        model: GlobalConfig.general.idle.timeouts

        IdleMonitor {
            required property var modelData

            enabled: root.enabled && (modelData.enabled ?? true)
            timeout: modelData.timeout
            respectInhibitors: modelData.respectInhibitors ?? true
            onIsIdleChanged: root.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction)
        }
    }
}
