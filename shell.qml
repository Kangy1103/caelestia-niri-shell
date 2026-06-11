// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.4.0-20260608

//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "components"
import "modules/drawers"
import "modules/areapicker"
import "modules/lock"
import "modules/keybinds"
import "modules/calendar"
import "modules/background"
import "modules/polkit"
import "modules/clipboard"
import "modules/nexus"
import qs.services

import Caelestia.Config
import QtQuick
import Quickshell

ShellRoot {
    // Font loader — GSFLoader doesn't block on missing fonts, safe to keep always
    GSFLoader {}

    Backdrop {}
    Background {}
    Drawers {}
    AreaPicker {}
    Lock { id: lockModule }
    IdleMonitors { lock: lockModule }

    Shortcuts {}
    ClipboardPanel {}
    KeybindsPanel {}
    CalendarPanel {}
    CalendarAppPanel {}

    // Native polkit authentication agent — replaces polkit-kde-authentication-agent-1
    PolkitDialog {}

    ReloadPopup {}

    // Config toast notifications (C++ GlobalConfig signals)
    ConfigToasts {}

    // Initialize BatteryMonitor service
    property var _batteryMonitor: BatteryMonitor

    // Initialize AudioPortSwitch service
    property var _audioPortSwitch: AudioPortSwitch

    // Initialize Cava audio visualiser service
    property var _cavaService: Cava

    // Initialize GameMode service
    property var _gameMode: GameMode

    // Initialize C++ Config singleton (populates Caelestia.Config.GlobalConfig)
    property var _cppConfig: GlobalConfig
}
