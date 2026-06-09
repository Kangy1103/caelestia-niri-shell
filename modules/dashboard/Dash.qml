import qs.components
import qs.services
import qs.config
import "dash"
import Quickshell
import QtQuick.Layouts

GridLayout {
    id: root

    required property PersistentProperties visibilities
    required property PersistentProperties state

    columns: 6
    rowSpacing: Appearance.spacing.lg
    columnSpacing: Appearance.spacing.lg

    Rect {
        Layout.column: 2
        Layout.columnSpan: 3
        Layout.preferredWidth: user.implicitWidth
        Layout.preferredHeight: user.implicitHeight

        User {
            id: user
            visibilities: root.visibilities
            state: root.state
        }
    }

    Rect {
        Layout.row: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: Config.dashboard.sizes.weatherWidth
        Layout.fillHeight: true

        Weather {}
    }

    Rect {
        Layout.row: 1
        Layout.columnSpan: 4
        Layout.fillWidth: true
        Layout.minimumHeight: dateTime.implicitHeight + Appearance.padding.md

        DateTime {
            id: dateTime
            anchors.centerIn: parent
        }
    }

    Rect {
        Layout.row: 2
        Layout.columnSpan: 4
        Layout.fillWidth: true
        Layout.minimumHeight: 90

        QuickToggles {}
    }

    Rect {
        Layout.row: 3
        Layout.columnSpan: 4
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 80

        UpcomingEvents {}
    }

    Rect {
        Layout.row: 1
        Layout.column: 4
        Layout.rowSpan: 3
        Layout.fillHeight: true
        Layout.minimumHeight: 200
        Layout.preferredWidth: resources.implicitWidth

        Resources {
            id: resources
        }
    }

    Rect {
        Layout.row: 0
        Layout.column: 5
        Layout.rowSpan: 4
        Layout.preferredWidth: media.implicitWidth
        Layout.fillHeight: true

        Media {
            id: media
        }
    }

    component Rect: StyledRect {
        radius: Appearance.rounding.small
        color: Colours.tPalette.m3surfaceContainer
    }
}
