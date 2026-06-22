pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import CNS
import CNS.Config
import qs.components.misc
import qs.services
import qs.utils
import QtMultimedia

Singleton {
    id: root

    property list<NotifData> list: []
    readonly property list<NotifData> notClosed: list.filter(n => !n.closed)
    readonly property list<NotifData> popups: list.filter(n => n.popup)
    property alias dnd: props.dnd

    property bool loaded

    function hasFullscreen(): bool {
        return Niri.hasFullscreen;
    }

    function shouldShowPopup(): bool {
        if (props.dnd)
            return false;
        return true;
    }

    onDndChanged: {
        if (!GlobalConfig.utilities.toasts.dndChanged)
            return;

        if (dnd)
            Toaster.toast(qsTr("Do not disturb enabled"), qsTr("Popup notifications are now disabled"), "do_not_disturb_on");
        else
            Toaster.toast(qsTr("Do not disturb disabled"), qsTr("Popup notifications are now enabled"), "do_not_disturb_off");
    }

    onListChanged: {
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: storage.setText(JSON.stringify(root.notClosed.map(n => ({
                    time: n.time,
                    id: n.id,
                    summary: n.summary,
                    body: n.body,
                    appIcon: n.appIcon,
                    appName: n.appName,
                    image: n.image,
                    expireTimeout: n.expireTimeout,
                    urgency: n.urgency,
                    resident: n.resident,
                    hasActionIcons: n.hasActionIcons,
                    actions: n.actions
                }))))
    }

    PersistentProperties {
        id: props

        property bool dnd

        reloadableId: "notifs"
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            // Suppress internal screenshot notifications from workspace preview captures
            if (notif.appName === "niri" && notif.summary === "Screenshot captured") {
                notif.tracked = false;
                notif.close();
                return;
            }

            notif.tracked = true;

            if (notif.hints?.["suppress-sound"]) {
                // skip — app explicitly asked for silence
            } else if (notif.hints?.["sound-file"]) {
                notifSound.source = root.resolveSoundUrl(notif.hints["sound-file"]);
                notifSound.play();
            } else if (notif.hints?.["sound-name"]) {
                notifSound.source = "file:///usr/share/sounds/freedesktop/stereo/" + notif.hints["sound-name"] + ".oga";
                notifSound.play();
            } else {
                root.playDefaultSound(notif.urgency, notif.appName);
            }

            const comp = notifComp.createObject(root, {
                popup: root.shouldShowPopup(),
                notification: notif
            });
            root.list = [comp, ...root.list];
        }
    }

    function resolveSoundUrl(configPath: string): string {
        if (configPath.startsWith("root:"))
            return "file://" + Quickshell.shellPath(configPath.substring(5));
        if (configPath.startsWith("/"))
            return "file://" + configPath;
        return configPath;
    }

    function isElectronApp(appName: string): bool {
        if (!appName) return false;
        const name = appName.toLowerCase();
        const knownElectron = [
            "discord", "vesktop", "webcord", "armcord", "vencord",
            "code", "code-oss", "vscodium", "vscode",
            "slack", "skype", "teams", "element", "riot",
            "opencode", "opencode desktop",
            "spotify", "postman", "figma", "notion",
            "brave", "chromium", "google-chrome"
        ];
        for (const pattern of knownElectron) {
            if (name.indexOf(pattern) !== -1)
                return true;
        }
        return false;
    }

    function playDefaultSound(urgency: int, appName: string): void {
        if (!GlobalConfig.notifs.soundEnabled)
            return;

        const soundPath = urgency === NotificationUrgency.Critical
            ? GlobalConfig.notifs.soundCritical
            : GlobalConfig.notifs.soundNormal;

        if (!soundPath)
            return;

        if (isElectronApp(appName))
            return;

        notifSound.source = root.resolveSoundUrl(soundPath);
        notifSound.play();
    }

    SoundEffect {
        id: notifSound
        volume: 0.5
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/notifs.json`
        onLoaded: {
            const data = JSON.parse(text());
            for (const notif of data)
                root.list.push(notifComp.createObject(root, notif));
            root.list.sort((a, b) => b.time - a.time);
            root.loaded = true;
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loaded = true;
                Qt.callLater(() => setText("[]"));
            }
        }
    }

    IpcHandler {
        function clear(): void {
            for (const notif of root.list.slice())
                notif.close();
        }

        function isDndEnabled(): bool {
            return props.dnd;
        }

        function toggleDnd(): void {
            props.dnd = !props.dnd;
        }

        function enableDnd(): void {
            props.dnd = true;
        }

        function disableDnd(): void {
            props.dnd = false;
        }

        target: "notifs"
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
