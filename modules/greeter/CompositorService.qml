pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool isHyprland: false
    property bool isNiri: true
    property bool isDwl: false
    property bool isLabwc: false
    property bool isSway: false
    property bool isScroll: false
    property bool isMango: false
    property bool isMiracle: false
}
