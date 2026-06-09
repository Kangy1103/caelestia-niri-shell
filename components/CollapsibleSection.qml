import qs.services
import Caelestia.Config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    default property alias contentComponent: contentLoader.sourceComponent

    property string title: qsTr("Dropdown Title")
    property string description: ""
    property bool expanded: false
    property bool showBackground: false
    property bool nested: false
    property color backgroundColor: expanded ? Colours.palette.m3surfaceContainerLow : "transparent"

    // Margin properties: if backgroundMargins >= 0, use it for all sides; otherwise, use individual margins
    property real backgroundMarginLeft: Config.appearance.padding.extraSmall
    property real backgroundMarginRight: Config.appearance.padding.extraSmall
    property real backgroundMarginTop: Config.appearance.padding.extraSmall
    property real backgroundMarginBottom: 0
    property real backgroundMargins: -1 // -1 means "not set"

    signal collapsed

    // Header height constant
    Rectangle {
        id: backgroundRect

        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true

        Layout.leftMargin: root.backgroundMargins >= 0 ? root.backgroundMargins : root.backgroundMarginLeft
        Layout.rightMargin: root.backgroundMargins >= 0 ? root.backgroundMargins : root.backgroundMarginRight
        Layout.topMargin: root.backgroundMargins >= 0 ? root.backgroundMargins : root.backgroundMarginTop
        Layout.bottomMargin: root.backgroundMargins >= 0 ? root.backgroundMargins : root.backgroundMarginBottom

        color: root.backgroundColor
        radius: Config.appearance.rounding.small

        // Height is header + description (if shown) + content (if expanded) + margins
        Layout.preferredHeight: headerRow.implicitHeight + Config.appearance.padding.extraSmall * 2 + (root.expanded && root.description !== "" ? descriptionText.implicitHeight + descriptionText.Layout.topMargin + descriptionText.Layout.bottomMargin : 0) + (root.expanded ? contentWrapper.implicitHeight : 0) + (anchors.topMargin + anchors.bottomMargin)

        Behavior on Layout.preferredHeight {
            Anim {}
        }

        ColumnLayout {
            anchors.fill: parent

            // Header
            RowLayout {
                id: headerRow
                Layout.topMargin: Config.appearance.padding.extraSmall
                Layout.leftMargin: Config.appearance.padding.largeIncreased
                Layout.rightMargin: Config.appearance.padding.extraSmall
                Layout.bottomMargin: Config.appearance.padding.extraSmall

                spacing: Config.appearance.spacing.large
                implicitHeight: Config.appearance.spacing.large + Config.appearance.padding.extraSmall * 2

                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    elide: Text.ElideRight
                    font.pointSize: Config.appearance.font.body.small.size
                    font.family: Config.appearance.font.body.family
                }

                StyledRect {
                    color: "transparent"

                    radius: Config.appearance.rounding.small

                    implicitWidth: expandIcon.implicitWidth + Config.appearance.padding.extraSmall * 2
                    implicitHeight: expandIcon.implicitHeight + Config.appearance.padding.extraSmall

                    StateLayer {
                        function onClicked(): void {
                            root.expanded = !root.expanded;
                        }
                    }

                    MaterialIcon {
                        id: expandIcon
                        anchors.centerIn: parent
                        animate: true
                        text: root.expanded ? "expand_less" : "expand_more"
                        color: root.expanded ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                        font.pointSize: Config.appearance.font.title.medium.size
                    }
                }
            }

            // Description text (shown when expanded and description is set)
            StyledText {
                id: descriptionText
                Layout.fillWidth: true
                Layout.leftMargin: Config.appearance.padding.largeIncreased
                Layout.rightMargin: Config.appearance.padding.extraSmall
                Layout.topMargin: root.description !== "" ? Config.appearance.spacing.medium : 0
                Layout.bottomMargin: root.description !== "" ? Config.appearance.spacing.small : 0
                visible: root.expanded && root.description !== ""
                text: root.description
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.label.large.size
                wrapMode: Text.Wrap
            }

            // Collapsible content
            WrapperItem {
                id: contentWrapper
                Layout.fillWidth: true
                Layout.leftMargin: Config.appearance.padding.small
                Layout.rightMargin: Config.appearance.padding.small

                // Animate height for smooth expand/collapse
                Layout.preferredHeight: root.expanded ? contentLoader.implicitHeight + topMargin + bottomMargin : 0
                clip: true

                bottomMargin: Config.appearance.padding.largeIncreased

                Loader {
                    id: contentLoader
                    Layout.fillWidth: true
                    active: root.expanded
                }

                Behavior on Layout.preferredHeight {
                    Anim {}
                }
            }
        }
    }

    function collapse(): void {
        if (expanded) {
            expanded = false;
        }
    }

    onExpandedChanged: {
        if (!expanded) {
            collapsed();
        }
    }
}
