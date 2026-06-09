pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
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

    implicitWidth: contentRow.implicitWidth + Appearance.padding.md * 2
    implicitHeight: contentRow.implicitHeight + Appearance.padding.md * 2

    anchors.centerIn: parent

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Appearance.spacing.md

        RowLayout {
            id: timeRow
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: root.timeComponents[0]
                color: Colours.palette.m3secondary
                font.pointSize: Appearance.font.size.headlineLarge
                font.family: Appearance.font.family.clock
                font.weight: 600
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.bottomMargin: -font.pointSize * 0.15
                text: ":"
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.headlineLarge * 0.9
                font.family: Appearance.font.family.clock
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: root.timeComponents[1]
                color: Colours.palette.m3secondary
                font.pointSize: Appearance.font.size.headlineLarge
                font.family: Appearance.font.family.clock
                font.weight: 600
            }

            Loader {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Appearance.spacing.sm

                asynchronous: true
                active: Config.services.useTwelveHourClock
                visible: active

                sourceComponent: StyledText {
                    text: root.timeComponents[2] ?? ""
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.titleMedium
                    font.family: Appearance.font.family.clock
                    font.weight: 600
                }
            }
        }

        StyledText {
            id: dateLabel
            Layout.alignment: Qt.AlignVCenter
            text: root.dateText
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.titleMedium
            font.weight: 500
        }
    }
}
