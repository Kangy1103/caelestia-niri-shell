// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.2.0-20260610

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components.misc
import qs.services
import qs.modules.nexus

Scope {
    id: root

    property bool launcherInterrupted
    // Niri doesn't expose per-window fullscreen state via IPC.
    // TODO: add when Niri IPC gains fullscreen tracking.
    readonly property bool hasFullscreen: false

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
            const v = Visibilities.getForActive();
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
            const visibilities = Visibilities.getForActive();
            visibilities.dashboard = !visibilities.dashboard;
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
            const visibilities = Visibilities.getForActive();
            visibilities.session = !visibilities.session;
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
                const visibilities = Visibilities.getForActive();
                visibilities.launcher = !visibilities.launcher;
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
            const visibilities = Visibilities.getForActive();
            visibilities.sidebar = !visibilities.sidebar;
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
            const visibilities = Visibilities.getForActive();
            visibilities.utilities = !visibilities.utilities;
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
                const visibilities = Visibilities.getForActive();
                visibilities[drawer] = !visibilities[drawer];
            } else {
                console.warn(lc, `Drawer "${drawer}" does not exist`);
            }
        }

        function list(): string {
            const visibilities = Visibilities.getForActive();
            return Object.keys(visibilities).filter(k => typeof visibilities[k] === "boolean").join("\n");
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

    // ── IPC: clipboard (custom — not in upstream) ──
    IpcHandler {
        target: "clipboard"
        function open(): void {
            const visibilities = Visibilities.getForActive();
            visibilities.requestMode = "clip";
            visibilities.launcher = true;
        }
        function close(): void {
            const visibilities = Visibilities.getForActive();
            visibilities.launcher = false;
        }
        function toggle(): void {
            const visibilities = Visibilities.getForActive();
            if (visibilities.launcher) {
                visibilities.launcher = false;
            } else {
                visibilities.requestMode = "clip";
                visibilities.launcher = true;
            }
        }
        function clear(): void {
            Quickshell.execDetached(["cliphist", "wipe"]);
            Quickshell.execDetached(["wl-copy", "--clear"]);
            Toaster.toast(qsTr("Clipboard cleared"), qsTr("The clipboard history has been wiped."), "content_paste_off");
        }
    }

    LoggingCategory {
        id: lc
        name: "caelestia.qml.shortcuts"
        defaultLogLevel: LoggingCategory.Info
    }
}
