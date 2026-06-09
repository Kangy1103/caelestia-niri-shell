import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Config.appearance.padding.largeIncreased

    rowSpacing: Config.appearance.spacing.medium
    columnSpacing: Config.appearance.spacing.medium
    columns: 2

    Ref {
        service: SystemUsage
    }

    // Section label
    RowLayout {
        Layout.columnSpan: 2
        Layout.fillWidth: true
        Layout.topMargin: Config.appearance.padding.largeIncreased
        Layout.bottomMargin: Config.appearance.spacing.extraSmall
        spacing: Config.appearance.spacing.extraSmall

        MaterialIcon {
            text: "monitor_heart"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.size(Config.appearance.font.label.large.size).build()
}

        StyledText {
            text: qsTr("System")
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.label.large.size
            font.weight: Font.Medium
            font.family: Config.appearance.font.mono.family
        }
    }

    Resource {
        icon: "memory"
        value: SystemUsage.cpuPerc
        colour: Colours.palette.m3primary
    }

    Resource {
        icon: "thermostat"
        value: Math.min(1, SystemUsage.cpuTemp / 90)
        colour: Colours.palette.m3secondary
    }

    Resource {
        Layout.bottomMargin: Config.appearance.padding.largeIncreased
        icon: "memory_alt"
        value: SystemUsage.memPerc
        colour: Colours.palette.m3secondary
    }

    Resource {
        Layout.bottomMargin: Config.appearance.padding.largeIncreased
        icon: "hard_disk"
        value: SystemUsage.storagePerc
        colour: Colours.palette.m3tertiary
    }

    component Resource: StyledRect {
        id: res

        required property string icon
        required property real value
        required property color colour

        Layout.fillWidth: true
        implicitHeight: width

        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
        radius: Config.appearance.rounding.large

        CircularProgress {
            id: circ

            anchors.fill: parent
            value: res.value
            padding: Config.appearance.padding.largeIncreased * 3
            fgColour: res.colour
            bgColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)
            strokeWidth: width < 200 ? Config.appearance.padding.small : Config.appearance.padding.medium
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            text: res.icon
            color: res.colour
            fontStyle: Tokens.font.icon.size((circ.arcRadius * 0.7) || 1).weight(600).build()
}

        Behavior on value {
            Anim {
                duration: Config.appearance.anim.durations.large
            }
        }
    }
}
