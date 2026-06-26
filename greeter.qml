// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.4.0-20260621

//@ pragma Env CAELESTIA_CONFIG_DIR=caelestia-niri-shell
//@ pragma Env QSG_RENDER_LOOP=threaded

import "modules/greeter"
import CNS.Config
import QtQuick
import Quickshell

ShellRoot {
    // Force GlobalConfig initialization
    property var _cppConfig: GlobalConfig

    Greeter {}
}
