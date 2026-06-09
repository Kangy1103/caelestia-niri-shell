pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property list<string> timeComponents: Time.format(Config.services.useTwelveHourClock ? "hh:mm:A" : "hh:mm").split(":")
    readonly property string dateText: {
        const now = new Date();
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return `${days[now.getDay()]}, ${months[now.getMonth()]} ${now.getDate()}`;
    }

    implicitWidth: contentRow.implicitWidth + Config.appearance.padding.medium * 2
    implicitHeight: contentRow.implicitHeight + Config.appearance.padding.medium * 2

    anchors.centerIn: parent

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Config.appearance.spacing.medium

        RowLayout {
            id: timeRow
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: root.timeComponents[0]
                color: Colours.palette.m3secondary
                font.pointSize: Config.appearance.font.headline.large.size
                font.family: Config.appearance.font.clock
                font.weight: 600
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.bottomMargin: -font.pointSize * 0.15
                text: ":"
                color: Colours.palette.m3primary
                font.pointSize: Config.appearance.font.headline.large.size * 0.9
                font.family: Config.appearance.font.clock
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: root.timeComponents[1]
                color: Colours.palette.m3secondary
                font.pointSize: Config.appearance.font.headline.large.size
                font.family: Config.appearance.font.clock
                font.weight: 600
            }

            Loader {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Config.appearance.spacing.small

                asynchronous: true
                active: Config.services.useTwelveHourClock
                visible: active

                sourceComponent: StyledText {
                    text: root.timeComponents[2] ?? ""
                    color: Colours.palette.m3primary
                    font.pointSize: Config.appearance.font.title.medium.size
                    font.family: Config.appearance.font.clock
                    font.weight: 600
                }
            }
        }

        StyledText {
            id: dateLabel
            Layout.alignment: Qt.AlignVCenter
            text: root.dateText
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.title.medium.size
            font.weight: 500
        }
    }
}
