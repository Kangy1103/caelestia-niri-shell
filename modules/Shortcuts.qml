import qs.modules.controlcenter
import qs.services
import Caelestia.Config
import Caelestia
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property bool launcherInterrupted

    IpcHandler {
        target: "drawers"

        function toggle(drawer: string): void {
            if (list().split("\n").includes(drawer)) {
                const visibilities = Visibilities.getForActive();
                visibilities[drawer] = !visibilities[drawer];
            } else {
                console.warn(`[IPC] Drawer "${drawer}" does not exist`);
            }
        }

        function list(): string {
            const visibilities = Visibilities.getForActive();
            return Object.keys(visibilities).filter(k => typeof visibilities[k] === "boolean").join("\n");
        }
    }

    IpcHandler {
        target: "controlCenter"

        function open(): void {
            WindowFactory.create();
        }
    }

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

    IpcHandler {
        target: "clipboard"

        function open(): void {
            const visibilities = Visibilities.getForActive()
            visibilities.clipboardRequested = true
            visibilities.launcher = true
        }

        function close(): void {
            const visibilities = Visibilities.getForActive()
            visibilities.launcher = false
        }

        function toggle(): void {
            const visibilities = Visibilities.getForActive()
            if (visibilities.launcher) {
                visibilities.launcher = false
            } else {
                visibilities.clipboardRequested = true
                visibilities.launcher = true
            }
        }

        function clear(): void {
            Quickshell.execDetached(["cliphist", "wipe"]);
            Quickshell.execDetached(["wl-copy", "--clear"]);
            Toaster.toast(qsTr("Clipboard cleared"), qsTr("The clipboard history has been wiped."), "content_paste_off");
        }
    }
}
