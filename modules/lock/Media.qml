pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var lock

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: layout.implicitHeight

    Image {
        anchors.fill: parent
        source: Players.active?.trackArtUrl ?? ""

        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: width
        sourceSize.height: height

        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            Anim {
                duration: Config.appearance.anim.durations.extraLarge
            }
        }

        StyledRect {
            anchors.fill: parent
            color: Colours.palette.m3surface
            opacity: 0.7
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Config.appearance.padding.largeIncreased

        StyledText {
            Layout.topMargin: Config.appearance.padding.largeIncreased
            Layout.bottomMargin: Config.appearance.spacing.largeIncreased
            text: qsTr("Now playing")
            color: Colours.palette.m3onSurfaceVariant
            font.family: Config.appearance.font.mono.family
            font.weight: 500
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: Players.active?.trackArtist ?? qsTr("No media")
            color: Colours.palette.m3primary
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Config.appearance.font.title.medium.size
            font.family: Config.appearance.font.mono.family
            font.weight: 600
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: Players.active?.trackTitle ?? qsTr("No media")
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Config.appearance.font.body.large.size
            font.family: Config.appearance.font.mono.family
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Config.appearance.spacing.extraExtraLarge * 1.2
            Layout.bottomMargin: Config.appearance.padding.largeIncreased

            spacing: Config.appearance.spacing.extraExtraLarge

            PlayerControl {
                icon: "skip_previous"

                function onClicked(): void {
                    if (Players.active?.canGoPrevious)
                        Players.active.previous();
                }
            }

            PlayerControl {
                animate: true
                icon: active ? "pause" : "play_arrow"
                colour: "Primary"
                level: active ? 2 : 1
                active: Players.active?.isPlaying ?? false

                function onClicked(): void {
                    if (Players.active?.canTogglePlaying)
                        Players.active.togglePlaying();
                }
            }

            PlayerControl {
                icon: "skip_next"

                function onClicked(): void {
                    if (Players.active?.canGoNext)
                        Players.active.next();
                }
            }
        }
    }

    component PlayerControl: StyledRect {
        id: control

        property alias animate: controlIcon.animate
        property alias icon: controlIcon.text
        property bool active
        property string colour: "Secondary"
        property int level: 1

        function onClicked(): void {
        }

        Layout.preferredWidth: implicitWidth + (controlState.pressed ? Config.appearance.padding.medium * 2 : active ? Config.appearance.padding.extraSmall * 2 : 0)
        implicitWidth: controlIcon.implicitWidth + Config.appearance.padding.largeIncreased * 2
        implicitHeight: controlIcon.implicitHeight + Config.appearance.padding.medium * 2

        color: active ? Colours.palette[`m3${colour.toLowerCase()}`] : Colours.palette[`m3${colour.toLowerCase()}Container`]
        radius: active || controlState.pressed ? Config.appearance.rounding.large : Math.min(implicitWidth, implicitHeight) / 2 * Math.min(1, Config.appearance.rounding.scale)

        Elevation {
            anchors.fill: parent
            radius: parent.radius
            z: -1
            level: controlState.containsMouse && !controlState.pressed ? control.level + 1 : control.level
        }

        StateLayer {
            id: controlState

            color: control.active ? Colours.palette[`m3on${control.colour}`] : Colours.palette[`m3on${control.colour}Container`]

            function onClicked(): void {
                control.onClicked();
            }
        }

        MaterialIcon {
            id: controlIcon

            anchors.centerIn: parent
            color: control.active ? Colours.palette[`m3on${control.colour}`] : Colours.palette[`m3on${control.colour}Container`]
            fontStyle: Tokens.font.icon.size(Config.appearance.font.title.medium.size).build()
fill: control.active ? 1 : 0

            Behavior on fill {
                Anim {}
            }
        }

        Behavior on Layout.preferredWidth {
            Anim {
                duration: Config.appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: TokenConfig.appearance.curves.expressiveFastSpatial
            }
        }

        Behavior on radius {
            Anim {
                duration: Config.appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: TokenConfig.appearance.curves.expressiveFastSpatial
            }
        }
    }
}
