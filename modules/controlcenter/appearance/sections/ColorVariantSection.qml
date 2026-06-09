pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import Caelestia.Config
import Quickshell
import QtQuick
import QtQuick.Layouts

CollapsibleSection {
    title: qsTr("Color variant")
    description: qsTr("Material theme variant")
    showBackground: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.small / 2

        Repeater {
            model: M3Variants.list

            delegate: StyledRect {
                required property var modelData

                Layout.fillWidth: true

                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, modelData.variant === Schemes.currentVariant ? Colours.tPalette.m3surfaceContainer.a : 0)
                radius: Config.appearance.rounding.large
                border.width: modelData.variant === Schemes.currentVariant ? 1 : 0
                border.color: Colours.palette.m3primary

                StateLayer {
                    function onClicked(): void {
                        M3Variants.setVariant(modelData.variant);
                    }
                }

                RowLayout {
                    id: variantRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Config.appearance.padding.medium

                    spacing: Config.appearance.spacing.large

                    MaterialIcon {
                        text: modelData.icon
                        font.pointSize: Config.appearance.font.title.medium.size
                        fill: modelData.variant === Schemes.currentVariant ? 1 : 0
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.name
                        font.weight: modelData.variant === Schemes.currentVariant ? 500 : 400
                    }

                    MaterialIcon {
                        visible: modelData.variant === Schemes.currentVariant
                        text: "check"
                        color: Colours.palette.m3primary
                        font.pointSize: Config.appearance.font.title.medium.size
                    }
                }

                implicitHeight: variantRow.implicitHeight + Config.appearance.padding.medium * 2
            }
        }
    }
}
