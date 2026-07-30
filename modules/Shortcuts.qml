// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.2.0-20260610

import QtQuick
import Quickshell
import Quickshell.Io
import CNS
import CNS.Config
import qs.components.misc
import qs.services
import qs.modules.nexus

Scope {
    id: root

    property bool launcherInterrupted
    // Niri doesn't expose per-window fullscreen state via IPC.
    // TODO: add when Niri IPC gains fullscreen tracking.
    readonly property bool hasFullscreen: Niri.hasFullscreen

    // ── CustomShortcut: nexus ──
    CustomShortcut {
        id: scNexus
        name: "nexus"
        description: "Open nexus"
        onPressed: WindowFactory.create()
    }

    // ── CustomShortcut: showall ──
    CustomShortcut {
        id: scShowall
        name: "showall"
        description: "Toggle launcher, dashboard and osd"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const v = ShellState.forActive();
            v.launcher = v.dashboard = v.osd = v.utilities = !(v.launcher || v.dashboard || v.osd || v.utilities);
        }
    }

    // ── CustomShortcut: dashboard ──
    CustomShortcut {
        id: scDashboard
        name: "dashboard"
        description: "Toggle dashboard"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const screenState = ShellState.forActive();
            screenState.dashboard = !screenState.dashboard;
        }
    }

    // ── CustomShortcut: session ──
    CustomShortcut {
        id: scSession
        name: "session"
        description: "Toggle session menu"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const screenState = ShellState.forActive();
            screenState.session = !screenState.session;
        }
    }

    // ── CustomShortcut: launcher (hold-to-show pattern) ──
    CustomShortcut {
        id: scLauncher
        name: "launcher"
        description: "Toggle launcher"
        onPressed: root.launcherInterrupted = false
        onReleased: {
            if (!root.launcherInterrupted && !root.hasFullscreen) {
                const screenState = ShellState.forActive();
                screenState.launcher = !screenState.launcher;
            }
            root.launcherInterrupted = false;
        }
    }

    // ── CustomShortcut: launcherInterrupt ──
    CustomShortcut {
        id: scLauncherInterrupt
        name: "launcherInterrupt"
        description: "Interrupt launcher keybind"
        onPressed: root.launcherInterrupted = true
    }

    // ── CustomShortcut: sidebar ──
    CustomShortcut {
        id: scSidebar
        name: "sidebar"
        description: "Toggle sidebar"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const screenState = ShellState.forActive();
            screenState.sidebar = !screenState.sidebar;
        }
    }

    // ── CustomShortcut: utilities ──
    CustomShortcut {
        id: scUtilities
        name: "utilities"
        description: "Toggle utilities"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const screenState = ShellState.forActive();
            screenState.utilities = !screenState.utilities;
        }
    }

    // ── IPC: nexus ──
    IpcHandler {
        target: "nexus"
        function open(): void {
            scNexus.pressed();
        }
    }

    // ── IPC: launcher (hold-to-show) ──
    IpcHandler {
        target: "launcher"
        function open(): void { scLauncher.pressed(); }
        function pressed(): void { scLauncher.pressed(); }
        function released(): void { scLauncher.released(); }
    }

    // ── IPC: launcherInterrupt ──
    IpcHandler {
        target: "launcherInterrupt"
        function open(): void { scLauncherInterrupt.pressed(); }
        function pressed(): void { scLauncherInterrupt.pressed(); }
    }

    // ── IPC: dashboard ──
    IpcHandler {
        target: "dashboard"
        function open(): void { scDashboard.pressed(); }
        function pressed(): void { scDashboard.pressed(); }
    }

    // ── IPC: session ──
    IpcHandler {
        target: "session"
        function open(): void { scSession.pressed(); }
        function pressed(): void { scSession.pressed(); }
    }

    // ── IPC: sidebar ──
    IpcHandler {
        target: "sidebar"
        function open(): void { scSidebar.pressed(); }
        function pressed(): void { scSidebar.pressed(); }
    }

    // ── IPC: utilities ──
    IpcHandler {
        target: "utilities"
        function open(): void { scUtilities.pressed(); }
        function pressed(): void { scUtilities.pressed(); }
    }

    // ── IPC: showall ──
    IpcHandler {
        target: "showall"
        function open(): void { scShowall.pressed(); }
        function pressed(): void { scShowall.pressed(); }
    }

    // ── IPC: drawers ──
    IpcHandler {
        target: "drawers"
        function toggle(drawer: string): void {
            if (list().split("\n").includes(drawer)) {
                if (root.hasFullscreen && ["launcher", "session", "dashboard"].includes(drawer))
                    return;
                const screenState = ShellState.forActive();
                screenState[drawer] = !screenState[drawer];
            } else {
                console.warn(lc, `Drawer "${drawer}" does not exist`);
            }
        }

        function list(): string {
            const screenState = ShellState.forActive();
            return Object.keys(screenState).filter(k => typeof screenState[k] === "boolean").join("\n");
        }

        function isOpen(drawer: string): string {
            const screenState = ShellState.forActive();
            if (typeof screenState[drawer] !== "boolean")
                return "unknown";
            return screenState[drawer] ? "1" : "0";
        }
    }

    // ── IPC: greeter (used by greeter.qml entry point) ──
    IpcHandler {
        target: "greeter"
        function lock(): void {
            // Trigger lock from shell; only relevant in shell mode
            // Forward to lock module
        }
        function isAvailable(): bool {
            return false; // Greeter module not loaded in shell mode
        }
    }

    // ── IPC: toaster ──
    IpcHandler {
        target: "toaster"
        function info(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Info);
        }
        function success(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Success);
        }
        function warn(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Warning);
        }
        function error(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Error);
        }
    }

    LoggingCategory {
        id: lc
        name: "caelestia.qml.shortcuts"
        defaultLogLevel: LoggingCategory.Info
    }
}
