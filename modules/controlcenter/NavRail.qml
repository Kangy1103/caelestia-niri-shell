pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Caelestia.Config
import qs.modules.controlcenter
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    required property Session session
    required property bool initialOpeningComplete

    implicitWidth: navFlickable.implicitWidth + Config.appearance.padding.largeIncreased * 2
    implicitHeight: parent ? parent.height : 400

    Flickable {
        id: navFlickable

        anchors.fill: parent
        anchors.leftMargin: Config.appearance.padding.largeIncreased
        anchors.rightMargin: Config.appearance.padding.largeIncreased
        anchors.topMargin: Config.appearance.padding.large
        anchors.bottomMargin: Config.appearance.padding.large

        contentHeight: layout.implicitHeight
        contentWidth: layout.implicitWidth
        flickableDirection: Flickable.VerticalFlick
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        implicitWidth: layout.implicitWidth

        ColumnLayout {
            id: layout

            spacing: 2

            Loader {
                Layout.bottomMargin: Config.appearance.spacing.extraSmall
                active: !root.session.floating
                visible: active

                sourceComponent: StyledRect {
                    implicitWidth: floatRow.implicitWidth + Config.appearance.padding.largeIncreased * 2
                    implicitHeight: floatRow.implicitHeight + Config.appearance.padding.medium * 2

                    color: Colours.palette.m3primaryContainer
                    radius: Config.appearance.rounding.small

                    StateLayer {
                        color: Colours.palette.m3onPrimaryContainer

                        onClicked: {
                            root.session.root.close();
                            WindowFactory.create(null, {
                                active: root.session.active,
                                navExpanded: root.session.navExpanded
                            });
                        }
                    }

                    RowLayout {
                        id: floatRow

                        anchors.centerIn: parent
                        spacing: Config.appearance.spacing.small

                        MaterialIcon {
                            text: "open_in_new"
                            color: Colours.palette.m3onPrimaryContainer
                            fontStyle: Tokens.font.icon.size(Config.appearance.font.body.large.size).build()
}

                        StyledText {
                            text: qsTr("Float window")
                            color: Colours.palette.m3onPrimaryContainer
                            font.pointSize: Config.appearance.font.body.small.size
                        }
                    }
                }
            }

            Loader {
                active: !root.session.floating
                visible: active
                Layout.fillWidth: true
                Layout.topMargin: Config.appearance.spacing.extraSmall
                Layout.bottomMargin: Config.appearance.spacing.small

                sourceComponent: Rectangle {
                    implicitHeight: 1
                    color: Qt.alpha(Colours.palette.m3outlineVariant, 0.4)
                }
            }

            Repeater {
                model: PaneRegistry.count

                ColumnLayout {
                    id: navDelegate

                    required property int index
                    spacing: 0

                    Loader {
                        active: navDelegate.index > 0 && PaneRegistry.isFirstInCategory(navDelegate.index)
                        visible: active
                        Layout.fillWidth: true
                        Layout.leftMargin: Config.appearance.padding.medium
                        Layout.rightMargin: Config.appearance.padding.medium
                        Layout.topMargin: Config.appearance.spacing.small
                        Layout.bottomMargin: Config.appearance.spacing.small

                        sourceComponent: Rectangle {
                            implicitHeight: 1
                            color: Qt.alpha(Colours.palette.m3outlineVariant, 0.4)
                        }
                    }

                    NavItem {
                        icon: PaneRegistry.getByIndex(navDelegate.index).icon
                        label: PaneRegistry.getByIndex(navDelegate.index).label
                    }
                }
            }
        }
    }

    component NavItem: Item {
        id: item

        required property string icon
        required property string label
        readonly property bool active: root.session.active === label

        implicitWidth: background.implicitWidth
        implicitHeight: background.implicitHeight

        StyledRect {
            id: background

            anchors.left: parent.left
            anchors.right: parent.right

            radius: Config.appearance.rounding.full
            color: Qt.alpha(Colours.palette.m3secondaryContainer, item.active ? 1 : 0)

            implicitWidth: itemIcon.implicitWidth + itemIcon.anchors.leftMargin + itemLabel.anchors.leftMargin + itemLabel.implicitWidth + Config.appearance.padding.largeIncreased
            implicitHeight: Math.max(itemIcon.implicitHeight, itemLabel.implicitHeight) + Config.appearance.padding.medium * 2

            Behavior on color {
                CAnim {}
            }

            StateLayer {
                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

                onClicked: {
                    if (!root.initialOpeningComplete)
                        return;
                    root.session.active = item.label;
                }
            }

            MaterialIcon {
                id: itemIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Config.appearance.padding.largeIncreased

                text: item.icon
                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.size(Config.appearance.font.body.large.size).build()
fill: item.active ? 1 : 0

                Behavior on fill {
                    Anim {}
                }

                Behavior on color {
                    CAnim {}
                }
            }

            StyledText {
                id: itemLabel

                anchors.left: itemIcon.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Config.appearance.spacing.large

                text: item.label
                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.body.small.size
                font.weight: item.active ? Font.DemiBold : Font.Normal
                font.capitalization: Font.Capitalize

                Behavior on color {
                    CAnim {}
                }
            }
        }
    }
}
