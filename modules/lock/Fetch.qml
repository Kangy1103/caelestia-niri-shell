pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import Caelestia.Config
import qs.utils
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// System fetch widget — flex-filling middle slot of the left lock panel.
// anchors.margins: padding.largeIncreased mirrors Resources.qml / Media.qml internal inset.
ColumnLayout {
    id: root

    anchors.fill: parent
    anchors.margins: Config.appearance.padding.largeIncreased

    spacing: Config.appearance.spacing.medium

    // ── Terminal header ────────────────────────────────────────────────────────
    //  icon + filename — mono, muted, matches section-label style across shell
    RowLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.small

        MaterialIcon {
            text: "chevron_right"
            font.pointSize: Config.appearance.font.body.medium.size
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            Layout.fillWidth: true
            text: "Systemfetch.sh"
            font.pointSize: Config.appearance.font.body.small.size
            font.family: Config.appearance.font.mono.family
            color: Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
        }
    }

    // ── Info key-value rows ────────────────────────────────────────────────────
    // Placed directly in root ColumnLayout — top-aligned, equal spacing between rows
    InfoRow { label: "OS";  value: SysInfo.osPrettyName || SysInfo.osName }
    InfoRow { label: "WM";  value: SysInfo.wm }
    InfoRow { label: "USR"; value: SysInfo.user }
    InfoRow { label: "UP";  value: SysInfo.uptime }

    InfoRow {
        visible: UPower.displayDevice.isLaptopBattery
        label: "BAT"
        value: `${UPower.onBattery ? "" : "+ "}${Math.round(UPower.displayDevice.percentage * 100)}%`
    }

    Item { Layout.preferredHeight: Config.appearance.font.label.large.size }

    // Flex spacer — pushes swatches to the bottom of the available area
    Item { Layout.fillHeight: true }

    // ── Inline component: key : value row ─────────────────────────────────────
    component InfoRow: RowLayout {
        id: infoRow

        required property string label
        required property string value

        Layout.fillWidth: true
        spacing: Config.appearance.spacing.extraSmall

        StyledText {
            text: infoRow.label
            font.pointSize: Config.appearance.font.label.large.size
            font.family: Config.appearance.font.mono.family
            color: Colours.palette.m3primary
            font.weight: Font.Medium
        }

        StyledText {
            Layout.fillWidth: true
            text: infoRow.value
            font.pointSize: Config.appearance.font.label.large.size
            font.family: Config.appearance.font.mono.family
            color: Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
        }
    }
}
