pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import CNS.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Audio")

    property bool outputDevicesExpanded: false
    property bool inputDevicesExpanded: false
    property bool appVolumesExpanded: false

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Output
        SliderRow {
            Layout.fillWidth: true
            first: true
            icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
            label: qsTr("Output")
            valueLabel: Math.round(value * 100) + "%"
            value: Audio.volume
            enabled: !Audio.muted
            onMoved: v => Audio.setVolume(v)
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Muted")
            checked: Audio.muted
            onToggled: Audio.setStreamMuted(Audio.sink, checked)
        }

        // Output devices toggle
        ConnectedRect {
            Layout.fillWidth: true
            first: false
            last: !root.outputDevicesExpanded

            implicitHeight: outputToggleLayout.implicitHeight + outputToggleLayout.anchors.margins * 2

            StateLayer {
                onClicked: root.outputDevicesExpanded = !root.outputDevicesExpanded
            }

            RowLayout {
                id: outputToggleLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: root.outputDevicesExpanded ? "expand_more" : "expand_less"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Output devices (%1)").arg(Audio.sinks.length)
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: !!Audio.sink?.description
                        text: Audio.sink?.description ?? ""
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Output devices list (animated drawer)
        Item {
            Layout.fillWidth: true
            clip: true
            implicitHeight: root.outputDevicesExpanded ? outputDevContent.implicitHeight : 0

            Behavior on implicitHeight {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            ColumnLayout {
                id: outputDevContent

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                AudioDeviceList {
                    Layout.fillWidth: true
                    nodes: Audio.sinks
                    currentId: Audio.sink?.id ?? -1
                    iconName: "speaker"
                    placeholderIcon: "speaker"
                    placeholderText: qsTr("No output devices")
                    onSelected: node => Audio.setAudioSink(node)
                }
            }
        }

        // Input
        SliderRow {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            icon: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
            label: qsTr("Input")
            valueLabel: Math.round(value * 100) + "%"
            value: Audio.sourceVolume
            enabled: !Audio.sourceMuted
            onMoved: v => Audio.setSourceVolume(v)
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Muted")
            checked: Audio.sourceMuted
            onToggled: Audio.setStreamMuted(Audio.source, checked)
        }

        // Input devices toggle
        ConnectedRect {
            Layout.fillWidth: true
            first: false
            last: !root.inputDevicesExpanded

            implicitHeight: inputToggleLayout.implicitHeight + inputToggleLayout.anchors.margins * 2

            StateLayer {
                onClicked: root.inputDevicesExpanded = !root.inputDevicesExpanded
            }

            RowLayout {
                id: inputToggleLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: root.inputDevicesExpanded ? "expand_more" : "expand_less"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Input devices (%1)").arg(Audio.sources.length)
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: !!Audio.source?.description
                        text: Audio.source?.description ?? ""
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Input devices list (animated drawer)
        Item {
            Layout.fillWidth: true
            clip: true
            implicitHeight: root.inputDevicesExpanded ? inputDevContent.implicitHeight : 0

            Behavior on implicitHeight {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            ColumnLayout {
                id: inputDevContent

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                AudioDeviceList {
                    Layout.fillWidth: true
                    nodes: Audio.sources
                    currentId: Audio.source?.id ?? -1
                    iconName: "mic"
                    placeholderIcon: "mic_off"
                    placeholderText: qsTr("No input devices")
                    onSelected: node => Audio.setAudioSource(node)
                }
            }
        }

        // App volumes toggle
        ConnectedRect {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            last: !root.appVolumesExpanded || Audio.streams.length === 0

            implicitHeight: appToggleLayout.implicitHeight + appToggleLayout.anchors.margins * 2

            StateLayer {
                onClicked: root.appVolumesExpanded = !root.appVolumesExpanded
            }

            RowLayout {
                id: appToggleLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "tune"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("App volumes")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Audio.streams.length === 0 ? qsTr("No apps playing audio") : Audio.streams.length === 1 ? qsTr("1 app playing audio") : qsTr("%1 apps playing audio").arg(Audio.streams.length)
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                        animate: true
                    }
                }

                MaterialIcon {
                    text: root.appVolumesExpanded ? "expand_more" : "expand_less"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                }
            }
        }

        // Per-app stream list (animated drawer)
        Item {
            Layout.fillWidth: true
            clip: true
            implicitHeight: root.appVolumesExpanded ? appStreamsContent.implicitHeight : 0

            Behavior on implicitHeight {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            ColumnLayout {
                id: appStreamsContent

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Tokens.spacing.extraSmall / 2

                Repeater {
                    model: ScriptModel {
                        values: [...Audio.streams]
                    }

                    delegate: SliderRow {
                        required property PwNode modelData
                        required property int index

                        Layout.fillWidth: true
                        first: false
                        last: index === Audio.streams.length - 1

                        icon: Icons.getVolumeIcon(modelData?.audio?.volume ?? 0, modelData?.audio?.muted ?? false)
                        label: Audio.getStreamName(modelData)
                        valueLabel: Math.round(value * 100) + "%"
                        value: modelData?.audio?.volume ?? 0
                        enabled: !modelData?.audio?.muted
                        onMoved: v => Audio.setStreamVolume(modelData, v)
                    }
                }
            }
        }

    }
}
