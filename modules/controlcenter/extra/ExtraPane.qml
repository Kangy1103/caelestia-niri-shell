pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import Caelestia.Config
import Caelestia
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    function saveConfig(): void {
    }

    ClippingRectangle {
        id: extraClippingRect
        anchors.fill: parent
        anchors.margins: Config.appearance.padding.medium
        anchors.leftMargin: 0
        anchors.rightMargin: Config.appearance.padding.medium

        radius: extraBorder.innerRadius
        color: "transparent"

        Loader {
            id: extraLoader
            anchors.fill: parent
            anchors.margins: Config.appearance.padding.largeIncreased + Config.appearance.padding.medium
            anchors.leftMargin: Config.appearance.padding.largeIncreased
            anchors.rightMargin: Config.appearance.padding.largeIncreased

            sourceComponent: extraContentComponent
        }
    }

    InnerBorder {
        id: extraBorder
        leftThickness: 0
        rightThickness: Config.appearance.padding.medium
    }

    Component {
        id: extraContentComponent

        StyledFlickable {
            id: extraFlickable
            flickableDirection: Flickable.VerticalFlick
            contentHeight: extraLayout.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: extraFlickable
            }

            ColumnLayout {
                id: extraLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Config.appearance.spacing.large

                RowLayout {
                    spacing: Config.appearance.spacing.medium

                    StyledText {
                        text: qsTr("Extra Features")
                        font.pointSize: Config.appearance.font.title.medium.size
                        font.weight: 500
                    }
                }

                // Features Section
                SectionContainer {
                    alignTop: true

                    StyledText {
                        text: qsTr("Features")
                        font.pointSize: Config.appearance.font.body.medium.size
                    }
                }
            }
        }
    }
}
