pragma ComponentBehavior: Bound

import qs.components
import qs.services
import CNS.Config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    readonly property var upcomingEvents: CalEvents.upcoming(3)

    implicitHeight: eventsLayout.implicitHeight + Tokens.padding.medium * 2
    implicitWidth: eventsLayout.implicitWidth + Tokens.padding.medium * 2
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: eventsLayout
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.leftMargin: Tokens.padding.extraSmall
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
                spacing: Tokens.spacing.small

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
