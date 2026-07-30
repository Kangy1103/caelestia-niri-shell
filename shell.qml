// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.4.0-20260608

//@ pragma Env CAELESTIA_CONFIG_DIR=caelestia-niri-shell
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QSG_DROP_EXPENSIVE_FONTS=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma IconTheme Slot-Symbolic-Dark-Icons

//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

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
import "modules/nexus"
import qs.services

import CNS.Config
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root

  // Font loader — GSFLoader doesn't block on missing fonts, safe to keep always
  GSFLoader {}
  ServiceLoader {}

  // Backdrop {}  // disabled — occluded by Background wallpaper
  Background {}
  Drawers {}
  AreaPicker {}
  Lock {
    id: lockModule
  }
  Shortcuts {}
  ClipboardPanel {}
  NotepadPanel {}
  KeybindsPanel {}
  CalendarPanel {}
  CalendarAppPanel {}

  // Native polkit authentication agent — replaces polkit-kde-authentication-agent-1
  PolkitDialog {}

  ReloadPopup {}

  // Config toast notifications (C++ GlobalConfig signals)
  ConfigToasts {}

  Component {
    id: geomComponent
    Geom {}
  }

  SocketServer {
    id: screenshotSocket

    active: true
    path: "/tmp/quickshell_screenshot.sock"

    handler: Socket {
      id: handler
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

  // Sync profile picture to greeter cache so the greeter user can read it
  Process {
    command: ["sh", "-c", "cp /home/kangy/.face /var/cache/cns-greeter/.face 2>/dev/null; chmod 644 /var/cache/cns-greeter/.face 2>/dev/null"]
    running: true
  }
}
