pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import CNS.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

ColumnLayout {
    id: root

    property string role: ""
    property bool pinned: false
    property bool expanded: false
    property var roleStreams: []

    spacing: Tokens.spacing.extraSmall / 2
    Layout.fillWidth: true

    readonly property bool hasStreams: root.roleStreams.length > 0
    readonly property bool _showToggle: root.pinned || root.hasStreams
    readonly property bool _showExpanded: root.hasStreams && root.expanded

    readonly property string roleIcon: {
        const icons = {
            "Notification": "notifications",
            "Communication": "call",
            "Game": "sports_esports",
            "Music": "music_note",
            "Alarm": "alarm",
            "System": "settings",
        };
        return icons[root.role] || "volume_up";
    }

    readonly property real masterVolume: {
        if (root.role === "Notification")
            return Audio.notificationVolume;
        const s = root.roleStreams[0];
        return s?.audio?.volume ?? 0;
    }

    readonly property bool masterMuted: {
        if (root.role === "Notification")
            return Audio.notificationMuted;
        const s = root.roleStreams[0];
        return !!s?.audio?.muted;
    }

    // Master slider pill
    ConnectedRect {
        Layout.fillWidth: true
        first: true
        last: !root._showToggle && !root._showExpanded

        implicitHeight: masterLayout.implicitHeight + masterLayout.anchors.margins * 2

        RowLayout {
            id: masterLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: root.roleIcon
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.icon.medium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: root.role || qsTr("Audio")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                        text: Math.round(root.masterVolume * 100) + "%"
                    }
                }

                CustomMouseArea {
                    Layout.fillWidth: true
                    implicitHeight: Tokens.padding.medium * 2

                    StyledSlider {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        radius: Tokens.rounding.small
                        value: root.masterVolume
                        enabled: root.pinned || (!root.masterMuted && root.hasStreams)
                        onInteraction: v => {
                            if (root.role === "Notification")
                                Audio.setNotificationVolume(v);
                            else
                                Audio.setRoleVolume(root.role, v);
                        }
                    }
                }
            }

            Item {
                implicitWidth: chevronIcon.implicitWidth
                implicitHeight: chevronIcon.implicitHeight

                MaterialIcon {
                    id: chevronIcon
                    anchors.centerIn: parent
                    text: "expand_more"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                    visible: root.hasStreams
                    rotation: root.expanded ? 180 : 0

                    Behavior on rotation {
                        Anim { type: Anim.StandardSmall }
                    }
                }

                StateLayer {
                    anchors.fill: parent
                    radius: Tokens.rounding.full
                    onClicked: {
                        if (root.hasStreams)
                            root.expanded = !root.expanded;
                    }
                }
            }
        }
    }

    // Mute toggle
    ToggleRow {
        Layout.fillWidth: true
        visible: root._showToggle
        text: qsTr("Muted")

        first: false
        last: !root._showExpanded

        checked: root.masterMuted
        onToggled: {
            if (root.role === "Notification")
                Audio.setNotificationMuted(checked);
            else
                Audio.setRoleMuted(root.role, checked);
        }
    }

    // Expanded per-stream sliders — direct children of root ColumnLayout
    // forming a connected pill group with master and mute toggle
    Repeater {
        model: root.roleStreams

        delegate: SliderRow {
            required property PwNode modelData
            required property int index

            visible: root._showExpanded
            Layout.fillWidth: true
            first: false
            last: index === root.roleStreams.length - 1

            icon: Icons.getVolumeIcon(modelData?.audio?.volume ?? 0, modelData?.audio?.muted ?? false)
            label: Audio.getStreamName(modelData)
            valueLabel: Math.round(value * 100) + "%"
            value: modelData?.audio?.volume ?? 0
            enabled: !modelData?.audio?.muted
            onMoved: v => {
                Audio.setStreamVolume(modelData, v);
                if (root.role === "Notification")
                    Audio.notificationVolume = v;
            }
        }
    }
}
