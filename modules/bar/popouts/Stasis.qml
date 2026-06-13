pragma ComponentBehavior: Bound

import qs.components
import qs.services
import CNS.Config
import Quickshell
import Quickshell.Io
import QtQuick

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
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: pollRunner.running = true

    StyledText {
        text: stasisState === "manually_inhibited" ? "Paused" : "Default"
        font.pointSize: Config.appearance.font.label.large.size
        font.weight: 500
    }

    StyledRect {
        width: parent.width
        implicitHeight: pauseLabel.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.large
        color: stasisState === "manually_inhibited" ? Colours.palette.m3tertiary : Colours.palette.m3primary

        StateLayer {
            onClicked: {
                Quickshell.execDetached(["stasis", "toggle-inhibit"]);
            }
        }

        StyledText {
            id: pauseLabel
            anchors.centerIn: parent
            text: stasisState === "manually_inhibited" ? "Resume" : "Pause"
            color: stasisState === "manually_inhibited" ? Colours.palette.m3onTertiary : Colours.palette.m3onPrimary
            font.pointSize: Config.appearance.font.label.large.size
        }
    }

    StyledText {
        text: "Profiles"
        font.pointSize: Config.appearance.font.label.large.size
        font.weight: 500
    }

    StyledRect {
        width: parent.width
        implicitHeight: defLabel.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.large
        color: stasisProfile === "none" || stasisProfile === "default"
            ? Colours.palette.m3primaryContainer
            : Colours.tPalette.m3surfaceContainer

        StateLayer {
            onClicked: {
                Quickshell.execDetached(["stasis", "profile", "default"]);
            }
        }

        StyledText {
            id: defLabel
            anchors.centerIn: parent
            text: "Default"
            color: stasisProfile === "none" || stasisProfile === "default"
                ? Colours.palette.m3onPrimaryContainer
                : Colours.palette.m3onSurface
            font.pointSize: Config.appearance.font.label.large.size
        }
    }

    StyledRect {
        width: parent.width
        implicitHeight: gamingLabel.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.large
        color: stasisProfile === "gaming"
            ? Colours.palette.m3primaryContainer
            : Colours.tPalette.m3surfaceContainer

        StateLayer {
            onClicked: {
                Quickshell.execDetached(["stasis", "profile", "gaming"]);
            }
        }

        StyledText {
            id: gamingLabel
            anchors.centerIn: parent
            text: "Gaming"
            color: stasisProfile === "gaming"
                ? Colours.palette.m3onPrimaryContainer
                : Colours.palette.m3onSurface
            font.pointSize: Config.appearance.font.label.large.size
        }
    }

    StyledRect {
        width: parent.width
        implicitHeight: videoLabel.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.large
        color: stasisProfile === "video"
            ? Colours.palette.m3primaryContainer
            : Colours.tPalette.m3surfaceContainer

        StateLayer {
            onClicked: {
                Quickshell.execDetached(["stasis", "profile", "video"]);
            }
        }

        StyledText {
            id: videoLabel
            anchors.centerIn: parent
            text: "Video"
            color: stasisProfile === "video"
                ? Colours.palette.m3onPrimaryContainer
                : Colours.palette.m3onSurface
            font.pointSize: Config.appearance.font.label.large.size
        }
    }
}
