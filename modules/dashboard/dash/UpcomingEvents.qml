pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    readonly property var upcomingEvents: CalEvents.upcoming(3)

    implicitHeight: eventsLayout.implicitHeight + Appearance.padding.md * 2
    implicitWidth: eventsLayout.implicitWidth + Appearance.padding.md * 2
    radius: Appearance.rounding.normal
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: eventsLayout
        anchors.fill: parent
        anchors.margins: Appearance.padding.md
        spacing: Appearance.spacing.xs

        StyledText {
            Layout.leftMargin: Appearance.padding.xs
            text: "Upcoming"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.bodySmall
            font.weight: 500
        }

        Repeater {
            model: root.upcomingEvents

            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Appearance.spacing.sm

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
                    font.pointSize: Appearance.font.size.bodySmall
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    text: {
                        if (modelData.allDay) return "All day";
                        return modelData.startTime;
                    }
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.bodySmall
                    visible: modelData.startTime || modelData.allDay
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: "No upcoming events"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.bodySmall
            visible: root.upcomingEvents.length === 0
        }
    }
}
