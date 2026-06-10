// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260610

pragma ComponentBehavior: Bound

import qs.services
import Quickshell
import Quickshell.Io

Scope {
    id: root

    IpcHandler {
        target: "clipboard"

        function open(): void {
            const visibilities = Visibilities.getForActive();
            visibilities.clipboard = true;
        }

        function close(): void {
            const visibilities = Visibilities.getForActive();
            visibilities.clipboard = false;
        }

        function toggle(): void {
            const visibilities = Visibilities.getForActive();
            visibilities.clipboard = !visibilities.clipboard;
        }
    }
}
