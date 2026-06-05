// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.1-20260605

//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "components"
import "modules/drawers"
import "modules/areapicker"
import "modules/lock"
import "modules/quicktoggles"
import "modules/background"
import "modules/polkit"
import qs.modules.controlcenter
import qs.services
import qs.config

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

    // Native polkit authentication agent — replaces polkit-kde-authentication-agent-1
    PolkitDialog {}

    ReloadPopup {}

    // Initialize BatteryMonitor service
    property var _batteryMonitor: BatteryMonitor

    // Initialize AudioPortSwitch service
    property var _audioPortSwitch: AudioPortSwitch

    // Initialize Cava audio visualiser service
    property var _cavaService: Cava

    // Wire idle timeout from config
    property var _idleService: IdleService

    Connections {
        target: Config
        function onConfigLoaded(): void {
            IdleService.setThreshold(Config.general.idleTimeout);
            IdleService.screenOffDelaySeconds = Config.general.screenOffDelay;
        }
    }
}
