pragma Singleton

import qs.modules.launcher
import qs.modules.nexus
import qs.services
import Caelestia.Config
import qs.utils
import Quickshell
import QtQuick

Searcher {
    id: root

    readonly property list<QtObject> actions: [
        Action {
            name: qsTr("Settings")
            desc: qsTr("Open the configuration editor")
            icon: "settings"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                WindowFactory.create();
            }
        },
        Action {
            name: qsTr("Calculator")
            desc: qsTr("Do simple math equations (powered by Qalc)")
            icon: "calculate"

            function onClicked(list: AppList): void {
                list.search.text = `${GlobalConfig.launcher.actionPrefix}calc `;
            }
        },
        Action {
            name: qsTr("Scheme")
            desc: qsTr("Change the current colour scheme")
            icon: "palette"

            function onClicked(list: AppList): void {
                list.search.text = `${GlobalConfig.launcher.actionPrefix}scheme `;
            }
        },
        Action {
            name: qsTr("Wallpaper")
            desc: qsTr("Change the current wallpaper")
            icon: "image"

            function onClicked(list: AppList): void {
                list.search.text = `${GlobalConfig.launcher.actionPrefix}wallpaper `;
            }
        },
        Action {
            name: qsTr("Variant")
            desc: qsTr("Change the current scheme variant")
            icon: "colors"

            function onClicked(list: AppList): void {
                list.search.text = `${GlobalConfig.launcher.actionPrefix}variant `;
            }
        },
        Action {
            name: qsTr("Clipboard")
            desc: qsTr("Search clipboard history")
            icon: "content_paste"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                list.visibilities.clipboard = true;
            }
        },
        Action {
            name: qsTr("Web Search")
            desc: qsTr("Search the web or open a URL")
            icon: "travel_explore"

            function onClicked(list: AppList): void {
                list.search.text = `${GlobalConfig.launcher.actionPrefix}web `;
            }
        },
        Action {
            name: qsTr("Emoji")
            desc: qsTr("Search and copy emojis")
            icon: "mood"

            function onClicked(list: AppList): void {
                list.search.text = `${GlobalConfig.launcher.actionPrefix}emoji `;
            }
        },
        Action {
            name: qsTr("OCR")
            desc: qsTr("Extract text from a screen region")
            icon: "document_scanner"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                const configName = Quickshell.shellDir.toString().replace(/\/$/, "").split("/").pop();
                Quickshell.execDetached(["qs", "-c", configName, "ipc", "call", "picker", "regionOcr"]);
            }
        },
        Action {
            name: qsTr("Google Lens")
            desc: qsTr("Search a screen region with Google Lens")
            icon: "image_search"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                const configName = Quickshell.shellDir.toString().replace(/\/$/, "").split("/").pop();
                Quickshell.execDetached(["qs", "-c", configName, "ipc", "call", "picker", "regionSearch"]);
            }
        },
        Action {
            name: qsTr("Transparency")
            desc: qsTr("Change shell transparency")
            icon: "opacity"
            disabled: true

            function onClicked(list: AppList): void {
                list.search.text = `${GlobalConfig.launcher.actionPrefix}transparency `;
            }
        },
        Action {
            name: qsTr("Random")
            desc: qsTr("Switch to a random wallpaper")
            icon: "casino"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                // Get a random wallpaper from the Wallpapers service
                const wallpaperList = Wallpapers.list;
                if (wallpaperList && wallpaperList.length > 0) {
                    const randomIndex = Math.floor(Math.random() * wallpaperList.length);
                    const randomWallpaper = wallpaperList[randomIndex];
                    if (randomWallpaper && randomWallpaper.path) {
                        Wallpapers.setWallpaper(randomWallpaper.path);
                    }
                }
            }
        },
        Action {
            name: qsTr("Light")
            desc: qsTr("Change the scheme to light mode")
            icon: "light_mode"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                Colours.setMode("light");
                Schemes.regenerateDynamic();
            }
        },
        Action {
            name: qsTr("Dark")
            desc: qsTr("Change the scheme to dark mode")
            icon: "dark_mode"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                Colours.setMode("dark");
                Schemes.regenerateDynamic();
            }
        },
        Action {
            name: qsTr("Shutdown")
            desc: qsTr("Shutdown the system")
            icon: "power_settings_new"
            disabled: !GlobalConfig.launcher.enableDangerousActions

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                Quickshell.execDetached(["systemctl", "poweroff"]);
            }
        },
        Action {
            name: qsTr("Reboot")
            desc: qsTr("Reboot the system")
            icon: "cached"
            disabled: !GlobalConfig.launcher.enableDangerousActions

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                Quickshell.execDetached(["systemctl", "reboot"]);
            }
        },
        Action {
            name: qsTr("Logout")
            desc: qsTr("Log out of the current session")
            icon: "exit_to_app"
            disabled: !GlobalConfig.launcher.enableDangerousActions

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                Quickshell.execDetached(["niri", "msg", "action", "quit", "-s"]);
            }
        },
        Action {
            name: qsTr("Lock")
            desc: qsTr("Lock the current session")
            icon: "lock"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                const configName = Quickshell.shellDir.toString().replace(/\/$/, "").split("/").pop();
                Quickshell.execDetached(["qs", "-c", configName, "ipc", "call", "lock", "lock"]);
            }
        }
    ]

    function transformSearch(search: string): string {
        return search.slice(GlobalConfig.launcher.actionPrefix.length);
    }

    function autocomplete(list: AppList, text: string): void {
        list.search.text = `${GlobalConfig.launcher.actionPrefix}${text} `;
    }

    list: actions.filter(a => !a.disabled)
    useFuzzy: GlobalConfig.launcher.useFuzzy.actions

    component Action: QtObject {
        required property string name
        required property string desc
        required property string icon
        property bool disabled

        function onClicked(list: AppList): void {
        }
    }
}
