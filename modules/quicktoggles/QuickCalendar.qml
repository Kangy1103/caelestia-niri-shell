pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var visibilities

    property date selectedDate: new Date()
    property date currentDate: new Date()

    signal monthTitleClicked()

    implicitHeight: calendarLayout.implicitHeight + Appearance.padding.md * 2
    implicitWidth: calendarLayout.implicitWidth + Appearance.padding.md * 2

    readonly property int currMonth: currentDate.getMonth()
    readonly property int currYear: currentDate.getFullYear()

    function onWheel(event: WheelEvent): void {
        if (event.angleDelta.y > 0)
            currentDate = new Date(currYear, currMonth - 1, 1);
        else if (event.angleDelta.y < 0)
            currentDate = new Date(currYear, currMonth + 1, 1);
    }

    // Detect mouse wheel on the calendar to change months
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => root.onWheel(wheel)
    }

    ColumnLayout {
        id: calendarLayout
        anchors.fill: parent
        spacing: Appearance.spacing.xs

        RowLayout {
            id: monthNav
            Layout.fillWidth: true
            spacing: Appearance.spacing.sm

            Item {
                implicitWidth: implicitHeight
                implicitHeight: prevIcon.implicitHeight + Appearance.padding.xs * 2

                StateLayer {
                    radius: Appearance.rounding.full

                    function onClicked(): void {
                        currentDate = new Date(currYear, currMonth - 1, 1);
                    }
                }

                MaterialIcon {
                    id: prevIcon
                    anchors.centerIn: parent
                    text: "chevron_left"
                    color: Colours.palette.m3tertiary
                    font.pointSize: Appearance.font.size.bodySmall
                    font.weight: 700
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: monthText.implicitHeight + Appearance.padding.xs * 2

                StateLayer {
                    anchors.fill: monthText
                    anchors.margins: -Appearance.padding.xs
                    anchors.leftMargin: -Appearance.padding.md
                    anchors.rightMargin: -Appearance.padding.md
                    radius: Appearance.rounding.full

                    function onClicked(): void {
                        root.monthTitleClicked();
                    }
                }

                StyledText {
                    id: monthText
                    anchors.centerIn: parent
                    text: grid.title
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.bodySmall
                    font.weight: 500
                    font.capitalization: Font.Capitalize
                }
            }

            Item {
                implicitWidth: implicitHeight
                implicitHeight: nextIcon.implicitHeight + Appearance.padding.xs * 2

                StateLayer {
                    radius: Appearance.rounding.full

                    function onClicked(): void {
                        currentDate = new Date(currYear, currMonth + 1, 1);
                    }
                }

                MaterialIcon {
                    id: nextIcon
                    anchors.centerIn: parent
                    text: "chevron_right"
                    color: Colours.palette.m3tertiary
                    font.pointSize: Appearance.font.size.bodySmall
                    font.weight: 700
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
                font.pointSize: Appearance.font.size.bodySmall
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
                spacing: 2
                locale: Qt.locale()

                delegate: Item {
                    id: dayItem
                    required property var model
                    implicitWidth: implicitHeight
                    implicitHeight: 34

                    readonly property string dateKey: `${model.year}-${String(model.month + 1).padStart(2, '0')}-${String(model.day).padStart(2, '0')}`
                    readonly property var eventsForDay: CalEvents.eventsForDate(new Date(model.year, model.month, model.day))
                    readonly property var dotColors: eventsForDay.slice(0, 3).map(e => e.color)
                    readonly property bool hasEvents: dotColors.length > 0
                    readonly property bool isSelected: model.day === root.selectedDate.getDate() && model.month === root.selectedDate.getMonth() && model.year === root.selectedDate.getFullYear()

                    StateLayer {
                        anchors.fill: parent
                        radius: Appearance.rounding.full

                        function onClicked(): void {
                            root.selectedDate = new Date(model.year, model.month, model.day);
                        }
                    }

                    StyledText {
                        id: dayText
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: (parent.height - (dayText.implicitHeight + (dayItem.hasEvents ? dotsRow.height + 2 : 0))) / 2
                        horizontalAlignment: Text.AlignHCenter
                        text: grid.locale.toString(dayItem.model.day)
                        color: {
                            const dayOfWeek = dayItem.model.date.getUTCDay();
                            if (dayOfWeek === 0 || dayOfWeek === 6)
                                return Colours.palette.m3secondary;
                            return Colours.palette.m3onSurfaceVariant;
                        }
                        opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                        font.pointSize: Appearance.font.size.bodySmall
                        font.weight: 500
                    }

                    Row {
                        id: dotsRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: dayText.bottom
                        anchors.topMargin: 2
                        spacing: 1
                        visible: dayItem.hasEvents

                        Repeater {
                            model: dayItem.dotColors
                            delegate: Rectangle {
                                required property var modelData
                                width: 3
                                height: 3
                                radius: 1.5
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
                radius: Appearance.rounding.full
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
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }

                Behavior on y {
                    Anim {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }
            }
        }
    }
}
