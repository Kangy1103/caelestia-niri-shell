pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import CNS
import CNS.Config
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> fullscreenItems: [
        MenuItem { text: qsTr("Show") },
        MenuItem { text: qsTr("Hide") }
    ]
    readonly property list<string> fullscreenValues: ["on", "off"]

    function fullscreenKeyToIndex(key: string): int {
        return key === "on" ? 0 : 1;
    }

    title: qsTr("Notifications & popups")

    resources: [
        Component {
            id: menuItemComp
            MenuItem {}
        }
    ]

    Component.onCompleted: {
        function buildItems(subdir) {
            const path = Quickshell.shellPath("assets/sounds/" + subdir);
            const files = CUtils.listDir(path, ["*.wav", "*.oga", "*.ogg", "*.flac"]);
            files.sort();
            var items = [menuItemComp.createObject(null, { text: qsTr("None") })];
            for (var i = 0; i < files.length; i++)
                items.push(menuItemComp.createObject(null, { text: files[i] }));
            items.push(menuItemComp.createObject(null, { text: qsTr("Browse...") }));
            return items;
        }
        normalSound.items = buildItems("normal");
        normalSound.menuItems = normalSound.items;
        criticalSound.items = buildItems("critical");
        criticalSound.menuItems = criticalSound.items;
        unlockSound.items = buildItems("unlock");
        unlockSound.menuItems = unlockSound.items;
        loginSound.items = buildItems("login");
        loginSound.menuItems = loginSound.items;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // ── Notifications ──
        SectionHeader {
            first: true
            text: qsTr("Notifications")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Expire")
            subtext: qsTr("Automatically dismiss notifications after a timeout")
            checked: GlobalConfig.notifs.expire
            onToggled: GlobalConfig.notifs.expire = checked
        }

        SelectRow {
            Layout.fillWidth: true
            label: qsTr("Fullscreen behaviour")
            subtext: qsTr("How notifications behave during fullscreen apps")
            menuItems: root.fullscreenItems
            active: root.fullscreenItems[root.fullscreenKeyToIndex(GlobalConfig.notifs.fullscreen)]
            onSelected: item => GlobalConfig.notifs.fullscreen = root.fullscreenValues[root.fullscreenItems.indexOf(item)]
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Expire timeout")
            subtext: qsTr("How long notifications stay visible (ms)")
            value: GlobalConfig.notifs.defaultExpireTimeout
            from: 1000
            to: 30000
            stepSize: 500
            onMoved: v => GlobalConfig.notifs.defaultExpireTimeout = v
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Fullscreen timeout")
            subtext: qsTr("Expire timeout during fullscreen (ms)")
            value: GlobalConfig.notifs.fullscreenExpireTimeout
            from: 500
            to: 10000
            stepSize: 500
            onMoved: v => GlobalConfig.notifs.fullscreenExpireTimeout = v
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Clear threshold")
            subtext: qsTr("Swipe distance to dismiss a notification")
            value: Config.notifs.clearThreshold
            from: 0.1
            to: 1.0
            stepSize: 0.05
            onMoved: v => GlobalConfig.notifs.clearThreshold = v
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Expand threshold")
            subtext: qsTr("Pixels to scroll before expanding a notification group")
            value: Config.notifs.expandThreshold
            from: 5
            to: 100
            stepSize: 5
            onMoved: v => GlobalConfig.notifs.expandThreshold = v
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Action on click")
            subtext: qsTr("Trigger the default action when clicking a notification")
            checked: GlobalConfig.notifs.actionOnClick
            onToggled: GlobalConfig.notifs.actionOnClick = checked
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Group preview")
            subtext: qsTr("Number of notifications shown in a collapsed group")
            value: Config.notifs.groupPreviewNum
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.notifs.groupPreviewNum = v
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Open expanded")
            subtext: qsTr("Show notification groups already expanded")
            checked: Config.notifs.openExpanded
            onToggled: GlobalConfig.notifs.openExpanded = checked
        }

        // ── Sounds ──
        SectionHeader {
            text: qsTr("Sounds")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Notification sounds")
            subtext: qsTr("Play a sound when a notification arrives")
            checked: GlobalConfig.notifs.soundEnabled
            onToggled: GlobalConfig.notifs.soundEnabled = checked
        }

        SelectRow {
            id: normalSound
            Layout.fillWidth: true

            property list<MenuItem> items: [
                MenuItem { text: qsTr("None") },
                MenuItem { text: qsTr("Browse...") }
            ]

            label: qsTr("Normal sound")
            subtext: qsTr("Played for normal and low urgency notifications")
            menuItems: items
            active: {
                const path = GlobalConfig.notifs.soundNormal;
                if (!path) return items[0];
                for (let i = 1; i < items.length - 1; i++) {
                    if (path.endsWith("/" + items[i].text))
                        return items[i];
                }
                return null;
            }
            fallbackText: {
                const path = GlobalConfig.notifs.soundNormal;
                if (!path) return "";
                const parts = path.split("/");
                return parts[parts.length - 1] || path;
            }
            onSelected: item => {
                const idx = items.indexOf(item);
                if (idx === 0)
                    GlobalConfig.notifs.soundNormal = "";
                else if (idx === items.length - 1)
                    browseNormal.open();
                else
                    GlobalConfig.notifs.soundNormal = "root:/assets/sounds/normal/" + item.text;
            }

            FileDialog {
                id: browseNormal
                title: qsTr("Select normal notification sound")
                filterLabel: qsTr("Audio files")
                filters: ["wav", "oga", "mp3", "flac"]
                showHidden: true
                onAccepted: path => GlobalConfig.notifs.soundNormal = path
            }
        }

        SelectRow {
            id: criticalSound
            Layout.fillWidth: true

            property list<MenuItem> items: [
                MenuItem { text: qsTr("None") },
                MenuItem { text: qsTr("Browse...") }
            ]

            label: qsTr("Critical sound")
            subtext: qsTr("Played for critical urgency notifications")
            menuItems: items
            active: {
                const path = GlobalConfig.notifs.soundCritical;
                if (!path) return items[0];
                for (let i = 1; i < items.length - 1; i++) {
                    if (path.endsWith("/" + items[i].text))
                        return items[i];
                }
                return null;
            }
            fallbackText: {
                const path = GlobalConfig.notifs.soundCritical;
                if (!path) return "";
                const parts = path.split("/");
                return parts[parts.length - 1] || path;
            }
            onSelected: item => {
                const idx = items.indexOf(item);
                if (idx === 0)
                    GlobalConfig.notifs.soundCritical = "";
                else if (idx === items.length - 1)
                    browseCritical.open();
                else
                    GlobalConfig.notifs.soundCritical = "root:/assets/sounds/critical/" + item.text;
            }

            FileDialog {
                id: browseCritical
                title: qsTr("Select critical notification sound")
                filterLabel: qsTr("Audio files")
                filters: ["wav", "oga", "mp3", "flac"]
                showHidden: true
                onAccepted: path => GlobalConfig.notifs.soundCritical = path
            }
        }

        SelectRow {
            id: unlockSound
            Layout.fillWidth: true

            property list<MenuItem> items: [
                MenuItem { text: qsTr("None") },
                MenuItem { text: qsTr("Browse...") }
            ]

            label: qsTr("Unlock sound")
            subtext: qsTr("Played when the session is unlocked")
            menuItems: items
            active: {
                const path = GlobalConfig.notifs.soundUnlock;
                if (!path) return items[0];
                for (let i = 1; i < items.length - 1; i++) {
                    if (path.endsWith("/" + items[i].text))
                        return items[i];
                }
                return null;
            }
            fallbackText: {
                const path = GlobalConfig.notifs.soundUnlock;
                if (!path) return "";
                const parts = path.split("/");
                return parts[parts.length - 1] || path;
            }
            onSelected: item => {
                const idx = items.indexOf(item);
                if (idx === 0)
                    GlobalConfig.notifs.soundUnlock = "";
                else if (idx === items.length - 1)
                    browseUnlock.open();
                else
                    GlobalConfig.notifs.soundUnlock = "root:/assets/sounds/unlock/" + item.text;
            }

            FileDialog {
                id: browseUnlock
                title: qsTr("Select unlock sound")
                filterLabel: qsTr("Audio files")
                filters: ["wav", "oga", "mp3", "flac"]
                showHidden: true
                onAccepted: path => GlobalConfig.notifs.soundUnlock = path
            }
        }

        SelectRow {
            id: loginSound
            Layout.fillWidth: true
            last: true

            property list<MenuItem> items: [
                MenuItem { text: qsTr("None") },
                MenuItem { text: qsTr("Browse...") }
            ]

            label: qsTr("Login sound")
            subtext: qsTr("Played when logging in (greeter only)")
            menuItems: items
            active: {
                const path = GlobalConfig.notifs.soundLogin;
                if (!path) return items[0];
                for (let i = 1; i < items.length - 1; i++) {
                    if (path.endsWith("/" + items[i].text))
                        return items[i];
                }
                return null;
            }
            fallbackText: {
                const path = GlobalConfig.notifs.soundLogin;
                if (!path) return "";
                const parts = path.split("/");
                return parts[parts.length - 1] || path;
            }
            onSelected: item => {
                const idx = items.indexOf(item);
                if (idx === 0)
                    GlobalConfig.notifs.soundLogin = "";
                else if (idx === items.length - 1)
                    browseLogin.open();
                else
                    GlobalConfig.notifs.soundLogin = "root:/assets/sounds/login/" + item.text;
            }

            FileDialog {
                id: browseLogin
                title: qsTr("Select login sound")
                filterLabel: qsTr("Audio files")
                filters: ["wav", "oga", "mp3", "flac"]
                showHidden: true
                onAccepted: path => GlobalConfig.notifs.soundLogin = path
            }
        }

        // ── On-Screen Display (OSD) ──
        SectionHeader {
            text: qsTr("On-screen display")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Enabled")
            checked: Config.osd.enabled
            onToggled: GlobalConfig.osd.enabled = checked
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Hide delay")
            subtext: qsTr("How long the OSD stays visible (ms)")
            value: Config.osd.hideDelay
            from: 500
            to: 5000
            stepSize: 100
            onMoved: v => GlobalConfig.osd.hideDelay = v
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Brightness indicator")
            subtext: qsTr("Show OSD when changing brightness")
            checked: Config.osd.enableBrightness
            onToggled: GlobalConfig.osd.enableBrightness = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Microphone indicator")
            subtext: qsTr("Show OSD when microphone is toggled")
            checked: Config.osd.enableMicrophone
            onToggled: GlobalConfig.osd.enableMicrophone = checked
        }

        // ── Toasts ──
        SectionHeader {
            text: qsTr("Toasts")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Utilities enabled")
            checked: Config.utilities.enabled
            onToggled: GlobalConfig.utilities.enabled = checked
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Max toasts")
            subtext: qsTr("Maximum number of visible toasts at once")
            value: Config.utilities.maxToasts
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.utilities.maxToasts = v
        }

        SectionHeader {
            text: qsTr("Toast events")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Config loaded")
            checked: GlobalConfig.utilities.toasts.configLoaded
            onToggled: GlobalConfig.utilities.toasts.configLoaded = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Charging changed")
            checked: GlobalConfig.utilities.toasts.chargingChanged
            onToggled: GlobalConfig.utilities.toasts.chargingChanged = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Game mode changed")
            checked: GlobalConfig.utilities.toasts.gameModeChanged
            onToggled: GlobalConfig.utilities.toasts.gameModeChanged = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Do not disturb")
            checked: GlobalConfig.utilities.toasts.dndChanged
            onToggled: GlobalConfig.utilities.toasts.dndChanged = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Audio output changed")
            checked: GlobalConfig.utilities.toasts.audioOutputChanged
            onToggled: GlobalConfig.utilities.toasts.audioOutputChanged = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Audio input changed")
            checked: GlobalConfig.utilities.toasts.audioInputChanged
            onToggled: GlobalConfig.utilities.toasts.audioInputChanged = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Caps lock")
            checked: GlobalConfig.utilities.toasts.capsLockChanged
            onToggled: GlobalConfig.utilities.toasts.capsLockChanged = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Num lock")
            checked: GlobalConfig.utilities.toasts.numLockChanged
            onToggled: GlobalConfig.utilities.toasts.numLockChanged = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Keyboard layout")
            checked: GlobalConfig.utilities.toasts.kbLayoutChanged
            onToggled: GlobalConfig.utilities.toasts.kbLayoutChanged = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Keyboard limit")
            checked: GlobalConfig.utilities.toasts.kbLimit
            onToggled: GlobalConfig.utilities.toasts.kbLimit = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("VPN changed")
            checked: GlobalConfig.utilities.toasts.vpnChanged
            onToggled: GlobalConfig.utilities.toasts.vpnChanged = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Now playing")
            checked: GlobalConfig.utilities.toasts.nowPlaying
            onToggled: GlobalConfig.utilities.toasts.nowPlaying = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Niri config reloaded")
            subtext: qsTr("CNS-specific: toast when niri config is reloaded")
            checked: GlobalConfig.utilities.toasts.niriConfigLoaded
            onToggled: GlobalConfig.utilities.toasts.niriConfigLoaded = checked
        }
    }
}
