pragma ComponentBehavior: Bound

import "lock"
import QtQuick
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
        if (GlobalConfig.general.idle.inhibitWhenAudio && hasPlayer)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenCharging && isCharging)
            return false;
        return true;
    }

    function handleIdleAction(action: var): void {
        if (!action)
            return;

        // CNS: fire the lock out-of-process (like the old stasis `cns shell lock
        // lock`) instead of setting lock.lock.locked in-engine. Locking from
        // inside the IdleMonitor callback interleaves with the QML engine's own
        // screen/panel reconciliation; the resulting Variants/Scope teardown can
        // destroy a PanelWindow while its backing QQuickWindow is already freed,
        // which is a use-after-free in Quickshell (proxywindow.cpp). Driving the
        // lock over IPC from a separate process keeps that teardown clean.
        if (action === "lock")
            Quickshell.execDetached(["cns", "shell", "lock", "lock"]);
        else if (action === "unlock")
            Quickshell.execDetached(["cns", "shell", "lock", "unlock"]);
        else if (typeof action === "string") {
            // CNS: route niri actions over the already-open Niri socket instead
            // of forking a `niri msg` client. Upstream dispatches idle actions
            // straight into its compositor (Hypr.dispatch("hl.dsp.dpms(...)"));
            // Niri has no equivalent API, so the port used execDetached, which
            // forks, execs, connects and exits on every call. Run from inside the
            // IdleMonitor callback, that lands asynchronously relative to the
            // shell's own output handling.
            //
            // Only "niri msg action <name>" is intercepted. Suspend and session
            // commands still go through execDetached, and that is also the
            // fallback if the Niri socket is unavailable.
            const prefix = "niri msg action ";
            if (action.startsWith(prefix) && Niri.action(action.slice(prefix.length)))
                return;
            Quickshell.execDetached(action.split(" "));
        } else if (!SessionManager.exec(action))
            Quickshell.execDetached(action);
    }

    Connections {
        function onAboutToSleep(): void {
            if (GlobalConfig.general.idle.lockBeforeSleep)
                root.lock.lock.locked = true;
        }

        function onLockRequested(): void {
            root.lock.lock.locked = true;
        }

        function onUnlockRequested(): void {
            root.lock.lock.unlock();
        }

        target: SessionManager
    }

    Variants {
        // CNS: timeouts is a settings ListNode, not a QVariantList. Quickshell
        // Variants silently creates zero delegates for the node itself; use
        // its values list, as with other EntryList/ListNode-backed models.
        model: GlobalConfig.general.idle.timeouts.values

        IdleMonitor {
            required property var modelData

            enabled: {
                if (!root.enabled || !(modelData.enabled ?? true))
                    return false;
                if (modelData.inhibitWhenAudio && root.hasPlayer)
                    return false;
                if (modelData.inhibitWhenCharging && root.isCharging)
                    return false;
                return true;
            }
            timeout: modelData.timeout
            respectInhibitors: modelData.respectInhibitors ?? true
            onIsIdleChanged: root.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction)
        }
    }
}
