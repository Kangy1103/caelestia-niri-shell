pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import Caelestia.Config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    property bool enabled: Config.session.enabled ?? true
    property bool vimKeybinds: Config.session.vimKeybinds ?? false
    property int dragThreshold: Config.session.dragThreshold ?? 30
    property int buttonSize: TokenConfig.sizes.session.button ?? 80

    anchors.fill: parent

    function saveConfig() {
        Config.session.enabled = root.enabled;
        Config.session.vimKeybinds = root.vimKeybinds;
        Config.session.dragThreshold = root.dragThreshold;
        TokenConfig.sizes.session.button = root.buttonSize;
    }

    ClippingRectangle {
        id: sessionClippingRect
        anchors.fill: parent
        anchors.margins: Config.appearance.padding.medium
        anchors.leftMargin: 0
        anchors.rightMargin: Config.appearance.padding.medium

        radius: sessionBorder.innerRadius
        color: "transparent"

        Loader {
            id: sessionLoader
            anchors.fill: parent
            anchors.margins: Config.appearance.padding.largeIncreased + Config.appearance.padding.medium
            anchors.leftMargin: Config.appearance.padding.largeIncreased
            anchors.rightMargin: Config.appearance.padding.largeIncreased

            sourceComponent: sessionContentComponent
        }
    }

    InnerBorder {
        id: sessionBorder
        leftThickness: 0
        rightThickness: Config.appearance.padding.medium
    }

    Component {
        id: sessionContentComponent

        StyledFlickable {
            id: sessionFlickable
            flickableDirection: Flickable.VerticalFlick
            contentHeight: sessionLayout.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: sessionFlickable
            }

            ColumnLayout {
                id: sessionLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Config.appearance.spacing.large

                RowLayout {
                    spacing: Config.appearance.spacing.medium

                    StyledText {
                        text: qsTr("Session")
                        font.pointSize: Config.appearance.font.title.medium.size
                        font.weight: 500
                    }
                }

                // General Section
                SectionContainer {
                    alignTop: true

                    StyledText {
                        text: qsTr("General")
                        font.pointSize: Config.appearance.font.body.medium.size
                    }

                    SwitchRow {
                        label: qsTr("Enabled")
                        checked: root.enabled
                        onToggled: checked => {
                            root.enabled = checked;
                            root.saveConfig();
                        }
                    }

                    SwitchRow {
                        label: qsTr("Vim keybinds")
                        checked: root.vimKeybinds
                        onToggled: checked => {
                            root.vimKeybinds = checked;
                            root.saveConfig();
                        }
                    }

                    SectionContainer {
                        contentSpacing: Config.appearance.spacing.large

                        SliderInput {
                            Layout.fillWidth: true

                            label: qsTr("Drag threshold")
                            value: root.dragThreshold
                            from: 0
                            to: 100
                            suffix: "px"
                            validator: IntValidator { bottom: 0; top: 100 }
                            formatValueFunction: val => Math.round(val).toString()
                            parseValueFunction: text => parseInt(text)

                            onValueModified: newValue => {
                                root.dragThreshold = Math.round(newValue);
                                root.saveConfig();
                            }
                        }
                    }
                }

                // Sizing Section
                SectionContainer {
                    alignTop: true

                    StyledText {
                        text: qsTr("Sizing")
                        font.pointSize: Config.appearance.font.body.medium.size
                    }

                    SectionContainer {
                        contentSpacing: Config.appearance.spacing.large

                        SliderInput {
                            Layout.fillWidth: true

                            label: qsTr("Button size")
                            value: root.buttonSize
                            from: 40
                            to: 160
                            stepSize: 5
                            suffix: "px"
                            validator: IntValidator { bottom: 40; top: 160 }
                            formatValueFunction: val => Math.round(val).toString()
                            parseValueFunction: text => parseInt(text)

                            onValueModified: newValue => {
                                root.buttonSize = Math.round(newValue);
                                root.saveConfig();
                            }
                        }
                    }
                }
            }
        }
    }
}
