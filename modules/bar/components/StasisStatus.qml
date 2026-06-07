pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    implicitWidth: icon.implicitHeight + Appearance.padding.xs * 2 + 8
    implicitHeight: icon.implicitHeight + Appearance.padding.xs * 2

    property string stasisState: "idle_waiting"
    property string stasisTooltip: "Stasis: waiting"
    property string stasisProfile: "default"

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!pollRunner.running)
                pollRunner.running = true;
        }
    }

    Process {
        id: pollRunner
        command: ["stasis", "info", "--json"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                try {
                    var info = JSON.parse(data.trim());
                    if (!info) return;
                    root.stasisState = info.alt ?? "idle_waiting";
                    root.stasisProfile = info.profile ?? "default";
                    root.stasisTooltip = info.tooltip ?? "Stasis: waiting";
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: pollRunner.running = true

    StyledRect {
        id: bg
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: root.stasisState !== "idle_waiting" && root.stasisState !== "idle_idle"
            ? Qt.alpha(Colours.palette.m3primaryContainer, 1)
            : "transparent"

        MaterialIcon {
            id: icon
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -1
            text: "coffee"
            color: root.stasisState !== "idle_waiting" && root.stasisState !== "idle_idle"
                ? Colours.palette.m3onSurfaceVariant
                : Colours.palette.m3primary
            font.bold: true
            font.pointSize: 16
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                contextMenu.expanded = !contextMenu.expanded;
            } else {
                Quickshell.execDetached(["stasis", "toggle-inhibit"]);
            }
        }
    }

    Menu {
        id: contextMenu
        expanded: false

        items: [
            MenuItem {
                text: "Default"
                activeIcon: root.stasisProfile === "none" || root.stasisProfile === "default" ? "check" : ""
                onClicked: {
                    Quickshell.execDetached(["stasis", "profile", "default"]);
                    contextMenu.expanded = false;
                }
            },
            MenuItem {
                text: "Gaming"
                icon: "sports_esports"
                activeIcon: root.stasisProfile === "gaming" ? "check" : ""
                onClicked: {
                    Quickshell.execDetached(["stasis", "profile", "gaming"]);
                    contextMenu.expanded = false;
                }
            },
            MenuItem {
                text: "Video"
                icon: "movie"
                activeIcon: root.stasisProfile === "video" ? "check" : ""
                onClicked: {
                    Quickshell.execDetached(["stasis", "profile", "video"]);
                    contextMenu.expanded = false;
                }
            }
        ]
    }
}
