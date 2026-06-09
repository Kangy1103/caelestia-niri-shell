pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Caelestia.Config
import qs.utils
import QtQuick
import QtQuick.Layouts

// Weather widget — top slot of the left lock panel.
// Horizontal inset: padding.largeIncreased on each side, matching Media.qml / Resources.qml.
ColumnLayout {
    id: root

    required property int rootHeight

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: Config.appearance.padding.largeIncreased
    anchors.rightMargin: Config.appearance.padding.largeIncreased

    spacing: 0

    // ── Section label + current temp ───────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Config.appearance.padding.largeIncreased
        Layout.bottomMargin: Config.appearance.padding.largeIncreased
        spacing: Config.appearance.spacing.extraSmall

        MaterialIcon {
            text: "partly_cloudy_day"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.label.large.size
        }

        StyledText {
            text: qsTr("Weather")
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.label.large.size
            font.weight: Font.Medium
            font.family: Config.appearance.font.mono.family
        }

        Item { Layout.fillWidth: true }

        // Temperature is the primary data — larger and accented
        StyledText {
            animate: true
            text: Weather.temp
            color: Colours.palette.m3primary
            font.pointSize: Config.appearance.font.body.large.size
            font.weight: Font.Bold
        }
    }

    // ── Current conditions row ─────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: Config.appearance.padding.largeIncreased
        spacing: Config.appearance.spacing.small

        MaterialIcon {
            text: Weather.icon || "cloud"
            color: Colours.palette.m3secondary
            font.pointSize: Config.appearance.font.body.medium.size
        }

        StyledText {
            Layout.fillWidth: true
            text: Weather.description
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.body.small.size
            font.family: Config.appearance.font.mono.family
            elide: Text.ElideRight
        }

        MaterialIcon {
            text: "water_drop"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.label.medium.size
            visible: Weather.humidity > 0
        }

        StyledText {
            text: Weather.humidity ? `${Weather.humidity}% humidity` : ""
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.body.small.size
            font.family: Config.appearance.font.mono.family
        }
    }

    // ── Hourly forecast ────────────────────────────────────────────────────────
    Loader {
        Layout.fillWidth: true
        Layout.bottomMargin: Config.appearance.padding.largeIncreased

        asynchronous: true
        active: (Weather.forecast?.length ?? 0) > 0
        visible: active

        sourceComponent: Item {
            implicitHeight: forecastRow.implicitHeight

            RowLayout {
                id: forecastRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Config.appearance.spacing.large

                Repeater {
                    model: Weather.forecast.slice(0, 6)

                    ColumnLayout {
                        required property var modelData
                        spacing: Config.appearance.spacing.small

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.icon || "cloud"
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Config.appearance.font.body.medium.size
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Config.services.useFahrenheit
                                ? `${modelData.maxTempF}°`
                                : `${modelData.maxTempC}°`
                            color: Colours.palette.m3onSurface
                            font.pointSize: Config.appearance.font.body.small.size
                            font.family: Config.appearance.font.mono.family
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDate(new Date(modelData.date), "ddd")
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Config.appearance.font.label.medium.size
                            font.family: Config.appearance.font.mono.family
                        }
                    }
                }
            }
        }
    }

    Timer {
        running: true
        triggeredOnStart: true
        repeat: true
        interval: 900000
        onTriggered: Weather.reload()
    }
}
