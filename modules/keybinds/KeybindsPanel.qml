pragma ComponentBehavior: Bound

import qs.services
import Quickshell
import Quickshell.Io

Scope {
    id: root

    IpcHandler {
        target: "keybinds"

        function open(): void {
            const screenState = ShellState.forActive()
            if (screenState) screenState.keybinds = true
        }

        function close(): void {
            const screenState = ShellState.forActive()
            if (screenState) screenState.keybinds = false
        }

        function toggle(): void {
            const screenState = ShellState.forActive()
            if (screenState) screenState.keybinds = !screenState.keybinds
        }
    }
}
