pragma ComponentBehavior: Bound

import qs.components
import qs.services
import CNS.Config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    readonly property var upcomingEvents: CalEvents.upcoming(3)

    implicitHeight: eventsLayout.implicitHeight + Config.appearance.padding.medium * 2
    implicitWidth: eventsLayout.implicitWidth + Config.appearance.padding.medium * 2
    radius: Config.appearance.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: eventsLayout
        anchors.fill: parent
        anchors.margins: Config.appearance.padding.medium
        spacing: Config.appearance.spacing.extraSmall

        StyledText {
            Layout.leftMargin: Config.appearance.padding.extraSmall
            text: "Upcoming"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.body.small.size
            font.weight: 500
        }

        Repeater {
            model: root.upcomingEvents

            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Config.appearance.spacing.small

                Rectangle {
                    Layout.preferredWidth: 3
                    Layout.preferredHeight: eventText.implicitHeight
                    radius: 1.5
                    color: modelData.color
                }

                StyledText {
                    id: eventText
                    Layout.fillWidth: true
                    text: modelData.title
                    color: Colours.palette.m3onSurface
                    font.pointSize: Config.appearance.font.body.small.size
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    text: {
                        if (modelData.allDay) return "All day";
                        return modelData.startTime;
                    }
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Config.appearance.font.body.small.size
                    visible: modelData.startTime || modelData.allDay
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: "No upcoming events"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.body.small.size
            visible: root.upcomingEvents.length === 0
        }
    }
}
