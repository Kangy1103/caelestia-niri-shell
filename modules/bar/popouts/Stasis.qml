// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.6.0-20260615

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import CNS.Config
import qs.components
import qs.services
import Quickshell.Io


Column {
    id: root

    spacing: Config.appearance.spacing.large
    width: 200
    topPadding: Config.appearance.padding.extraSmall

    property string stasisState: "idle_waiting"
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
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: pollRunner.running = true

    StyledText {
        text: stasisState === "manually_inhibited" ? "Paused"
            : stasisProfile === "gaming" ? "Gaming"
            : stasisProfile === "video" ? "Video"
            : "Default"
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    StyledRect {
        width: parent.width
        implicitHeight: pauseRow.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.full
        color: stasisState === "manually_inhibited" ? Colours.palette.m3tertiary : Colours.palette.m3primary

        Behavior on color {
            CAnim {}
        }

        StateLayer {
            onClicked: {
                root.stasisState = root.stasisState === "manually_inhibited" ? "idle_waiting" : "manually_inhibited";
                Quickshell.execDetached(["stasis", "toggle-inhibit"]);
            }
        }

        Item {
            id: pauseRow
            anchors.centerIn: parent
            width: pauseIcon.width + Config.appearance.spacing.small + pauseLabel.implicitWidth
            implicitHeight: Math.max(pauseIcon.implicitHeight, pauseLabel.implicitHeight)

            MaterialIcon {
                id: pauseIcon
                anchors.verticalCenter: parent.verticalCenter
                text: stasisState === "manually_inhibited" ? "play_arrow" : "pause"
                color: stasisState === "manually_inhibited" ? Colours.palette.m3onTertiary : Colours.palette.m3onPrimary
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                id: pauseLabel
                anchors.left: pauseIcon.right
                anchors.leftMargin: Config.appearance.spacing.small
                anchors.verticalCenter: parent.verticalCenter
                text: stasisState === "manually_inhibited" ? "Resume" : "Pause"
                color: stasisState === "manually_inhibited" ? Colours.palette.m3onTertiary : Colours.palette.m3onPrimary
                font: Tokens.font.body.small
            }
        }
    }

    StyledText {
        text: "Profiles"
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    StyledRect {
        width: parent.width
        implicitHeight: defRow.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.full
        color: stasisProfile === "none" || stasisProfile === "default"
            ? Colours.palette.m3primaryContainer
            : Colours.palette.m3surfaceContainer

        Behavior on color {
            CAnim {}
        }

        StateLayer {
            onClicked: {
                root.stasisProfile = "default";
                Quickshell.execDetached(["stasis", "profile", "default"]);
            }
        }

        Item {
            id: defRow
            anchors.centerIn: parent
            width: defIcon.width + Config.appearance.spacing.small + defLabel.implicitWidth
            implicitHeight: Math.max(defIcon.implicitHeight, defLabel.implicitHeight)

            MaterialIcon {
                id: defIcon
                anchors.verticalCenter: parent.verticalCenter
                text: "tune"
                color: stasisProfile === "none" || stasisProfile === "default"
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                id: defLabel
                anchors.left: defIcon.right
                anchors.leftMargin: Config.appearance.spacing.small
                anchors.verticalCenter: parent.verticalCenter
                text: "Default"
                color: stasisProfile === "none" || stasisProfile === "default"
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurface
                font: Tokens.font.body.small
            }
        }
    }

    StyledRect {
        width: parent.width
        implicitHeight: gamingRow.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.full
        color: stasisProfile === "gaming"
            ? Colours.palette.m3primaryContainer
            : Colours.palette.m3surfaceContainer

        Behavior on color {
            CAnim {}
        }

        StateLayer {
            onClicked: {
                root.stasisProfile = "gaming";
                Quickshell.execDetached(["stasis", "profile", "gaming"]);
            }
        }

        Item {
            id: gamingRow
            anchors.centerIn: parent
            width: gamingIcon.width + Config.appearance.spacing.small + gamingLabel.implicitWidth
            implicitHeight: Math.max(gamingIcon.implicitHeight, gamingLabel.implicitHeight)

            MaterialIcon {
                id: gamingIcon
                anchors.verticalCenter: parent.verticalCenter
                text: "sports_esports"
                color: stasisProfile === "gaming"
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                id: gamingLabel
                anchors.left: gamingIcon.right
                anchors.leftMargin: Config.appearance.spacing.small
                anchors.verticalCenter: parent.verticalCenter
                text: "Gaming"
                color: stasisProfile === "gaming"
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurface
                font: Tokens.font.body.small
            }
        }
    }

    StyledRect {
        width: parent.width
        implicitHeight: videoRow.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.full
        color: stasisProfile === "video"
            ? Colours.palette.m3primaryContainer
            : Colours.palette.m3surfaceContainer

        Behavior on color {
            CAnim {}
        }

        StateLayer {
            onClicked: {
                root.stasisProfile = "video";
                Quickshell.execDetached(["stasis", "profile", "video"]);
            }
        }

        Item {
            id: videoRow
            anchors.centerIn: parent
            width: videoIcon.width + Config.appearance.spacing.small + videoLabel.implicitWidth
            implicitHeight: Math.max(videoIcon.implicitHeight, videoLabel.implicitHeight)

            MaterialIcon {
                id: videoIcon
                anchors.verticalCenter: parent.verticalCenter
                text: "movie"
                color: stasisProfile === "video"
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                id: videoLabel
                anchors.left: videoIcon.right
                anchors.leftMargin: Config.appearance.spacing.small
                anchors.verticalCenter: parent.verticalCenter
                text: "Video"
                color: stasisProfile === "video"
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurface
                font: Tokens.font.body.small
            }
        }
    }
}
