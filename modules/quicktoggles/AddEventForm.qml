pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    required property date selectedDate
    property bool active: false

    signal saved()
    signal cancelled()

    readonly property var colors: [
        Config.dashboard.calendarColors.blue,
        Config.dashboard.calendarColors.red,
        Config.dashboard.calendarColors.yellow,
        Config.dashboard.calendarColors.green,
        Config.dashboard.calendarColors.purple,
        Config.dashboard.calendarColors.teal,
        Config.dashboard.calendarColors.pink,
        Config.dashboard.calendarColors.orange,
        Config.dashboard.calendarColors.brown,
    ]

    property string title: ""
    property string startTime: "09:00"
    property string endTime: "10:00"
    property string lastValidStartTime: "09:00"
    property string lastValidEndTime: "10:00"
    property bool allDay: false
    property string selectedColor: Config.dashboard.calendarColors.blue

    visible: active
    implicitHeight: active ? formLayout.implicitHeight + Appearance.padding.md * 2 : 0
    implicitWidth: formLayout.implicitWidth + Appearance.padding.md * 2

    onActiveChanged: {
        if (active)
            resetForm();
    }

    function resetForm(): void {
        titleField.text = "";
        root.startTime = "09:00";
        root.endTime = "10:00";
        startTimeField.text = "09:00";
        endTimeField.text = "10:00";
        root.lastValidStartTime = "09:00";
        root.lastValidEndTime = "10:00";
        allDaySwitch.checked = false;
        selectedColor = Config.dashboard.calendarColors.blue;
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.normal
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    ColumnLayout {
        id: formLayout
        anchors.fill: parent
        anchors.margins: Appearance.padding.md
        spacing: Appearance.spacing.sm

        StyledInputField {
            id: titleField
            Layout.fillWidth: true
            text: root.title
            placeholderText: "Event title"
            horizontalAlignment: TextInput.AlignLeft

            onTextEdited: text => root.title = text
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.sm

            StyledInputField {
                id: startTimeField
                Layout.fillWidth: true
                text: root.startTime
                placeholderText: "HH:MM"
                readOnly: root.allDay
                opacity: root.allDay ? 0.5 : 1

                onTextEdited: text => {
                    root.startTime = text;
                    if (/^([01][0-9]|2[0-3]):[0-5][0-9]$/.test(text))
                        root.lastValidStartTime = text;
                }

                onEditingFinished: {
                    if (!/^([01][0-9]|2[0-3]):[0-5][0-9]$/.test(root.startTime)) {
                        root.startTime = root.lastValidStartTime;
                        startTimeField.text = root.lastValidStartTime;
                    }
                }
            }

            StyledInputField {
                id: endTimeField
                Layout.fillWidth: true
                text: root.endTime
                placeholderText: "HH:MM"
                readOnly: root.allDay
                opacity: root.allDay ? 0.5 : 1

                onTextEdited: text => {
                    root.endTime = text;
                    if (/^([01][0-9]|2[0-3]):[0-5][0-9]$/.test(text))
                        root.lastValidEndTime = text;
                }

                onEditingFinished: {
                    if (!/^([01][0-9]|2[0-3]):[0-5][0-9]$/.test(root.endTime)) {
                        root.endTime = root.lastValidEndTime;
                        endTimeField.text = root.lastValidEndTime;
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.sm

            StyledText {
                text: "All day"
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.bodySmall
            }

            Item { Layout.fillWidth: true }

            Switch {
                id: allDaySwitch
                checked: root.allDay

                onCheckedChanged: root.allDay = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.sm

            Repeater {
                model: root.colors

                delegate: Rectangle {
                    required property var modelData
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 12
                    color: modelData

                    readonly property bool isSelected: modelData === root.selectedColor
                    border.width: isSelected ? 3 : 0
                    border.color: Colours.palette.m3onSurface
                    scale: isSelected ? 1.2 : 1

                    Behavior on scale { Anim {} }
                    Behavior on border.width { Anim {} }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selectedColor = modelData
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.sm

            IconTextButton {
                id: cancelBtn
                Layout.fillWidth: true
                text: "Cancel"
                icon: "close"
                type: IconTextButton.Tonal
                radius: Appearance.rounding.small

                onClicked: root.cancelled()
            }

            IconTextButton {
                id: saveBtn
                Layout.fillWidth: true
                text: "Save"
                icon: "check"
                type: IconTextButton.Filled
                radius: Appearance.rounding.small
                enabled: root.title.trim().length > 0

                onClicked: {
                    CalEvents.addEvent({
                        title: root.title.trim(),
                        startDate: root.selectedDate,
                        startTime: root.allDay ? "" : root.startTime,
                        endTime: root.allDay ? "" : root.endTime,
                        allDay: root.allDay,
                        color: root.selectedColor,
                    });
                    root.saved();
                }
            }
        }
    }
}
