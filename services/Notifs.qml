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

    // CNS: this file had no logging at all, so the notification path could
    // only be judged by the absence of QML warnings - which is exactly how
    // the close()/dismiss() bug survived, since a failed call still surfaces
    // as only a scene warning. These confirm the path positively: received,
    // tracked or suppressed, popped up or dropped, and cleared.
    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.notifs"
        defaultLogLevel: LoggingCategory.Info
    }

    function hasFullscreen(): bool {
        return Niri.hasFullscreen;
    }

    function shouldShowPopup(): bool {
        if (props.dnd) {
            console.log(lc, "popup suppressed: dnd is on");
            return false;
        }
        console.log(lc, "popup allowed: dnd is off");
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
                    notificationId: n.notificationId,
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
            console.log(lc, `received: id=${notif.id} app="${notif.appName}" summary="${notif.summary}" urgency=${notif.urgency} resident=${notif.resident}`);

            // Suppress internal screenshot notifications from workspace preview captures
            if (notif.appName === "niri" && notif.summary === "Screenshot captured") {
                notif.tracked = false;
                // CNS: quickshell's Notification exposes dismiss(), not close().
                // close() threw "Property 'close' ... is not a func", so
                // screenshot notifications were never suppressed and the
                // clear-all IPC never cleared anything. main has this bug too.
                console.log(lc, `suppressing niri screenshot notification, dismissing id=${notif.id}`);
                notif.dismiss();
                console.log(lc, `screenshot notification dismissed id=${notif.id}`);
                return;
            }

            notif.tracked = true;

            if (notif.hints?.["suppress-sound"]) {
                // skip — app explicitly asked for silence
                console.log(lc, `app requested silence: ${notif.summary}`);
            } else if (notif.hints?.["sound-file"]) {
                notifSound.source = root.resolveSoundUrl(notif.hints["sound-file"]);
                notifSound.play();
                console.log(lc, `sound-file: ${notifSound.source}`);
            } else if (notif.hints?.["sound-name"]) {
                notifSound.source = "file:///usr/share/sounds/freedesktop/stereo/" + notif.hints["sound-name"] + ".oga";
                notifSound.play();
                console.log(lc, `sound-name: ${notif.hints["sound-name"]}`);
            } else {
                root.playDefaultSound(notif.urgency, notif.appName);
                console.log(lc, `default sound played for "${notif.appName}"`);
            }

            const comp = notifComp.createObject(root, {
                popup: root.shouldShowPopup(),
                notification: notif
            });
            if (!comp) {
                console.warn(lc, `createObject returned null for id=${notif.id} - notification will not appear`);
            } else {
                console.log(lc, `tracked: id=${notif.id} popup=${comp.popup} listSize=${root.list.length + 1}`);
            }
            root.list = [comp, ...root.list];
        }
    }

    Component.onCompleted: console.log(lc, "notification server up, actionsSupported:", server.actionsSupported)

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
            for (const notif of data) {
                const properties = Object.assign({}, notif);

                // Backwards compatibility for old notifications
                if (properties.notificationId === undefined && properties.id !== undefined)
                    properties.notificationId = properties.id;

                delete properties.id;
                root.list.push(notifComp.createObject(root, properties));
            }
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
            const items = root.list.slice();
            console.log(lc, `clear(): closing ${items.length} notification(s)`);
            let failed = 0;
            for (const notif of items) {
                // root.list holds NotifData wrappers, not raw Notifications.
                // NotifData.close() is the correct call here - it delegates to
                // notification?.dismiss() internally. Calling dismiss() directly
                // on the wrapper throws "Property 'dismiss' ... is not a func".
                try {
                    notif.close();
                } catch (e) {
                    failed++;
                    console.warn(lc, `clear(): close failed: ${e}`);
                }
            }
            console.log(lc, `clear(): done, ${items.length - failed} closed, ${failed} failed, list=${root.list.length}`);
        }

        function isDndEnabled(): bool {
            return props.dnd;
        }

        function toggleDnd(): void {
            props.dnd = !props.dnd;
            console.log(lc, `dnd toggled -> ${props.dnd}`);
        }

        function enableDnd(): void {
            props.dnd = true;
            console.log(lc, "dnd enabled via IPC");
        }

        function disableDnd(): void {
            props.dnd = false;
            console.log(lc, "dnd disabled via IPC");
        }

        target: "notifs"
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
