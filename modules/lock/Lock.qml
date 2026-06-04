pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

Scope {

    WlSessionLock {
        id: lock

        signal unlock

        LockSurface {
            lock: lock
            pam: pam
        }
    }

    Pam {
        id: pam

        lock: lock
    }

    Connections {
        target: IdleService

        function onIdleChanged(idle: bool): void {
            if (idle) {
                lock.locked = true;
            }
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            lock.locked = true;
        }

        function isLocked(): bool {
            return lock.locked;
        }
    }
}
