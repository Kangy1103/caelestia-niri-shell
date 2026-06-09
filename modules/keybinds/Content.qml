pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import Caelestia.Config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    required property var wrapper
    required property PersistentProperties visibilities

    readonly property int padding: Math.max(Config.appearance.padding.largeIncreased, Config.border.rounding)

    implicitWidth: 480
    implicitHeight: mainLayout.implicitHeight + padding * 2

    ListModel { id: filteredModel }

    function filterKeybinds() {
        const query = searchInput.text.toLowerCase()
        filteredModel.clear()
        for (const bind of Keybinds.keybinds) {
            if (query === "" ||
                bind.key.toLowerCase().includes(query) ||
                bind.action.toLowerCase().includes(query)) {
                filteredModel.append(bind)
            }
        }
        if (filteredModel.count > 0) {
            listView.currentIndex = 0
        }
    }

    Connections {
        target: Keybinds
        function onKeybindsChanged(): void { filterKeybinds() }
    }

    Connections {
        target: root.visibilities
        function onKeybindsChanged(): void {
            if (root.visibilities.keybinds) {
                filterKeybinds()
                Qt.callLater(() => searchInput.forceActiveFocus())
            } else {
                searchInput.text = ""
            }
        }
    }

    Component.onCompleted: {
        if (Keybinds.initialized) {
            filterKeybinds()
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.padding
        spacing: Config.appearance.spacing.large
        anchors.leftMargin: root.padding
        anchors.rightMargin: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.appearance.spacing.large
            MaterialIcon {
                text: "keyboard"
                fontStyle: Tokens.font.icon.size(Config.appearance.font.title.medium.size).build()
color: Colours.palette.m3primary
            }
            StyledText {
                text: qsTr("Keybinds")
                font.pointSize: Config.appearance.font.title.medium.size
                font.weight: Font.Bold
                Layout.fillWidth: true
            }
            StyledRect {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Config.appearance.rounding.small
                color: "transparent"
                StateLayer {
                    radius: parent.radius
                    color: Colours.palette.m3onSurface
                    function onClicked(): void { Keybinds.refresh() }
                }
                MaterialIcon {
                    anchors.centerIn: parent
                    text: "refresh"
                    fontStyle: Tokens.font.icon.size(Config.appearance.font.body.large.size).build()
color: Colours.palette.m3onSurfaceVariant
                }
            }
            StyledRect {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Config.appearance.rounding.small
                color: "transparent"
                StateLayer {
                    radius: parent.radius
                    color: Colours.palette.m3onSurface
                    function onClicked(): void { root.visibilities.keybinds = false }
                }
                MaterialIcon {
                    anchors.centerIn: parent
                    text: "close"
                    fontStyle: Tokens.font.icon.size(Config.appearance.font.body.large.size).build()
color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(searchIcon.implicitHeight, searchInput.implicitHeight, clearIcon.implicitHeight)
            radius: Config.appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainer
            MaterialIcon {
                id: searchIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Config.appearance.padding.medium
                text: "search"
                color: Colours.palette.m3onSurfaceVariant
            }
            StyledTextField {
                id: searchInput
                anchors.left: searchIcon.right
                anchors.right: clearIcon.left
                anchors.leftMargin: Config.appearance.spacing.small
                anchors.rightMargin: Config.appearance.spacing.small
                topPadding: Config.appearance.padding.large
                bottomPadding: Config.appearance.padding.large
                placeholderText: qsTr("Search keybinds...")
                onTextChanged: filterKeybinds()
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Down) {
                        listView.forceActiveFocus()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        if (text === "") {
                            root.visibilities.keybinds = false
                        } else {
                            text = ""
                        }
                        event.accepted = true
                    }
                }
            }
            MaterialIcon {
                id: clearIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Config.appearance.padding.medium
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
                Behavior on width { Anim { duration: Config.appearance.anim.durations.small } }
                Behavior on opacity { Anim { duration: Config.appearance.anim.durations.small } }
            }
        }

        StyledClippingRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 400
            radius: Config.appearance.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            StyledListView {
                id: listView
                anchors.fill: parent
                anchors.margins: Config.appearance.padding.small
                model: filteredModel
                spacing: Config.appearance.spacing.small
                currentIndex: 0
                highlightFollowsCurrentItem: true
                clip: true
                highlightMoveDuration: Config.appearance.anim.durations.normal
                highlightResizeDuration: 0
                highlight: StyledRect {
                    radius: Config.appearance.rounding.small
                    color: Colours.palette.m3onSurface
                    opacity: 0.08
                }

                delegate: Item {
                    id: keybindItem
                    required property int index
                    required property string key
                    required property string action

                    width: listView.width
                    height: keybindContent.implicitHeight + Config.appearance.padding.small * 2

                    StyledRect {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: Config.appearance.rounding.small
                        color: "transparent"
                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onSurface
                            function onClicked(): void {
                                listView.currentIndex = keybindItem.index
                            }
                        }
                        RowLayout {
                            id: keybindContent
                            anchors.fill: parent
                            anchors.margins: Config.appearance.padding.small
                            spacing: Config.appearance.spacing.large
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Config.appearance.spacing.extraSmall
                                StyledText {
                                    Layout.fillWidth: true
                                    text: keybindItem.action
                                    font.pointSize: Config.appearance.font.label.large.size
                                    font.weight: Font.Medium
                                    color: Colours.palette.m3onSurface
                                    elide: Text.ElideRight
                                }
                                StyledRect {
                                    Layout.preferredWidth: keyText.implicitWidth + Config.appearance.padding.medium * 2
                                    Layout.preferredHeight: keyText.implicitHeight + Config.appearance.padding.small * 2
                                    radius: Config.appearance.rounding.extraSmall
                                    color: Colours.tPalette.m3surfaceContainerHighest
                                    StyledText {
                                        id: keyText
                                        anchors.centerIn: parent
                                        text: keybindItem.key
                                        font.pointSize: Config.appearance.font.label.medium.size
                                        font.family: "monospace"
                                        color: Colours.palette.m3onSurfaceVariant
                                    }
                                }
                            }
                        }
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Down && currentIndex < count - 1) {
                        currentIndex++
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        if (currentIndex > 0) {
                            currentIndex--
                        } else {
                            searchInput.forceActiveFocus()
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        root.visibilities.keybinds = false
                        event.accepted = true
                    }
                }

                ScrollBar.vertical: StyledScrollBar {}
            }

            Column {
                visible: filteredModel.count === 0 && !Keybinds.loading && !Keybinds.error
                anchors.centerIn: parent
                spacing: Config.appearance.spacing.large
                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: searchInput.text === "" ? "keyboard_hide" : "search_off"
                    fontStyle: Tokens.font.icon.size(Config.appearance.font.headline.large.size).build()
color: Colours.palette.m3outline
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: searchInput.text === "" ? qsTr("No keybinds found") : qsTr("No results found")
                    font.pointSize: Config.appearance.font.body.medium.size
                    color: Colours.palette.m3outline
                }
            }

            Column {
                visible: Keybinds.error && !Keybinds.loading
                anchors.centerIn: parent
                spacing: Config.appearance.spacing.large
                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "error_outline"
                    fontStyle: Tokens.font.icon.size(Config.appearance.font.headline.large.size).build()
color: Colours.palette.m3error
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Keybinds.error
                    font.pointSize: Config.appearance.font.body.medium.size
                    color: Colours.palette.m3error
                }
            }

            Column {
                visible: Keybinds.loading
                anchors.centerIn: parent
                spacing: Config.appearance.spacing.large
                StyledBusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: true
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Loading keybinds...")
                    font.pointSize: Config.appearance.font.body.medium.size
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.appearance.spacing.large
            StyledText {
                text: filteredModel.count + " " + qsTr("keybinds")
                font.pointSize: Config.appearance.font.label.large.size
                color: Colours.palette.m3outline
            }
            Item { Layout.fillWidth: true }
            RowLayout {
                spacing: Config.appearance.spacing.small
                MaterialIcon {
                    text: "info"
                    fontStyle: Tokens.font.icon.size(Config.appearance.font.label.medium.size).build()
color: Colours.palette.m3outline
                }
                StyledText {
                    text: qsTr("Arrow keys to navigate")
                    font.pointSize: Config.appearance.font.label.medium.size
                    color: Colours.palette.m3outline
                }
            }
        }
    }
}
