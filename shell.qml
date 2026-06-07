// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.3.0-20260606

//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "components"
import "modules/drawers"
import "modules/areapicker"
import "modules/lock"
import "modules/quicktoggles"
import "modules/keybinds"
import "modules/background"
import "modules/polkit"
import qs.modules.controlcenter
import qs.services

import QtQuick
import Quickshell

ShellRoot {
    Backdrop {}
    Background {}
    Drawers {}
    AreaPicker {}
    Lock {}

    Shortcuts {}
    QuickTogglesPanel {}
    KeybindsPanel {}

    // Native polkit authentication agent — replaces polkit-kde-authentication-agent-1
    PolkitDialog {}

    ReloadPopup {}

    // Initialize BatteryMonitor service
    property var _batteryMonitor: BatteryMonitor

    // Initialize AudioPortSwitch service
    property var _audioPortSwitch: AudioPortSwitch

    // Initialize Cava audio visualiser service
    property var _cavaService: Cava
}
