pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Caelestia.Config
import QtQuick

StyledRect {
    id: root

    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Config.appearance.padding.medium : Config.appearance.padding.small

    implicitWidth: TokenConfig.sizes.bar.innerWidth
    implicitHeight: layout.implicitHeight + root.padding * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Config.appearance.rounding.full

    Column {
        id: layout
        anchors.centerIn: parent
        spacing: Config.appearance.spacing.small

        Loader {
            anchors.horizontalCenter: parent.horizontalCenter

            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
            }
        }
        
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            visible: Config.bar.clock.showDate

            horizontalAlignment: StyledText.AlignHCenter
            text: Time.format("ddd\nd")
            font.pointSize: Config.appearance.font.body.small.size
            font.family: Config.appearance.font.mono.family
            color: root.colour
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Config.bar.clock.showDate
            height: visible ? 1 : 0
            
            width: parent.width * 0.8
            color: root.colour
            opacity: 0.2
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            horizontalAlignment: StyledText.AlignHCenter
            text: Time.format(Config.services.useTwelveHourClock ? "hh\nmm\nA" : "hh\nmm")
            font.pointSize: Config.appearance.font.body.small.size
            font.family: Config.appearance.font.mono.family
            color: root.colour
        }
    }
}