// Created by Kangy w/ OpenCode AI Assistance
// Based on Noctalia Shell (legacy-v4) WorkspacePill.qml
// Version: 0.4.0-20260603

pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    id: pillContainer

    required property var workspace
    required property bool isVertical
    required property real baseDimensionRatio
    required property real capsuleHeight
    required property real barHeight
    required property string labelMode
    required property int fontWeight
    required property int characterCount
    required property real textRatio
    required property bool showLabelsOnlyWhenOccupied
    required property string focusedColor
    required property string occupiedColor
    required property string emptyColor
    required property real masterProgress
    required property bool effectsActive
    required property color effectColor
    required property var getWorkspaceWidth
    required property var getWorkspaceHeight

    readonly property real fixedDimension: Math.round(capsuleHeight * baseDimensionRatio)

    property real pillWidth: isVertical ? fixedDimension : getWorkspaceWidth(workspace, false)
    property real pillHeight: isVertical ? getWorkspaceHeight(workspace, false) : fixedDimension

    width: isVertical ? barHeight : getWorkspaceWidth(workspace, false)
    height: isVertical ? getWorkspaceHeight(workspace, false) : barHeight
    implicitHeight: height

    states: [
        State {
            name: "active"
            when: workspace.isActive
            PropertyChanges {
                target: pillContainer
                width: isVertical ? barHeight : getWorkspaceWidth(workspace, true)
                height: isVertical ? getWorkspaceHeight(workspace, true) : barHeight
                pillWidth: isVertical ? fixedDimension : getWorkspaceWidth(workspace, true)
                pillHeight: isVertical ? getWorkspaceHeight(workspace, true) : fixedDimension
            }
        }
    ]

    transitions: [
        Transition {
            from: "inactive"
            to: "active"
            NumberAnimation {
                properties: isVertical ? "height,pillHeight" : "width,pillWidth"
                duration: Appearance.anim.durations.normal
                easing.type: Easing.OutBack
            }
        },
        Transition {
            from: "active"
            to: "inactive"
            NumberAnimation {
                properties: isVertical ? "height,pillHeight" : "width,pillWidth"
                duration: Appearance.anim.durations.normal
                easing.type: Easing.OutBack
            }
        }
    ]

    Rectangle {
        id: pill
        width: pillContainer.pillWidth
        height: pillContainer.pillHeight
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        radius: Appearance.rounding.full
        z: 0

        color: {
            if (pillMouseArea.containsMouse)
                return Colours.layer(Colours.palette.m3onSurface, 0.12);
            if (workspace.isFocused)
                return Colours.palette.m3primary;
            if (workspace.isUrgent)
                return Colours.palette.m3error;
            if (workspace.isOccupied)
                return Colours.layer(Colours.palette.m3surfaceContainerHigh, 2);
            return Qt.alpha(Colours.palette.m3outlineVariant, 0.3);
        }

        Loader {
            active: (labelMode !== "none") && (!showLabelsOnlyWhenOccupied || workspace.isOccupied || workspace.isFocused)
            anchors.fill: parent
            sourceComponent: Component {
                StyledText {
                    text: {
                        if (workspace.name && workspace.name.length > 0) {
                            if (labelMode === "name")
                                return workspace.name.substring(0, characterCount);
                            if (labelMode === "index+name") {
                                if (isVertical)
                                    return workspace.idx.toString() + workspace.name.substring(0, 1);
                                return workspace.idx.toString() + " " + workspace.name.substring(0, characterCount);
                            }
                        }
                        return workspace.idx.toString();
                    }
                    font.pointSize: Math.max(1, (isVertical ? pillContainer.pillWidth : pillContainer.pillHeight) * textRatio)
                    font.weight: fontWeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    color: {
                        if (pillMouseArea.containsMouse)
                            return Colours.palette.m3onSurface;
                        if (workspace.isFocused)
                            return Colours.palette.m3onPrimary;
                        if (workspace.isUrgent)
                            return Colours.palette.m3onError;
                        if (workspace.isOccupied)
                            return Colours.palette.m3onSurface;
                        return Colours.layer(Colours.palette.m3outlineVariant, 2);
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.anim.durations.fast
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.OutBack
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Appearance.anim.durations.fast
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.anim.durations.fast
                easing.type: Easing.InOutCubic
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.OutBack
            }
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.OutBack
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.OutBack
        }
    }
    Behavior on pillWidth {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.OutBack
        }
    }
    Behavior on pillHeight {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.OutBack
        }
    }

    MouseArea {
        id: pillMouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            Niri.switchToWorkspaceByNumber(workspace.idx);
        }
    }

    Rectangle {
        id: pillBurst
        anchors.centerIn: pill
        width: pillContainer.pillWidth + 18 * masterProgress
        height: pillContainer.pillHeight + 18 * masterProgress
        radius: width / 2
        color: "transparent"
        border.color: effectColor
        border.width: Math.max(1, Math.round((2 + 6 * (1.0 - masterProgress))))
        opacity: effectsActive && workspace.isFocused ? (1.0 - masterProgress) * 0.7 : 0
        visible: effectsActive && workspace.isFocused
        z: 1
    }
}
