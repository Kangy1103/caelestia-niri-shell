pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Column {
    id: root

    spacing: Appearance.spacing.lg
    width: 200
    topPadding: Appearance.padding.xs

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
        font.pointSize: Appearance.font.size.labelLarge
        font.weight: 500
    }

    StyledRect {
        width: parent.width
        implicitHeight: pauseLabel.implicitHeight + Appearance.padding.sm * 2
        radius: Appearance.rounding.normal
        color: stasisState === "manually_inhibited" ? Colours.palette.m3tertiary : Colours.palette.m3primary

        StateLayer {
            function onClicked(): void {
                Quickshell.execDetached(["stasis", "toggle-inhibit"]);
            }
        }

        StyledText {
            id: pauseLabel
            anchors.centerIn: parent
            text: stasisState === "manually_inhibited" ? "Resume" : "Pause"
            color: stasisState === "manually_inhibited" ? Colours.palette.m3onTertiary : Colours.palette.m3onPrimary
            font.pointSize: Appearance.font.size.labelLarge
        }
    }

    StyledText {
        text: "Profiles"
        font.pointSize: Appearance.font.size.labelLarge
        font.weight: 500
    }

    StyledRect {
        width: parent.width
        implicitHeight: defLabel.implicitHeight + Appearance.padding.sm * 2
        radius: Appearance.rounding.normal
        color: stasisProfile === "none" || stasisProfile === "default"
            ? Colours.palette.m3primaryContainer
            : Colours.tPalette.m3surfaceContainer

        StateLayer {
            function onClicked(): void {
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
            font.pointSize: Appearance.font.size.labelLarge
        }
    }

    StyledRect {
        width: parent.width
        implicitHeight: gamingLabel.implicitHeight + Appearance.padding.sm * 2
        radius: Appearance.rounding.normal
        color: stasisProfile === "gaming"
            ? Colours.palette.m3primaryContainer
            : Colours.tPalette.m3surfaceContainer

        StateLayer {
            function onClicked(): void {
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
            font.pointSize: Appearance.font.size.labelLarge
        }
    }

    StyledRect {
        width: parent.width
        implicitHeight: videoLabel.implicitHeight + Appearance.padding.sm * 2
        radius: Appearance.rounding.normal
        color: stasisProfile === "video"
            ? Colours.palette.m3primaryContainer
            : Colours.tPalette.m3surfaceContainer

        StateLayer {
            function onClicked(): void {
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
            font.pointSize: Appearance.font.size.labelLarge
        }
    }
}
