pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import CNS.Config
import CNS.Services
import QtMultimedia

Scope {
    id: root

    enum PamState {
        None,
        Error,
        MaxTries,
        Failed
    }

    required property WlSessionLock lock

    readonly property alias passwd: passwd
    readonly property alias fprint: fprint
    readonly property alias howdy: howdy
    property string lockMessage
    property int state
    property string buffer

    signal flashMsg

    function resolveSoundUrl(configPath: string): string {
        if (!configPath) return "";
        if (configPath.startsWith("root:"))
            return "file://" + Quickshell.shellPath(configPath.substring(5));
        if (configPath.startsWith("/"))
            return "file://" + configPath;
        return configPath;
    }

    function playUnlockSound(): void {
        if (!GlobalConfig.notifs.soundEnabled) return;
        const url = root.resolveSoundUrl(GlobalConfig.notifs.soundUnlock);
        if (!url) return;
        unlockSound.source = url;
        unlockSound.play();
    }

    function handleKey(event: KeyEvent): void {
        if (passwd.active)
            return;

        if (howdy.canAttempt && !howdy.active && (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) && buffer.length === 0)
            return howdy.start();

        if (state === Pam.MaxTries)
            return;

        if (howdy.active)
            howdy.abort();

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            passwd.start();
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier) {
                buffer = "";
            } else {
                buffer = buffer.slice(0, -1);
            }
        } else if (/^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
            buffer += event.text;
        }
    }

    function restartFprint(): void {
        fprint.reset();
        if (fprint.canAttempt)
            fprint.start();
        else
            fprint.abort();
    }

    function clearTransientState(): void {
        for (const obj of [root, fprint, howdy])
            if (obj.state !== Pam.MaxTries)
                obj.state = Pam.None;
    }

    PamContext {
        id: passwd

        config: "passwd"
        configDirectory: Quickshell.shellPath("assets/pam.d")

        onMessageChanged: {
            if (message.startsWith("The account is locked"))
                root.lockMessage = message;
            else if (root.lockMessage && message.endsWith(" left to unlock)"))
                root.lockMessage += "\n" + message;
        }

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;

            respond(root.buffer);
            root.buffer = "";
        }

        onCompleted: res => {
            if (res === PamResult.Success) {
                root.playUnlockSound();
                return root.lock.unlock();
            }

            root.clearTransientState();

            if (res === PamResult.Error)
                root.state = Pam.Error;
            else if (res === PamResult.MaxTries)
                root.state = Pam.MaxTries;
            else if (res === PamResult.Failed)
                root.state = Pam.Failed;

            root.flashMsg();
            pwdStateReset.restart();
        }
    }

    PamContext {
        id: fprint

        property bool available
        property int state
        property int tries
        property int errorTries

        function checkAvail(): void {
            if (!available || !GlobalConfig.lock.enableFprint || !root.lock.secure) {
                abort();
                return;
            }

            tries = 0;
            errorTries = 0;
            start();
        }

        config: "fprint"
        configDirectory: Quickshell.shellPath("assets/pam.d")

        onCompleted: res => {
            if (!available)
                return;

            if (res === PamResult.Success) {
                root.playUnlockSound();
                return root.lock.unlock();
            }

            if (res === PamResult.Error) {
                errorTries++;
                if (errorTries < 5) {
                    abort();
                    errorRetry.restart();
                }
            } else if (res === PamResult.MaxTries) {
                tries++;
                if (tries < GlobalConfig.lock.maxFprintTries) {
                    start();
                } else {
                    state = Pam.MaxTries;
                    abort();
                }
            }

            root.flashMsg();
            fprintStateReset.start();
        }
    }

    PamContext {
        id: howdy

        property bool canAttempt: Config.lock.enableHowdy && root.lock.secure
        property int state

        config: "howdy"
        configDirectory: Quickshell.shellPath("assets/pam.d")

        onCompleted: res => {
            if (res === PamResult.Success) {
                root.playUnlockSound();
                return root.lock.unlock();
            }

            root.clearTransientState();

            if (res === PamResult.Error)
                state = Pam.Error;
            else if (res === PamResult.MaxTries)
                state = Pam.MaxTries;

            root.flashMsg();
            howdyStateReset.restart();
        }
    }

    Process {
        id: availProc

        command: ["sh", "-c", "fprintd-list $USER"]
        onExited: code => {
            fprint.available = code === 0;
            fprint.checkAvail();
        }
    }

    Timer {
        id: errorRetry

        interval: 800
        onTriggered: fprint.start()
    }

    Timer {
        id: pwdStateReset

        interval: 4000
        onTriggered: {
            if (root.state !== Pam.MaxTries)
                root.state = Pam.None;
        }
    }

    Timer {
        id: fprintStateReset

        interval: 4000
        onTriggered: {
            fprint.errorTries = 0;
        }
    }

    Timer {
        id: howdyStateReset

        interval: 4000
        onTriggered: {
            if (howdy.state !== Pam.MaxTries)
                howdy.state = Pam.None;
        }
    }

    Connections {
        function onSecureChanged(): void {
            if (root.lock.secure) {
                availProc.running = true;
                root.buffer = "";
                root.state = Pam.None;
                root.lockMessage = "";
            }
        }

        function onUnlock(): void {
            fprint.abort();
        }

        target: root.lock
    }

    Connections {
        function onEnableFprintChanged(): void {
            fprint.checkAvail();
        }

        target: GlobalConfig.lock
    }

    SoundEffect {
        id: unlockSound
        volume: 0.5
    }
}
