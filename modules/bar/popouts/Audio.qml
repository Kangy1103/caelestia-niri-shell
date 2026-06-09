pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    required property var wrapper

    implicitWidth: layout.implicitWidth + Config.appearance.padding.medium * 2
    implicitHeight: layout.implicitHeight + Config.appearance.padding.medium * 2

    ButtonGroup {
        id: sinks
    }

    ButtonGroup {
        id: sources
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        StyledText {
            Layout.bottomMargin: Config.appearance.spacing.small / 2
            text: qsTr("Output device")
            font.weight: 500
        }

        Repeater {
            model: Audio.sinks

            StyledRadioButton {
                id: control

                required property PwNode modelData

                ButtonGroup.group: sinks
                checked: Audio.sink?.id === modelData.id
                onClicked: Audio.setAudioSink(modelData)
                text: modelData.description
            }
        }

        StyledText {
            Layout.topMargin: Config.appearance.spacing.large
            Layout.bottomMargin: Config.appearance.spacing.small / 2
            text: qsTr("Input device")
            font.weight: 500
        }

        Repeater {
            model: Audio.sources

            StyledRadioButton {
                required property PwNode modelData

                ButtonGroup.group: sources
                checked: Audio.source?.id === modelData.id
                onClicked: Audio.setAudioSource(modelData)
                text: modelData.description
            }
        }

        StyledText {
            Layout.topMargin: Config.appearance.spacing.large
            Layout.bottomMargin: Config.appearance.spacing.small / 2
            text: qsTr("Volume (%1)").arg(Audio.muted ? qsTr("Muted") : `${Math.round(Audio.volume * 100)}%`)
            font.weight: 500
        }

        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: Config.appearance.padding.medium * 3

            onWheel: event => {
                if (event.angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (event.angleDelta.y < 0)
                    Audio.decrementVolume();
            }

            StyledSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: parent.implicitHeight

                value: Audio.volume
                onMoved: Audio.setVolume(value)

                Behavior on value {
                    Anim {}
                }
            }
        }

        StyledRect {
            Layout.topMargin: Config.appearance.spacing.large
            visible: Config.general.apps.audio.length > 0

            implicitWidth: expandBtn.implicitWidth + Config.appearance.padding.medium * 2
            implicitHeight: expandBtn.implicitHeight + Config.appearance.padding.extraSmall

            radius: Config.appearance.rounding.large
            color: Colours.palette.m3primaryContainer

            StateLayer {
                color: Colours.palette.m3onPrimaryContainer

                function onClicked(): void {
                    root.wrapper.hasCurrent = false;
                    Quickshell.execDetached(["app2unit", "--", ...Config.general.apps.audio]);
                }
            }

            RowLayout {
                id: expandBtn

                anchors.centerIn: parent
                spacing: Config.appearance.spacing.small

                StyledText {
                    Layout.leftMargin: Config.appearance.padding.small
                    text: qsTr("Open settings")
                    color: Colours.palette.m3onPrimaryContainer
                }

                MaterialIcon {
                    text: "chevron_right"
                    color: Colours.palette.m3onPrimaryContainer
                    fontStyle: Tokens.font.icon.size(Config.appearance.font.title.medium.size).build()
}
            }
        }
    }
}
