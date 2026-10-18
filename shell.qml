// CNS: state directory. Phase 1 restored CAELESTIA_CONFIG_DIR support in
// Config/common.cpp for exactly this — without it configDir() falls back to
// its hardcoded literal.
//@ pragma Env CAELESTIA_CONFIG_DIR=caelestia-niri-shell
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma IconTheme Slot-Symbolic-Dark-Icons
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "components"
import "modules/drawers"
import "modules/areapicker"
import "modules/screenshot"
import "modules/lock"
import "modules/keybinds"
import "modules/calendar"
import "modules/background"
import "modules/polkit"
import "modules/clipboard"
import "modules/notepad"
import "modules/wallpaperfan"
import qs.services
import CNS.Config
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    settings.watchFiles: true

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    GSFLoader {}
    ServiceLoader {}

    Background {}
    Drawers {}
    AreaPicker {}
    Lock {
        id: lockModule
    }

    IdleMonitors {
        lock: lockModule
    }
    Shortcuts {}
    ClipboardPanel {}
    NotepadPanel {}

    // CNS: fan wallpaper picker. Opens on its own IPC target (wallpaperFan),
    // Mod+Shift+W, or the ">wallpaperfan" launcher entry — not on startup.
    WallpaperPicker {
        id: wallpaperFan
    }

    Binding {
        target: ShellState
        property: "wallpaperFan"
        value: wallpaperFan
    }
    KeybindsPanel {}
    CalendarPanel {}
    CalendarAppPanel {}

    // Native polkit authentication agent - replaces polkit-kde-authentication-agent-1
    PolkitDialog {}

    ReloadPopup {}

    // Config toast notifications (C++ GlobalConfig signals)
    ConfigToasts {}

    Component {
        id: geomComponent
        Geom {}
    }

    // Region capture is driven from outside the shell (grim/slurp wrappers),
    // so the trigger arrives over a socket rather than IPC.
    SocketServer {
        id: screenshotSocket

        active: true
        path: "/tmp/quickshell_screenshot.sock"

        handler: Socket {
            parser: SplitParser {
                onRead: msg => {
                    if (msg === "geom") {
                        geomComponent.createObject(root);
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "screenshot"
        function region(): void {
            geomComponent.createObject(root);
        }
    }
}
