pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import CNS.Config
import Quickshell
import QtQuick

Item {
    id: root

    implicitWidth: icon.implicitHeight + Tokens.padding.extraSmall * 2 + 8
    implicitHeight: icon.implicitHeight + Tokens.padding.extraSmall * 2

    readonly property string stasisState: Stasis.state
    readonly property string stasisTooltip: Stasis.tooltip
    readonly property string stasisProfile: Stasis.profile

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
                Stasis.toggleInhibit();
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
                    Stasis.selectProfile("default");
                    contextMenu.expanded = false;
                }
            },
            MenuItem {
                text: "Gaming"
                icon: "sports_esports"
                activeIcon: root.stasisProfile === "gaming" ? "check" : ""
                onClicked: {
                    Stasis.selectProfile("gaming");
                    contextMenu.expanded = false;
                }
            },
            MenuItem {
                text: "Video"
                icon: "movie"
                activeIcon: root.stasisProfile === "video" ? "check" : ""
                onClicked: {
                    Stasis.selectProfile("video");
                    contextMenu.expanded = false;
                }
            }
        ]
    }
}
