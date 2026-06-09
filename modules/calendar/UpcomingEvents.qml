pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property date selectedDate

    readonly property var events: CalEvents.list.filter(e => {
        const d = e.startDate;
        return d.getFullYear() === selectedDate.getFullYear() && d.getMonth() === selectedDate.getMonth() && d.getDate() === selectedDate.getDate();
    }).sort((a, b) => {
        if (a.allDay && !b.allDay) return -1;
        if (!a.allDay && b.allDay) return 1;
        return a.startTime.localeCompare(b.startTime);
    })

    signal addEventRequested()

    implicitHeight: contentLayout.implicitHeight + Appearance.padding.md * 2
    implicitWidth: contentLayout.implicitWidth + Appearance.padding.md * 2

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: Appearance.spacing.sm

        StyledText {
            Layout.fillWidth: true
            text: "Events for " + root.selectedDate.toLocaleDateString(Qt.locale(), "MMM d")
            color: Colours.palette.m3onSurface
            font.pointSize: Appearance.font.size.bodySmall
            font.weight: 500
            horizontalAlignment: Text.AlignLeft
        }

        Repeater {
            model: root.events

            delegate: StyledRect {
                required property var modelData
                id: eventCard
                Layout.fillWidth: true
                implicitHeight: eventLayout.implicitHeight + Appearance.padding.sm * 2
                radius: Appearance.rounding.small
                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                clip: true

                property bool expanded: false

                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.expanded = !parent.expanded
                }

                RowLayout {
                    id: eventLayout
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.sm
                    spacing: Appearance.spacing.sm

                    Rectangle {
                        Layout.preferredWidth: 3
                        Layout.fillHeight: true
                        radius: 1.5
                        color: modelData.color || Config.dashboard.calendarColors.blue
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.title
                            color: Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.bodySmall
                            font.weight: 500
                            elide: Text.ElideRight
                            maximumLineCount: eventCard.expanded ? 0 : 1
                            wrapMode: eventCard.expanded ? Text.WordWrap : Text.NoWrap
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                if (modelData.allDay) return "All day";
                                let times = modelData.startTime;
                                if (modelData.endTime) times += " - " + modelData.endTime;
                                return times;
                            }
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Appearance.font.size.bodySmall
                            font.weight: 400
                            visible: modelData.allDay || modelData.startTime
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: deleteBtn.implicitHeight + Appearance.padding.xs
                            visible: eventCard.expanded

                            IconButton {
                                id: deleteBtn
                                anchors.right: parent.right
                                icon: "delete"
                                inactiveColour: Qt.alpha(Colours.palette.m3error, 0.1)
                                inactiveOnColour: Colours.palette.m3error
                                radius: Appearance.rounding.small

                                onClicked: CalEvents.removeEvent(modelData.id)
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: "No events"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.bodySmall
            font.weight: 400
            horizontalAlignment: Text.AlignHCenter
            visible: root.events.length === 0
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: addBtn.implicitHeight + 2

            IconTextButton {
                id: addBtn
                anchors.left: parent.left
                anchors.right: parent.right
                icon: "add"
                text: "Add event"
                type: IconTextButton.Tonal
                radius: Appearance.rounding.small

                onClicked: root.addEventRequested()
            }
        }
    }
}
