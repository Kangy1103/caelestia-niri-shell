pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    property var keyboardLayoutNames: Niri.kbLayoutsArray || []

    function getCurrentKeyboardLayoutName() {
        return Niri.kbLayout || "";
    }

    function cycleKeyboardLayout() {
        Niri.action("switch-layout", []);
    }
}
