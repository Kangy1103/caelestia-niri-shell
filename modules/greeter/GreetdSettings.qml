pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "GreetdEnv.js" as GreetdEnv

Singleton {
    id: root

    readonly property string configPath: {
        const greetCfgDir = Quickshell.env("CNS_GREET_CFG_DIR") || "/var/cache/cns-greeter";
        return greetCfgDir + "/settings.json";
    }

    readonly property string _greeterCacheDir: {
        const i = root.configPath.lastIndexOf("/");
        return i >= 0 ? root.configPath.substring(0, i) : "";
    }
    readonly property string greeterWallpaperOverridePath: root._greeterCacheDir ? (root._greeterCacheDir + "/greeter_wallpaper_override.jpg") : ""

    property bool settingsLoaded: false
    property bool use24HourClock: true
    property bool greeterUse24HourClock: true
    property bool greeterShowSeconds: false
    property bool greeterPadHours12Hour: false
    property string greeterLockDateFormat: ""
    property bool rememberLastSession: true
    property bool rememberLastUser: true
    property bool greeterEnableFprint: false
    property bool greeterEnableU2f: false
    property string greeterWallpaperPath: ""
    property bool powerActionConfirm: true
    property real powerActionHoldDuration: 0.5
    property var powerMenuActions: ["reboot", "logout", "poweroff", "lock", "suspend", "restart"]
    property string powerMenuDefaultAction: "poweroff"
    property bool powerMenuGridLayout: false
    property real fontScale: 1.0
    property real cornerRadius: 12
    property int animationSpeed: 2

    property bool weatherEnabled: false

    function parseSettings(content) {
        try {
            let settings = {};
            if (content && content.trim()) {
                settings = JSON.parse(content);
            }

            const envRememberLastSession = GreetdEnv.readBoolOverride(Quickshell.env, ["CNS_GREET_REMEMBER_LAST_SESSION", "CNS_SAVE_SESSION"], undefined);
            const envRememberLastUser = GreetdEnv.readBoolOverride(Quickshell.env, ["CNS_GREET_REMEMBER_LAST_USER", "CNS_SAVE_USERNAME"], undefined);

            use24HourClock = settings.use24HourClock !== undefined ? settings.use24HourClock : true;
            greeterUse24HourClock = settings.greeterUse24HourClock !== undefined ? settings.greeterUse24HourClock : use24HourClock;
            greeterShowSeconds = settings.greeterShowSeconds !== undefined ? settings.greeterShowSeconds : false;
            greeterPadHours12Hour = settings.greeterPadHours12Hour !== undefined ? settings.greeterPadHours12Hour : false;
            greeterLockDateFormat = settings.greeterLockDateFormat !== undefined ? settings.greeterLockDateFormat : "";
            if (envRememberLastSession !== undefined) {
                rememberLastSession = envRememberLastSession;
            } else {
                rememberLastSession = settings.greeterRememberLastSession !== undefined ? settings.greeterRememberLastSession : settings.rememberLastSession !== undefined ? settings.rememberLastSession : true;
            }
            if (envRememberLastUser !== undefined) {
                rememberLastUser = envRememberLastUser;
            } else {
                rememberLastUser = settings.greeterRememberLastUser !== undefined ? settings.greeterRememberLastUser : settings.rememberLastUser !== undefined ? settings.rememberLastUser : true;
            }
            greeterEnableFprint = settings.greeterEnableFprint !== undefined ? settings.greeterEnableFprint : false;
            greeterEnableU2f = settings.greeterEnableU2f !== undefined ? settings.greeterEnableU2f : false;
            greeterWallpaperPath = settings.greeterWallpaperPath !== undefined ? settings.greeterWallpaperPath : "";
            powerActionConfirm = settings.powerActionConfirm !== undefined ? settings.powerActionConfirm : true;
            powerActionHoldDuration = settings.powerActionHoldDuration !== undefined ? settings.powerActionHoldDuration : 0.5;
            powerMenuActions = settings.powerMenuActions !== undefined ? settings.powerMenuActions : ["reboot", "logout", "poweroff", "lock", "suspend", "restart"];
            powerMenuDefaultAction = settings.powerMenuDefaultAction !== undefined ? settings.powerMenuDefaultAction : "poweroff";
            powerMenuGridLayout = settings.powerMenuGridLayout !== undefined ? settings.powerMenuGridLayout : false;
            fontScale = settings.fontScale !== undefined ? settings.fontScale : 1.0;
            cornerRadius = settings.cornerRadius !== undefined ? settings.cornerRadius : 12;
            animationSpeed = settings.animationSpeed !== undefined ? settings.animationSpeed : 2;
            weatherEnabled = settings.weatherEnabled !== undefined ? settings.weatherEnabled : false;
        } catch (e) {
            console.warn("Failed to parse greetd settings:", e);
        } finally {
            settingsLoaded = true;
        }
    }

    FileView {
        id: settingsFile
        path: root.configPath
        blockLoading: false
        blockWrites: true
        atomicWrites: false
        watchChanges: false
        printErrors: true
        onLoaded: {
            parseSettings(settingsFile.text());
        }
        onLoadFailed: error => {
            console.warn("Failed to load greetd settings:", error);
            root.parseSettings("");
        }
    }
}
