pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.components.controls
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property date selectedDate: new Date()
    property date currentDate: new Date()

    readonly property int currMonth: currentDate.getMonth()
    readonly property int currYear: currentDate.getFullYear()

    readonly property int padding: Config.appearance.padding.largeIncreased

    implicitWidth: 480
    implicitHeight: calLayout.implicitHeight + padding * 2

    function onWheel(event: WheelEvent): void {
        if (event.angleDelta.y > 0)
            currentDate = new Date(currYear, currMonth - 1, 1);
        else if (event.angleDelta.y < 0)
            currentDate = new Date(currYear, currMonth + 1, 1);
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => root.onWheel(wheel)
    }

    ColumnLayout {
        id: calLayout
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Config.appearance.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.appearance.spacing.small

            Item {
                implicitWidth: implicitHeight
                implicitHeight: prevIcon.implicitHeight + Config.appearance.padding.extraSmall * 2

                StateLayer {
                    radius: Config.appearance.rounding.full

                    onClicked: {
                        currentDate = new Date(currYear, currMonth - 1, 1);
                    }
                }

                MaterialIcon {
                    id: prevIcon
                    anchors.centerIn: parent
                    text: "chevron_left"
                    color: Colours.palette.m3tertiary
                    fontStyle: Tokens.font.icon.size(Config.appearance.font.body.medium.size).weight(Font.Bold).build()
}
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: monthText.implicitHeight + Config.appearance.padding.extraSmall * 2

                StateLayer {
                    anchors.fill: monthText
                    anchors.margins: -Config.appearance.padding.extraSmall
                    anchors.leftMargin: -Config.appearance.padding.medium
                    anchors.rightMargin: -Config.appearance.padding.medium
                    radius: Config.appearance.rounding.full
                    disabled: {
                        const now = new Date();
                        return currMonth === now.getMonth() && currYear === now.getFullYear();
                    }

                    onClicked: {
                        currentDate = new Date();
                        selectedDate = new Date();
                    }
                }

                StyledText {
                    id: monthText
                    anchors.centerIn: parent
                    text: grid.title
                    color: Colours.palette.m3primary
                    font.pointSize: Config.appearance.font.body.medium.size
                    font.weight: 500
                    font.capitalization: Font.Capitalize
                }
            }

            Item {
                implicitWidth: implicitHeight
                implicitHeight: nextIcon.implicitHeight + Config.appearance.padding.extraSmall * 2

                StateLayer {
                    radius: Config.appearance.rounding.full

                    onClicked: {
                        currentDate = new Date(currYear, currMonth + 1, 1);
                    }
                }

                MaterialIcon {
                    id: nextIcon
                    anchors.centerIn: parent
                    text: "chevron_right"
                    color: Colours.palette.m3tertiary
                    fontStyle: Tokens.font.icon.size(Config.appearance.font.body.medium.size).weight(Font.Bold).build()
}
            }

            IconTextButton {
                id: todayBtn
                text: "Today"
                icon: "today"
                type: IconTextButton.Tonal
                radius: Config.appearance.rounding.small

                onClicked: {
                    currentDate = new Date();
                    selectedDate = new Date();
                }
            }
        }

        DayOfWeekRow {
            Layout.fillWidth: true
            locale: grid.locale

            delegate: StyledText {
                required property var model
                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font.pointSize: Config.appearance.font.body.small.size
                font.weight: 500
                color: (model.day === 0 || model.day === 6) ? Colours.palette.m3secondary : Colours.palette.m3onSurfaceVariant
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: grid.implicitHeight

            MonthGrid {
                id: grid
                month: root.currMonth
                year: root.currYear
                anchors.fill: parent
                spacing: 3
                locale: Qt.locale()

                delegate: Item {
                    id: dayItem
                    required property var model
                    implicitWidth: implicitHeight
                    implicitHeight: text.implicitHeight + Config.appearance.padding.extraSmall * 2 + (hasEvents ? 8 : 0)

                    readonly property var eventsForDay: CalEvents.eventsForDate(new Date(model.year, model.month, model.day))
                    readonly property var dotColors: eventsForDay.slice(0, 3).map(e => e.color)
                    readonly property bool hasEvents: dotColors.length > 0

                    StateLayer {
                        anchors.fill: parent
                        radius: Config.appearance.rounding.full

                        onClicked: {
                            root.selectedDate = new Date(model.year, model.month, model.day);
                        }
                    }

                    StyledText {
                        id: text
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: hasEvents ? (parent.height - (text.implicitHeight + dotsRow.height + 2)) / 2 : (parent.height - text.implicitHeight) / 2
                        horizontalAlignment: Text.AlignHCenter
                        text: grid.locale.toString(dayItem.model.day)
                        color: {
                            const dayOfWeek = dayItem.model.date.getUTCDay();
                            if (dayOfWeek === 0 || dayOfWeek === 6)
                                return Colours.palette.m3secondary;
                            return Colours.palette.m3onSurfaceVariant;
                        }
                        opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                        font.pointSize: Config.appearance.font.body.medium.size
                        font.weight: 500
                    }

                    Row {
                        id: dotsRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: text.bottom
                        anchors.topMargin: 2
                        spacing: 2
                        visible: dayItem.hasEvents

                        Repeater {
                            model: dayItem.dotColors
                            delegate: Rectangle {
                                required property var modelData
                                width: 4
                                height: 4
                                radius: 2
                                color: modelData
                            }
                        }
                    }
                }
            }

            StyledRect {
                id: todayIndicator
                readonly property Item todayItem: grid.contentItem.children.find(c => c.model && c.model.today) ?? null
                property Item today

                onTodayItemChanged: {
                    if (todayItem)
                        today = todayItem;
                }

                x: today ? today.x + (today.width - implicitWidth) / 2 : 0
                y: today?.y ?? 0
                implicitWidth: today?.implicitWidth ?? 0
                implicitHeight: today?.implicitHeight ?? 0

                clip: true
                radius: Config.appearance.rounding.full
                color: Colours.palette.m3primary
                opacity: todayItem ? 1 : 0
                scale: todayItem ? 1 : 0.7

                Colouriser {
                    x: -todayIndicator.x
                    y: -todayIndicator.y
                    implicitWidth: grid.width
                    implicitHeight: grid.height
                    source: grid
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onPrimary
                }

                Behavior on opacity { Anim {} }
                Behavior on scale { Anim {} }

                Behavior on x {
                    Anim {
                        duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: TokenConfig.appearance.curves.expressiveDefaultSpatial
                    }
                }

                Behavior on y {
                    Anim {
                        duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: TokenConfig.appearance.curves.expressiveDefaultSpatial
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Qt.alpha(Colours.palette.m3outline, 0.2)
        }

        UpcomingEvents {
            id: upcomingEvents
            Layout.fillWidth: true
            selectedDate: root.selectedDate

            onAddEventRequested: addEventForm.active = true
        }

        AddEventForm {
            id: addEventForm
            Layout.fillWidth: true
            selectedDate: root.selectedDate

            onSaved: addEventForm.active = false
            onCancelled: addEventForm.active = false
        }
    }
}
