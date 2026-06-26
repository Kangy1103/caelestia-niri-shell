pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import CNS.Config
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    implicitWidth: icon.implicitHeight + Tokens.padding.extraSmall * 2 + 8
    implicitHeight: icon.implicitHeight + Tokens.padding.extraSmall * 2

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
        command: ["/usr/bin/stasis", "info", "--json"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var info = JSON.parse(this.text.trim());
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
        radius: Tokens.rounding.full
        color: root.stasisState !== "idle_waiting"
            ? Qt.alpha(Colours.palette.m3primaryContainer, 1)
            : "transparent"

        MaterialIcon {
            id: icon
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -1
            text: "coffee"
            color: root.stasisState !== "idle_waiting"
                ? Colours.palette.m3onSurfaceVariant
                : Colours.palette.m3primary
            fontStyle: Tokens.font.icon.size(16).weight(Font.Bold).build()
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
                root.stasisState = root.stasisState === "manually_inhibited" ? "idle_waiting" : "manually_inhibited";
                Quickshell.execDetached(["stasis", "toggle-inhibit"]);
            }
        }
    }

    Menu {
        id: contextMenu
        attachTo: bg
        attachSideX: Menu.Right
        attachSideY: Menu.Bottom
        thisSideX: Menu.Right
        thisSideY: Menu.Top
        expanded: false

        items: [
            MenuItem {
                text: "Default"
                activeIcon: root.stasisProfile === "none" || root.stasisProfile === "default" ? "check" : ""
                onClicked: {
                    root.stasisProfile = "default";
                    Quickshell.execDetached(["stasis", "profile", "default"]);
                    contextMenu.expanded = false;
                }
            },
            MenuItem {
                text: "Gaming"
                icon: "sports_esports"
                activeIcon: root.stasisProfile === "gaming" ? "check" : ""
                onClicked: {
                    root.stasisProfile = "gaming";
                    Quickshell.execDetached(["stasis", "profile", "gaming"]);
                    contextMenu.expanded = false;
                }
            },
            MenuItem {
                text: "Video"
                icon: "movie"
                activeIcon: root.stasisProfile === "video" ? "check" : ""
                onClicked: {
                    root.stasisProfile = "video";
                    Quickshell.execDetached(["stasis", "profile", "video"]);
                    contextMenu.expanded = false;
                }
            }
        ]
    }
}
