// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260610

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import Quickshell
import Quickshell.Io

    Item {
    id: root

    required property Wrapper wrapper
    required property DrawerVisibilities visibilities

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.large

    implicitWidth: 420
    implicitHeight: 500

    Keys.onEscapePressed: root.visibilities.clipboard = false
    focus: true

    ListModel { id: clipboardModel }
    ListModel { id: filteredModel }

    property string searchQuery: ""

    Process {
        id: cliphistProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                clipboardModel.clear();
                const lines = text.trim().split("\n");
                for (const line of lines) {
                    if (!line) continue;
                    const parts = line.split("\t");
                    clipboardModel.append({
                        entryId: parts[0],
                        entryText: parts.slice(1).join("\t"),
                        isImage: line.includes("[[ binary data")
                    });
                }
                filterItems();
            }
        }
    }

    function refresh(): void { cliphistProc.running = true; }

    function filterItems(): void {
        filteredModel.clear();
        const q = root.searchQuery.toLowerCase();
        for (let i = 0; i < clipboardModel.count; i++) {
            const item = clipboardModel.get(i);
            if (!q || item.entryText.toLowerCase().includes(q))
                filteredModel.append(item);
        }
    }

    function deleteEntry(entryId: string): void {
        Quickshell.execDetached(["cliphist", "delete", entryId]);
        for (let i = 0; i < clipboardModel.count; i++) {
            if (clipboardModel.get(i).entryId === entryId) {
                clipboardModel.remove(i);
                break;
            }
        }
        filterItems();
    }

    function copyEntry(entryId: string): void {
        Quickshell.execDetached(["sh", "-c", "cliphist decode '" + entryId + "' | wl-copy"]);
    }

    Connections {
        target: root.wrapper
        function onShouldBeActiveChanged(): void {
            if (root.wrapper.shouldBeActive) {
                root.searchQuery = "";
                refresh();
                searchField.forceActiveFocus();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Tokens.spacing.medium

        // Search bar
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(searchField.implicitHeight, searchIcon.implicitHeight)
            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
            radius: Tokens.rounding.full

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.padding
                anchors.rightMargin: root.padding
                spacing: Tokens.spacing.small

                MaterialIcon {
                    id: searchIcon
                    text: "search"
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledTextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Search clipboard history")
                    onTextChanged: {
                        root.searchQuery = text;
                        root.filterItems();
                    }
                }

                MaterialIcon {
                    text: "close"
                    color: Colours.palette.m3onSurfaceVariant
                    visible: searchField.text !== ""
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchField.text = ""
                    }
                }
            }
        }

        // Clipboard list
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Tokens.spacing.extraSmall
            model: filteredModel

            delegate: ClipboardItem {
                width: ListView.view.width
                entryId: modelData.entryId
                entryText: modelData.entryText
                isImageEntry: modelData.isImage || false

                onActivated: root.copyEntry(entryId)
                onDeleteRequested: root.deleteEntry(entryId)
            }

            ScrollBar.vertical: StyledScrollBar {
                flickable: listView
            }
        }

        // Wipe button
        IconTextButton {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Clear clipboard history")
            icon: "delete_sweep"
            type: IconTextButton.FilledTonal
            onClicked: {
                Quickshell.execDetached(["cliphist", "wipe"]);
                clipboardModel.clear();
                filteredModel.clear();
            }
        }
    }
}
