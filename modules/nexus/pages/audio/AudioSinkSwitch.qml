pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CNS.Config
import qs.components
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Output switcher")
    isSubPage: true

    readonly property string _speakersMatch: "Main Audio"
    readonly property string _scarlettMatch: "Scarlett Solo 4th Gen"

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Sink identifiers")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            implicitHeight: speakersRow.implicitHeight + speakersRow.anchors.margins * 2

            RowLayout {
                id: speakersRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "volume_up"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Speakers")
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    text: root._speakersMatch
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            last: true
            implicitHeight: scarlettRow.implicitHeight + scarlettRow.anchors.margins * 2

            RowLayout {
                id: scarlettRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "headphones"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Scarlett")
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    text: root._scarlettMatch
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }
        }
    }
}
