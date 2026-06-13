// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.4.0-20260610

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CNS.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property DrawerVisibilities visibilities

    implicitWidth: 630
    implicitHeight: 500

    ListModel { id: clipboardModel }
    ListModel { id: filteredModel }

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
                        id: parts[0],
                        content: parts.slice(1).join("\t"),
                        isImage: line.includes("[[ binary data")
                    });
                }
                filterItems();
            }
        }
    }

    function refresh(): void { cliphistProc.running = true; }

    function filterItems(): void {
        const query = searchInput.text.toLowerCase();
        filteredModel.clear();
        for (let i = 0; i < clipboardModel.count; i++) {
            const item = clipboardModel.get(i);
            if (query === "" || item.content.toLowerCase().includes(query))
                filteredModel.append(item);
        }
        if (filteredModel.count > 0)
            listView.currentIndex = 0;
    }

    function deleteEntry(entryId: string): void {
        Quickshell.execDetached(["cliphist", "delete", entryId]);
        for (let i = 0; i < clipboardModel.count; i++) {
            if (clipboardModel.get(i).id === entryId) {
                clipboardModel.remove(i);
                break;
            }
        }
        filterItems();
    }

    function wipeAll(): void {
        Quickshell.execDetached(["cliphist", "wipe"]);
        clipboardModel.clear();
        filteredModel.clear();
    }

    Component.onCompleted: refresh()

    Connections {
        target: root.visibilities
        function onClipboardChanged(): void {
            if (root.visibilities.clipboard) {
                refresh();
                Qt.callLater(() => searchInput.forceActiveFocus());
            } else {
                searchInput.text = "";
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        // Search bar
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(searchIcon.implicitHeight, searchInput.implicitHeight, clearIcon.implicitHeight)
            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
            radius: Tokens.rounding.full

            MaterialIcon {
                id: searchIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Tokens.padding.medium
                text: "search"
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledTextField {
                id: searchInput
                anchors.left: searchIcon.right
                anchors.right: clearIcon.left
                anchors.leftMargin: Tokens.spacing.small
                anchors.rightMargin: Tokens.spacing.small
                topPadding: Tokens.padding.medium
                bottomPadding: Tokens.padding.medium
                placeholderText: qsTr("Search clipboard history")

                Component.onCompleted: forceActiveFocus()

                onTextChanged: root.filterItems()

                Keys.onEscapePressed: root.visibilities.clipboard = false

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Down) {
                        listView.forceActiveFocus();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (listView.count > 0) {
                            listView.forceActiveFocus();
                            const entryId = filteredModel.get(listView.currentIndex).id;
                            Quickshell.execDetached(["sh", "-c", "cliphist decode '" + entryId + "' | wl-copy"]);
                            root.visibilities.clipboard = false;
                        }
                        event.accepted = true;
                    }
                }
            }

            MaterialIcon {
                id: clearIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Tokens.padding.medium
                width: searchInput.text ? implicitWidth : implicitWidth / 2
                opacity: searchInput.text ? 1 : 0
                text: "close"
                color: Colours.palette.m3onSurfaceVariant

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: searchInput.text ? Qt.PointingHandCursor : undefined
                    onClicked: searchInput.text = ""
                }

                Behavior on width {
                    Anim { type: Anim.StandardSmall }
                }
                Behavior on opacity {
                    Anim { type: Anim.StandardSmall }
                }
            }
        }

        // Clipboard list
        StyledClippingRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainer

                StyledListView {
                id: listView
                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                model: filteredModel
                spacing: Tokens.spacing.extraSmall
                currentIndex: 0
                highlightFollowsCurrentItem: true
                clip: true

                highlightMoveDuration: Tokens.anim.durations.normal
                highlightResizeDuration: 0

                highlight: StyledRect {
                    radius: Tokens.rounding.medium
                    color: Colours.palette.m3onSurface
                    opacity: 0.08
                }

                delegate: ClipboardItem {
                    required property int index
                    required property string id
                    required property string content
                    required property bool isImage

                    entryId: id
                    entryText: content
                    isImageEntry: isImage
                    selected: ListView.isCurrentItem
                    width: listView.width

                    onActivated: {
                        Quickshell.execDetached(["sh", "-c", "cliphist decode '" + id + "' | wl-copy"]);
                        root.visibilities.clipboard = false;
                    }

                    onDeleteRequested: {
                        Quickshell.execDetached(["cliphist", "delete", id]);
                        for (let i = 0; i < clipboardModel.count; i++) {
                            if (clipboardModel.get(i).id === id) {
                                clipboardModel.remove(i);
                                break;
                            }
                        }
                        filteredModel.remove(index);
                    }
                }

                Keys.onEscapePressed: root.visibilities.clipboard = false

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Down && currentIndex < count - 1) {
                        currentIndex++;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        if (currentIndex > 0) {
                            currentIndex--;
                        } else {
                            searchInput.forceActiveFocus();
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (currentIndex >= 0 && currentIndex < count) {
                            const entryId = filteredModel.get(currentIndex).id;
                            Quickshell.execDetached(["sh", "-c", "cliphist decode '" + entryId + "' | wl-copy"]);
                            root.visibilities.clipboard = false;
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Delete) {
                        if (currentIndex >= 0 && currentIndex < count) {
                            const entryId = filteredModel.get(currentIndex).id;
                            Quickshell.execDetached(["cliphist", "delete", entryId]);
                            for (let i = 0; i < clipboardModel.count; i++) {
                                if (clipboardModel.get(i).id === entryId) {
                                    clipboardModel.remove(i);
                                    break;
                                }
                            }
                            filteredModel.remove(currentIndex);
                        }
                        event.accepted = true;
                    }
                }
            }

            // Empty state
            Column {
                visible: filteredModel.count === 0 && !cliphistProc.running
                anchors.centerIn: parent
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: searchInput.text === "" ? "content_paste_off" : "search_off"
                    font: Tokens.font.headline.large
                    color: Colours.palette.m3outline
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: searchInput.text === "" ? qsTr("No clipboard history") : qsTr("No results found")
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3outline
                }
            }
        }

        // Footer
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledText {
                text: filteredModel.count + " " + qsTr("items")
                font: Tokens.font.label.large
                color: Colours.palette.m3outline
            }

            Item { Layout.fillWidth: true }

            IconButton {
                icon: "delete_sweep"
                onClicked: root.wipeAll()
            }

            IconButton {
                icon: "close"
                onClicked: root.visibilities.clipboard = false
            }
        }
    }
}
