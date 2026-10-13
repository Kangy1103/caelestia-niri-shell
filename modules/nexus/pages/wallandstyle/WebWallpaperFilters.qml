// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260614

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CNS.Config
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    required property var gridRoot

    spacing: Tokens.spacing.medium

    function switchServer(server) {
        gridRoot.currentServer = server;
        gridRoot.keyword = "";
        searchField.text = "";
        if (server === "uhdpaper") {
            gridRoot.resolution = "2k";
            gridRoot.fetchCategories();
        } else if (server === "bing") {
            gridRoot.resolution = "UHD";
            gridRoot.categoriesList = [];
                } else if (server === "nasa" || server === "reddit") {
                    gridRoot.resolution = "";
                    gridRoot.categoriesList = [];
                } else if (server === "flare") {
                    gridRoot.resolution = "3840x2160";
                    gridRoot.categoriesList = [];
                } else {
            gridRoot.resolution = "1920x1080";
            gridRoot.categoriesList = [];
        }
        gridRoot.fetchWallpapers();
    }

    RowLayout {
        spacing: Tokens.spacing.medium
        Layout.fillWidth: true
        z: 1

        IconTextButton {
            id: serverButton

            Layout.preferredWidth: 140
            Layout.preferredHeight: 40
            text: {
                const s = gridRoot.currentServer;
                if (s === "uhdpaper") return "UHDpaper";
                if (s === "wallhaven") return "Wallhaven";
                if (s === "bing") return "Bing";
                if (s === "nasa") return "NASA";
                if (s === "flare") return "Flare";
                return "Reddit";
            }
            icon: {
                const s = gridRoot.currentServer;
                if (s === "uhdpaper") return "cloud";
                if (s === "wallhaven") return "explore";
                if (s === "bing") return "image_search";
                if (s === "nasa") return "rocket_launch";
                if (s === "flare") return "gradient";
                return "forum";
            }
            type: IconTextButton.Tonal
            onClicked: serverMenu.expanded = !serverMenu.expanded

            Menu {
                id: serverMenu

                attachTo: serverButton
                expanded: false

                items: [
                    MenuItem {
                        text: "UHDpaper"
                        icon: "cloud"
                        activeIcon: gridRoot.currentServer === "uhdpaper" ? "check" : ""
                        onClicked: root.switchServer("uhdpaper")
                    },
                    MenuItem {
                        text: "Wallhaven"
                        icon: "explore"
                        activeIcon: gridRoot.currentServer === "wallhaven" ? "check" : ""
                        onClicked: root.switchServer("wallhaven")
                    },
                    MenuItem {
                        text: "Bing"
                        icon: "image_search"
                        activeIcon: gridRoot.currentServer === "bing" ? "check" : ""
                        onClicked: root.switchServer("bing")
                    },
                    MenuItem {
                        text: "NASA"
                        icon: "rocket_launch"
                        activeIcon: gridRoot.currentServer === "nasa" ? "check" : ""
                        onClicked: root.switchServer("nasa")
                    },
                    MenuItem {
                        text: "Wallpaper Flare"
                        icon: "gradient"
                        activeIcon: gridRoot.currentServer === "flare" ? "check" : ""
                        onClicked: root.switchServer("flare")
                    },
                    MenuItem {
                        text: "Reddit"
                        icon: "forum"
                        activeIcon: gridRoot.currentServer === "reddit" ? "check" : ""
                        onClicked: root.switchServer("reddit")
                    }
                ]
            }

            Tooltip { target: serverButton; text: qsTr("Choose wallpaper source") }
        }

        StyledTextField {
            id: searchField

            Layout.fillWidth: true
            placeholderText: qsTr("Search wallpapers...")
            text: gridRoot.keyword
            onTextChanged: gridRoot.keyword = text
            onAccepted: gridRoot.fetchWallpapers()
        }

        IconButton {
            id: searchButton

            icon: "search"
            onClicked: gridRoot.fetchWallpapers()
            enabled: !gridRoot.loading
            Tooltip { target: searchButton; text: qsTr("Search") }
        }

        IconButton {
            id: randomButton

            icon: "casino"
            onClicked: {
                searchField.text = "";
                gridRoot.keyword = "";
                gridRoot.fetchWallpapers();
            }
            enabled: !gridRoot.loading
            Tooltip { target: randomButton; text: qsTr("Random") }
        }
    }

    Flow {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.extraSmall
        Layout.bottomMargin: Tokens.spacing.extraSmall
        spacing: Tokens.spacing.small
        visible: gridRoot.categoriesList.length > 0 && gridRoot.currentServer === "uhdpaper"

        Repeater {
            model: gridRoot.categoriesList
            delegate: TextButton {
                required property var modelData
                text: modelData.name.charAt(0).toUpperCase() + modelData.name.slice(1)
                checked: gridRoot.keyword.toLowerCase() === modelData.name.toLowerCase()
                onClicked: {
                    gridRoot.keyword = modelData.name;
                    searchField.text = modelData.name;
                    gridRoot.fetchWallpapers();
                }
                type: checked ? TextButton.Filled : TextButton.Tonal
                font: Tokens.font.label.builders.large.weight(Font.Medium).build()
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        spacing: Tokens.spacing.medium
        visible: gridRoot.currentServer === "wallhaven"

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraLargeIncreased

            ColumnLayout {
                spacing: Tokens.spacing.extraSmall
                Layout.alignment: Qt.AlignTop
                StyledText {
                    text: qsTr("Categories")
                    font: Tokens.font.label.builders.large.weight(Font.DemiBold).build()
                    color: Colours.palette.m3primary
                }
                RowLayout {
                    spacing: Tokens.spacing.extraSmall
                    Repeater {
                        model: ["General", "Anime", "People"]
                        delegate: TextButton {
                            required property var modelData
                            text: modelData
                            checked: gridRoot.wallhavenCategories.indexOf(modelData.toLowerCase()) !== -1
                            onClicked: {
                                let cat = modelData.toLowerCase();
                                let list = [];
                                for (let i = 0; i < gridRoot.wallhavenCategories.length; i++) list.push(gridRoot.wallhavenCategories[i]);
                                let idx = list.indexOf(cat);
                                if (idx === -1) list.push(cat);
                                else if (list.length > 1) list.splice(idx, 1);
                                gridRoot.wallhavenCategories = list;
                                gridRoot.fetchWallpapers();
                            }
                            type: checked ? TextButton.Filled : TextButton.Tonal
                            font: Tokens.font.label.builders.medium.weight(Font.Medium).build()
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: Tokens.spacing.extraSmall
                Layout.alignment: Qt.AlignTop
                StyledText {
                    text: qsTr("Purity")
                    font: Tokens.font.label.builders.large.weight(Font.DemiBold).build()
                    color: Colours.palette.m3primary
                }
                RowLayout {
                    spacing: Tokens.spacing.extraSmall
                    Repeater {
                        model: gridRoot.wallhavenHasApiKey ? ["SFW", "Sketchy", "NSFW"] : ["SFW", "Sketchy"]
                        delegate: TextButton {
                            required property var modelData
                            text: modelData
                            checked: gridRoot.wallhavenPurity.indexOf(modelData.toLowerCase()) !== -1
                            onClicked: {
                                let p = modelData.toLowerCase();
                                let list = [];
                                for (let i = 0; i < gridRoot.wallhavenPurity.length; i++) list.push(gridRoot.wallhavenPurity[i]);
                                let idx = list.indexOf(p);
                                if (idx === -1) list.push(p);
                                else if (list.length > 1) list.splice(idx, 1);
                                gridRoot.wallhavenPurity = list;
                                gridRoot.fetchWallpapers();
                            }
                            type: checked ? TextButton.Filled : TextButton.Tonal
                            font: Tokens.font.label.builders.medium.weight(Font.Medium).build()
                        }
                    }
                }
            }
        }

        ColumnLayout {
            spacing: Tokens.spacing.extraSmall
            StyledText {
                text: qsTr("Sorting")
                font: Tokens.font.label.builders.large.weight(Font.DemiBold).build()
                color: Colours.palette.m3primary
            }
            Flow {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall
                Repeater {
                    model: [
                        {label: qsTr("Added"), val: "date_added"},
                        {label: qsTr("Relevance"), val: "relevance"},
                        {label: qsTr("Random"), val: "random"},
                        {label: qsTr("Views"), val: "views"},
                        {label: qsTr("Favorites"), val: "favorites"},
                        {label: qsTr("Toplist"), val: "toplist"}
                    ]
                    delegate: TextButton {
                        required property var modelData
                        text: modelData.label
                        checked: gridRoot.wallhavenSort === modelData.val
                        onClicked: {
                            gridRoot.wallhavenSort = modelData.val;
                            gridRoot.fetchWallpapers();
                        }
                        type: checked ? TextButton.Filled : TextButton.Tonal
                        font: Tokens.font.label.builders.medium.weight(Font.Medium).build()
                    }
                }
            }
        }

        ColumnLayout {
            spacing: Tokens.spacing.extraSmall
            StyledText {
                text: qsTr("Color")
                font: Tokens.font.label.builders.large.weight(Font.DemiBold).build()
                color: Colours.palette.m3primary
            }
            Flow {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                IconButton {
                    id: clearColorButton

                    icon: "format_color_reset"
                    type: IconButton.Tonal
                    checked: gridRoot.wallhavenColor === ""
                    onClicked: {
                        gridRoot.wallhavenColor = "";
                        gridRoot.fetchWallpapers();
                    }
                    Tooltip { target: clearColorButton; text: qsTr("Clear color filter") }
                }

                Repeater {
                    model: ["660000", "cc0000", "ea4c88", "993399", "0066cc", "0099ff", "66cccc", "77cc33", "669900", "ffff00", "ff9900", "ff6600", "000000", "999999", "ffffff", "424153"]
                    delegate: StyledRect {
                        required property var modelData
                        width: 28
                        height: 28
                        radius: Tokens.rounding.full
                        color: "#" + modelData
                        border.width: gridRoot.wallhavenColor === modelData ? 2 : 1
                        border.color: gridRoot.wallhavenColor === modelData ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.5)

                        StateLayer {
                            anchors.fill: parent
                            radius: parent.radius
                            onClicked: {
                                if (gridRoot.wallhavenColor === modelData) gridRoot.wallhavenColor = "";
                                else gridRoot.wallhavenColor = modelData;
                                gridRoot.fetchWallpapers();
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            spacing: Tokens.spacing.extraSmall
            visible: gridRoot.wallhavenSort === "toplist"
            StyledText {
                text: qsTr("Range")
                font: Tokens.font.label.builders.large.weight(Font.DemiBold).build()
                color: Colours.palette.m3primary
            }
            RowLayout {
                spacing: Tokens.spacing.extraSmall
                Repeater {
                    model: ["1d", "1w", "1M", "3M", "1y"]
                    delegate: TextButton {
                        required property var modelData
                        text: modelData
                        checked: gridRoot.wallhavenRange === modelData
                        onClicked: {
                            gridRoot.wallhavenRange = modelData;
                            gridRoot.fetchWallpapers();
                        }
                        type: checked ? TextButton.Filled : TextButton.Tonal
                        font: Tokens.font.label.builders.medium.weight(Font.Medium).build()
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            IconTextButton {
                text: gridRoot.showApiKey ? qsTr("Hide API Settings") : qsTr("Configure API Key")
                icon: gridRoot.showApiKey ? "expand_less" : "key"
                type: IconTextButton.Text
                onClicked: gridRoot.showApiKey = !gridRoot.showApiKey
            }

            RowLayout {
                visible: gridRoot.showApiKey
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledTextField {
                    id: apiKeyField

                    Layout.fillWidth: true
                    placeholderText: qsTr("Enter Wallhaven API Key...")
                    echoMode: TextInput.Password
                    onAccepted: {
                        if (text.trim() === "") return;
                        gridRoot.saveApiKey(text.trim());
                        text = "";
                    }
                }

                IconButton {
                    id: saveApiKeyButton

                    icon: "save"
                    onClicked: {
                        gridRoot.saveApiKey(apiKeyField.text.trim());
                        apiKeyField.text = "";
                    }
                    enabled: apiKeyField.text.trim() !== ""
                    Tooltip { target: saveApiKeyButton; text: qsTr("Verify & Save Key") }
                }

                IconButton {
                    id: deleteApiKeyButton

                    icon: "delete"
                    type: IconButton.Tonal
                    onClicked: gridRoot.clearApiKey()
                    Tooltip { target: deleteApiKeyButton; text: qsTr("Clear API Key") }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        spacing: Tokens.spacing.extraLargeIncreased
        visible: gridRoot.currentServer === "uhdpaper" || gridRoot.currentServer === "wallhaven"

        ColumnLayout {
            spacing: Tokens.spacing.extraSmall
            Layout.alignment: Qt.AlignTop
            StyledText {
                text: qsTr("Resolution")
                font: Tokens.font.label.builders.large.weight(Font.DemiBold).build()
                color: Colours.palette.m3primary
            }

            RowLayout {
                spacing: Tokens.spacing.extraSmall
                Repeater {
                    model: gridRoot.currentServer === "uhdpaper" ? ["4k", "2k", "1080p"] : ["3840x2160", "3440x1440", "2560x1440", "2560x1080", "1920x1200", "1920x1080"]
                    delegate: TextButton {
                        required property var modelData
                        text: gridRoot.currentServer === "uhdpaper" ? modelData.toUpperCase() : modelData
                        checked: gridRoot.resolution === modelData
                        onClicked: gridRoot.resolution = modelData
                        type: checked ? TextButton.Filled : TextButton.Tonal
                        font: Tokens.font.label.builders.medium.weight(Font.Medium).build()
                    }
                }
            }
        }
    }
}
