// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260612

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CNS.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.nexus

VerticalFadeFlickable {
    id: root

    required property NexusState nState

    readonly property var filteredPages: {
        var result = [];
        var searchOn = nState.searchOpen;
        var query = searchOn ? nState.searchText.toLowerCase() : "";

        for (var i = 0; i < PageRegistry.pages.length; i++) {
            var p = PageRegistry.pages[i];
            if (searchOn) {
                if (p.label.toLowerCase().indexOf(query) < 0
                    && p.description.toLowerCase().indexOf(query) < 0
                    && p.category.toLowerCase().indexOf(query) < 0) {
                    continue;
                }
            }
            var entry = { origIdx: i, label: p.label, icon: p.icon, description: p.description, category: p.category };
            if (p.noFill !== undefined) entry.noFill = p.noFill;
            result.push(entry);
        }
        return result;
    }

    topMargin: Tokens.padding.large
    bottomMargin: Tokens.padding.large
    contentHeight: content.implicitHeight

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.extraSmall

        Repeater {
            id: list

            model: root.filteredPages

            StyledRect {
                id: item

                required property var modelData
                required property int index

                readonly property bool isCurrentPage: modelData.origIdx === root.nState.currentPageIdx
                readonly property bool isCategoryStart: index === 0 || root.filteredPages[index - 1].category !== modelData.category
                readonly property bool isCategoryEnd: index === root.filteredPages.length - 1 || root.filteredPages[index + 1].category !== modelData.category

                Layout.fillWidth: true
                Layout.topMargin: index !== 0 && isCategoryStart ? Tokens.spacing.medium : 0
                implicitHeight: {
                    const h = layout.implicitHeight + layout.anchors.margins * 2;
                    return h % 2 === 0 ? h : h + 1;
                }

                color: isCurrentPage ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

                topLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryStart ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                topRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryStart ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                bottomLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryEnd ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                bottomRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryEnd ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

                RadiusBehavior on topLeftRadius {}
                RadiusBehavior on topRightRadius {}
                RadiusBehavior on bottomLeftRadius {}
                RadiusBehavior on bottomRightRadius {}

                StateLayer {
                    id: stateLayer

                    anchors.fill: parent
                    topLeftRadius: parent.topLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    bottomRightRadius: parent.bottomRightRadius

                    onClicked: root.nState.currentPageIdx = modelData.origIdx
                }

                RowLayout {
                    id: layout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        Layout.fillHeight: true
                        Layout.topMargin: -1
                        Layout.bottomMargin: -1
                        implicitWidth: height

                        radius: Tokens.rounding.full
                        color: item.isCurrentPage ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                        MaterialIcon {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 1

                            text: item.modelData.icon
                            color: item.isCurrentPage ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                            fontStyle: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
                            grade: 25
                            fill: item.modelData.noFill ? 0 : 1
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.label
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.description
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    component RadiusBehavior: Behavior {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
