pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool perMonitorWallpaper: false
    property var monitorWallpapers: ({})

    function getMonitorWallpaper(screenName) {
        return "";
    }

    function getMonitorWallpaperFillMode(screenName) {
        return "Fill";
    }
}
