pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property string label
    property string currentFont
    property var model: Fonts.families
    property bool expanded: false

    signal fontSelected(string fontName)

    spacing: Config.appearance.spacing.extraSmall
    Layout.fillWidth: true

    // Header/Toggle Button
    StyledRect {
        id: header
        Layout.fillWidth: true
        implicitHeight: 56
        radius: Config.appearance.rounding.large
        color: root.expanded ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3surfaceContainer
        border.width: 1
        border.color: root.expanded ? Colours.palette.m3primary : "transparent"

        Behavior on color { CAnim {} }
        Behavior on border.color { CAnim {} }

        StateLayer {
            onClicked: {
                root.expanded = !root.expanded;
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Config.appearance.padding.medium
            spacing: Config.appearance.spacing.medium

            ColumnLayout {
                spacing: 0

                StyledText {
                    text: root.label
                    font.pointSize: Config.appearance.font.label.medium.size
                    color: Colours.palette.m3onSurfaceVariant
                    font.weight: 500
                }

                StyledText {
                    text: root.currentFont
                    font.pointSize: Config.appearance.font.body.large.size
                    font.weight: 400
                    elide: Text.ElideRight
                    color: Colours.palette.m3onSurface
                }
            }

            Item {
                Layout.fillWidth: true
            }

            MaterialIcon {
                text: root.expanded ? "expand_less" : "expand_more"
                color: root.expanded ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.size(Config.appearance.font.title.medium.size).build()
Behavior on color { CAnim {} }
                Behavior on rotation { Anim {} }
            }
        }
    }

    // Dropdown Content
    StyledRect {
        id: dropdownContainer
        Layout.fillWidth: true
        implicitHeight: root.expanded ? 320 : 0
        visible: root.expanded || opacity > 0
        opacity: root.expanded ? 1 : 0
        radius: Config.appearance.rounding.large
        color: Colours.palette.m3surfaceContainerHigh
        clip: true

        Behavior on implicitHeight {
            Anim { duration: Config.appearance.anim.durations.normal; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            Anim { duration: Config.appearance.anim.durations.normal }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Config.appearance.padding.small
            spacing: Config.appearance.spacing.small

            // Search Bar
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Config.appearance.rounding.small
                color: Colours.palette.m3surfaceContainerHighest
                border.width: 1
                border.color: searchField.hasFocus ? Colours.palette.m3primary : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Config.appearance.padding.medium
                    anchors.rightMargin: Config.appearance.padding.small
                    spacing: Config.appearance.spacing.small

                    MaterialIcon {
                        text: "search"
                        fontStyle: Tokens.font.icon.size(Config.appearance.font.body.medium.size).build()
color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledTextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Search fonts...")
                        font.pointSize: Config.appearance.font.body.medium.size
                        
                        onTextChanged: {
                            fontList.positionViewAtBeginning();
                        }

                        onVisibleChanged: {
                            if (visible) searchField.forceActiveFocus();
                        }
                    }
                    
                    IconButton {
                        visible: searchField.text !== ""
                        icon: "close"
                        type: IconButton.Text
                        font.pointSize: Config.appearance.font.body.small.size
                        onClicked: searchField.text = ""
                    }
                }
            }

            // Font List
            StyledListView {
                id: fontList
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                property var filteredModel: {
                    if (!searchField.text) return root.model;
                    const query = searchField.text.toLowerCase();
                    return root.model.filter(font => font.toLowerCase().includes(query));
                }

                model: filteredModel
                spacing: Config.appearance.spacing.extraSmall
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: fontList
                }

                delegate: StyledRect {
                    id: delegateRoot
                    required property string modelData
                    width: fontList.width
                    implicitHeight: 44
                    radius: Config.appearance.rounding.small
                    
                    readonly property bool isCurrent: modelData === root.currentFont
                    color: isCurrent ? Colours.palette.m3secondaryContainer : "transparent"

                    StateLayer {
                        onClicked: {
                            root.fontSelected(modelData);
                            root.expanded = false;
                            searchField.text = "";
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Config.appearance.padding.medium
                        anchors.rightMargin: Config.appearance.padding.medium
                        spacing: Config.appearance.spacing.medium

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData
                            font.family: modelData
                            font.pointSize: Config.appearance.font.body.medium.size
                            color: isCurrent ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        MaterialIcon {
                            visible: isCurrent
                            text: "check"
                            fontStyle: Tokens.font.icon.size(Config.appearance.font.body.large.size).build()
color: Colours.palette.m3onSecondaryContainer
                        }
                    }
                }
            }
        }
    }
}
