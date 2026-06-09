pragma Singleton

import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property alias appearance: cfgAdapter.appearance
    property alias border: cfgAdapter.border
    property alias bar: cfgAdapter.bar
    property alias dashboard: cfgAdapter.dashboard
    property alias launcher: cfgAdapter.launcher
    property alias osd: cfgAdapter.osd
    property alias session: cfgAdapter.session
    property alias controlCenter: cfgAdapter.controlCenter
    property alias lock: cfgAdapter.lock
    property alias background: cfgAdapter.background
    property alias general: cfgAdapter.general
    property alias services: cfgAdapter.services
    property alias paths: cfgAdapter.paths
    property alias notifs: cfgAdapter.notifs
    property alias utilities: cfgAdapter.utilities

    property bool initialLoadComplete: false
    property var loadStartTime: null
    property bool recentlySaved: false
    property var _cachedSections: ({})
    property var _dirtySections: new Set()

    signal configSaved()
    signal configLoaded(int elapsed)
    signal configError(string message)

    function save(): void {
        saveTimer.restart();
        recentlySaved = true;
        recentSaveCooldown.restart();
    }

    Timer {
        id: saveTimer
        interval: 500
        onTriggered: {
            try {
                cfgFile.setText(JSON.stringify(serializeConfig(), null, 2));
                root.configSaved();
            } catch (e) {
                console.error("Config: Failed to save:", e.message);
                root.configError(e.message);
            }
        }
    }

    function getFileForSection(section: string): var {
        return cfgFile;
    }

    function serializeConfig(): var {
        const sections = {
            appearance: serializeAppearance,
            border: serializeBorder,
            bar: serializeBar,
            dashboard: serializeDashboard,
            launcher: serializeLauncher,
            osd: serializeOsd,
            session: serializeSession,
            controlCenter: serializeControlCenter,
            lock: serializeLock,
            background: serializeBackground,
            general: serializeGeneral,
            services: serializeServices,
            paths: serializePaths,
            notifs: serializeNotifs,
            utilities: serializeUtilities
        };

        const dirty = _dirtySections;
        const noCache = Object.keys(_cachedSections).length === 0;

        for (const [key, fn] of Object.entries(sections)) {
            if (noCache || dirty.has(key)) {
                _cachedSections[key] = fn();
            }
        }

        _dirtySections.clear();

        return {
            appearance: _cachedSections.appearance,
            border: _cachedSections.border,
            bar: _cachedSections.bar,
            dashboard: _cachedSections.dashboard,
            launcher: _cachedSections.launcher,
            osd: _cachedSections.osd,
            session: _cachedSections.session,
            controlCenter: _cachedSections.controlCenter,
            lock: _cachedSections.lock,
            background: _cachedSections.background,
            general: _cachedSections.general,
            services: _cachedSections.services,
            paths: _cachedSections.paths,
            notifs: _cachedSections.notifs,
            utilities: _cachedSections.utilities
        };
    }

    function markDirty(section: string): void {
        _dirtySections.add(section);
        save();
    }

    function reloadAll(): void {
        cfgFile.reload();
    }

    Timer {
        id: reloadDebounce
        interval: 120
        onTriggered: reloadAll()
    }

    FileView {
        id: cfgFile; path: `${Paths.config}/shell.json`
        watchChanges: true
        onFileChanged: { root.loadStartTime = Date.now(); reloadDebounce.restart(); }
        property int _retry: 0
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound && _retry < 3)
                { _retry++; fileNotFoundRetry.restart(); return; }
            console.error("Config: Failed to load shell.json:", err);
            root.configError(`shell.json: ${err}`);
        }
        onLoaded: {
            _retry = 0;
            root.initialLoadComplete = true;
            root.configLoaded(root.loadStartTime ? Date.now() - root.loadStartTime : 0);
            root.loadStartTime = null;
        }
        JsonAdapter { id: cfgAdapter
            property AppearanceConfig appearance: AppearanceConfig {}
            property BorderConfig border: BorderConfig {}
            property BarConfig bar: BarConfig {}
            property DashboardConfig dashboard: DashboardConfig {}
            property LauncherConfig launcher: LauncherConfig {}
            property OsdConfig osd: OsdConfig {}
            property SessionConfig session: SessionConfig {}
            property ControlCenterConfig controlCenter: ControlCenterConfig {}
            property LockConfig lock: LockConfig {}
            property BackgroundConfig background: BackgroundConfig {}
            property GeneralConfig general: GeneralConfig {}
            property ServiceConfig services: ServiceConfig {}
            property UserPaths paths: UserPaths {}
            property NotifsConfig notifs: NotifsConfig {}
            property UtilitiesConfig utilities: UtilitiesConfig {}
        }
    }

    Timer {
        id: recentSaveCooldown
        interval: 2000
        onTriggered: root.recentlySaved = false
    }

    Timer {
        id: fileNotFoundRetry
        interval: 250
        onTriggered: configInitializer.running = true
    }

    Process {
        id: configInitializer
        command: ["mkdir", "-p", Paths.config]
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                if (!cfgFile.loaded)
                    cfgFile.setText(JSON.stringify(serializeConfig(), null, 2));
                reloadAll();
            } else {
                console.error("Config: Failed to create directory:", Paths.config, "Exit code:", exitCode);
            }
        }
    }

    function serializeAppearance(): var {
        return {
            rounding: { scale: 1.0 },
            spacing: { scale: 1.0 },
            padding: { scale: 1.0 },
            font: {
                family: {
                    sans: appearance.font.family.sans,
                    mono: appearance.font.family.mono,
                    material: appearance.font.family.material,
                    clock: appearance.font.family.clock
                },
                size: { scale: 1.0 }
            },
            anim: {
                durations: { scale: 1.0 }
            },
            transparency: {
                enabled: appearance.transparency.enabled,
                reduceTransparency: appearance.transparency.reduceTransparency,
                base: appearance.transparency.base,
                layers: appearance.transparency.layers
            }
        };
    }

    function serializeGeneral(): var {
        return {
            isDistLogo: general.isDistLogo,
            apps: {
                terminal: general.apps.terminal,
                audio: general.apps.audio,
                playback: general.apps.playback,
                explorer: general.apps.explorer
            },
            battery: {
                warnLevels: general.battery.warnLevels,
                criticalLevel: general.battery.criticalLevel,
                enableWarnings: general.battery.enableWarnings
            },
            idle: {
                lockBeforeSleep: general.idle.lockBeforeSleep,
                inhibitWhenAudio: general.idle.inhibitWhenAudio,
                timeouts: general.idle.timeouts
            }
        };
    }

    function serializeBackground(): var {
        return {
            enabled: background.enabled,
            backdropEnabled: background.backdropEnabled,
            wallpaperEnabled: background.wallpaperEnabled,
            desktopClock: {
                enabled: background.desktopClock.enabled,
                scale: background.desktopClock.scale,
                position: background.desktopClock.position,
                invertColors: background.desktopClock.invertColors,
                background: {
                    enabled: background.desktopClock.background.enabled,
                    opacity: background.desktopClock.background.opacity,
                    blur: background.desktopClock.background.blur
                },
                shadow: {
                    enabled: background.desktopClock.shadow.enabled,
                    opacity: background.desktopClock.shadow.opacity,
                    blur: background.desktopClock.shadow.blur
                }
            },
            visualiser: {
                enabled: background.visualiser.enabled,
                autoHide: background.visualiser.autoHide,
                blur: background.visualiser.blur,
                rounding: background.visualiser.rounding,
                spacing: background.visualiser.spacing,
                output: background.visualiser.output
            }
        };
    }

    function serializeBar(): var {
        return {
            persistent: bar.persistent,
            showOnHover: bar.showOnHover,
            dragThreshold: bar.dragThreshold,
            scrollActions: {
                workspaces: bar.scrollActions.workspaces,
                volume: bar.scrollActions.volume,
                brightness: bar.scrollActions.brightness
            },
            workspaces: {
                shown: bar.workspaces.shown,
                activeIndicator: bar.workspaces.activeIndicator,
                occupiedBg: bar.workspaces.occupiedBg,
                showWindows: bar.workspaces.showWindows,
                perMonitorWorkspaces: bar.workspaces.perMonitorWorkspaces,
                windowIconImage: bar.workspaces.windowIconImage,
                windowIconGap: bar.workspaces.windowIconGap,
                windowIconSize: bar.workspaces.windowIconSize,
                groupIconsByApp: bar.workspaces.groupIconsByApp,
                groupingRespectsLayout: bar.workspaces.groupingRespectsLayout,
                focusedWindowBlob: bar.workspaces.focusedWindowBlob,
                windowRighClickContext: bar.workspaces.windowRighClickContext,
                windowContextDefaultExpand: bar.workspaces.windowContextDefaultExpand,
                doubleClickToCenter: bar.workspaces.doubleClickToCenter,
                windowContextWidth: bar.workspaces.windowContextWidth,
                activeTrail: bar.workspaces.activeTrail,
                pagerActive: bar.workspaces.pagerActive,
                label: bar.workspaces.label,
                occupiedLabel: bar.workspaces.occupiedLabel,
                activeLabel: bar.workspaces.activeLabel
            },
            activeWindow: {
                compact: bar.activeWindow.compact,
                inverted: bar.activeWindow.inverted
            },
            tray: {
                background: bar.tray.background,
                compact: bar.tray.compact,
                recolour: bar.tray.recolour,
                iconSubs: bar.tray.iconSubs
            },
            status: {
                showAudio: bar.status.showAudio,
                showMicrophone: bar.status.showMicrophone,
                showKbLayout: bar.status.showKbLayout,
                showNetwork: bar.status.showNetwork,
                showWifi: bar.status.showWifi,
                showBluetooth: bar.status.showBluetooth,
                showBattery: bar.status.showBattery,
                showLockStatus: bar.status.showLockStatus
            },
            clock: {
                background: bar.clock.background,
                showDate: bar.clock.showDate,
                showIcon: bar.clock.showIcon
            },
            popouts: {
                tray: bar.popouts.tray,
                statusIcons: bar.popouts.statusIcons
            },
            sizes: {
                innerWidth: bar.sizes.innerWidth,
                windowPreviewSize: bar.sizes.windowPreviewSize,
                trayMenuWidth: bar.sizes.trayMenuWidth,
                batteryWidth: bar.sizes.batteryWidth,
                networkWidth: bar.sizes.networkWidth
            },
            entries: bar.entries
        };
    }

    function serializeBorder(): var {
        return {
            thickness: border.thickness,
            rounding: border.rounding
        };
    }

    function serializeDashboard(): var {
        return {
            enabled: dashboard.enabled,
            showOnHover: dashboard.showOnHover,
            useWallpaperAvatar: dashboard.useWallpaperAvatar,
            mediaUpdateInterval: dashboard.mediaUpdateInterval,
            resourceUpdateInterval: dashboard.resourceUpdateInterval,
            dragThreshold: dashboard.dragThreshold,
            updateInterval: dashboard.updateInterval,
            performance: {
                showBattery: dashboard.performance.showBattery,
                showGpu: dashboard.performance.showGpu,
                showCpu: dashboard.performance.showCpu,
                showMemory: dashboard.performance.showMemory,
                showStorage: dashboard.performance.showStorage,
                showNetwork: dashboard.performance.showNetwork
            },
            sizes: {
                tabIndicatorHeight: dashboard.sizes.tabIndicatorHeight,
                tabIndicatorSpacing: dashboard.sizes.tabIndicatorSpacing,
                infoWidth: dashboard.sizes.infoWidth,
                infoIconSize: dashboard.sizes.infoIconSize,
                dateTimeWidth: dashboard.sizes.dateTimeWidth,
                mediaWidth: dashboard.sizes.mediaWidth,
                mediaProgressSweep: dashboard.sizes.mediaProgressSweep,
                mediaProgressThickness: dashboard.sizes.mediaProgressThickness,
                resourceProgessThickness: dashboard.sizes.resourceProgessThickness,
                weatherWidth: dashboard.sizes.weatherWidth,
                mediaCoverArtSize: dashboard.sizes.mediaCoverArtSize,
                mediaVisualiserSize: dashboard.sizes.mediaVisualiserSize,
                resourceSize: dashboard.sizes.resourceSize
            }
        };
    }

    function serializeControlCenter(): var {
        return {
            sizes: {
                heightMult: controlCenter.sizes.heightMult,
                ratio: controlCenter.sizes.ratio
            }
        };
    }

    function serializeLauncher(): var {
        return {
            enabled: launcher.enabled,
            showOnHover: launcher.showOnHover,
            maxShown: launcher.maxShown,
            maxWallpapers: launcher.maxWallpapers,
            specialPrefix: launcher.specialPrefix,
            actionPrefix: launcher.actionPrefix,
            enableDangerousActions: launcher.enableDangerousActions,
            dragThreshold: launcher.dragThreshold,
            vimKeybinds: launcher.vimKeybinds,
            favouriteApps: launcher.favouriteApps,
            hiddenApps: launcher.hiddenApps,
            useFuzzy: {
                apps: launcher.useFuzzy.apps,
                actions: launcher.useFuzzy.actions,
                schemes: launcher.useFuzzy.schemes,
                variants: launcher.useFuzzy.variants,
                wallpapers: launcher.useFuzzy.wallpapers
            },
            sizes: {
                itemWidth: launcher.sizes.itemWidth,
                itemHeight: launcher.sizes.itemHeight,
                wallpaperWidth: launcher.sizes.wallpaperWidth,
                wallpaperHeight: launcher.sizes.wallpaperHeight
            }
        };
    }

    function serializeNotifs(): var {
        return {
            expire: notifs.expire,
            defaultExpireTimeout: notifs.defaultExpireTimeout,
            clearThreshold: notifs.clearThreshold,
            expandThreshold: notifs.expandThreshold,
            actionOnClick: notifs.actionOnClick,
            groupPreviewNum: notifs.groupPreviewNum,
            sizes: {
                width: notifs.sizes.width,
                image: notifs.sizes.image,
                badge: notifs.sizes.badge
            }
        };
    }

    function serializeOsd(): var {
        return {
            enabled: osd.enabled,
            hideDelay: osd.hideDelay,
            enableBrightness: osd.enableBrightness,
            enableMicrophone: osd.enableMicrophone,
            sizes: {
                sliderWidth: osd.sizes.sliderWidth,
                sliderHeight: osd.sizes.sliderHeight
            }
        };
    }

    function serializeSession(): var {
        return {
            enabled: session.enabled,
            dragThreshold: session.dragThreshold,
            vimKeybinds: session.vimKeybinds,
            commands: {
                logout: session.commands.logout,
                shutdown: session.commands.shutdown,
                hibernate: session.commands.hibernate,
                reboot: session.commands.reboot
            },
            sizes: {
                button: session.sizes.button
            }
        };
    }

    function serializeLock(): var {
        return {
            recolourLogo: lock.recolourLogo,
            enableFprint: lock.enableFprint,
            showExtras: lock.showExtras,
            maxFprintTries: lock.maxFprintTries,
            sizes: {
                heightMult: lock.sizes.heightMult,
                ratio: lock.sizes.ratio,
                centerWidth: lock.sizes.centerWidth
            }
        };
    }

    function serializeUtilities(): var {
        return {
            enabled: utilities.enabled,
            maxToasts: utilities.maxToasts,
            sizes: {
                width: utilities.sizes.width,
                toastWidth: utilities.sizes.toastWidth
            },
            toasts: {
                configLoaded: utilities.toasts.configLoaded,
                chargingChanged: utilities.toasts.chargingChanged,
                gameModeChanged: utilities.toasts.gameModeChanged,
                dndChanged: utilities.toasts.dndChanged,
                audioOutputChanged: utilities.toasts.audioOutputChanged,
                audioInputChanged: utilities.toasts.audioInputChanged,
                capsLockChanged: utilities.toasts.capsLockChanged,
                numLockChanged: utilities.toasts.numLockChanged,
                kbLayoutChanged: utilities.toasts.kbLayoutChanged,
                kbLimit: utilities.toasts.kbLimit,
                vpnChanged: utilities.toasts.vpnChanged,
                nowPlaying: utilities.toasts.nowPlaying,
                niriConfigLoaded: utilities.toasts.niriConfigLoaded
            },
            vpn: {
                enabled: utilities.vpn.enabled,
                provider: utilities.vpn.provider
            }
        };
    }

    function serializeServices(): var {
        return {
            weatherLocation: services.weatherLocation,
            useFahrenheit: services.useFahrenheit,
            useTwelveHourClock: services.useTwelveHourClock,
            gpuType: services.gpuType,
            visualiserBars: services.visualiserBars,
            audioIncrement: services.audioIncrement,
            smartScheme: services.smartScheme,
            defaultPlayer: services.defaultPlayer,
            playerAliases: services.playerAliases,
            toasts: {
                configLoaded: services.toasts.configLoaded,
                configError: services.toasts.configError
            }
        };
    }

    function serializePaths(): var {
        return {
            wallpaperDir: paths.wallpaperDir,
            wallpaper: paths.wallpaper,
            sessionGif: paths.sessionGif,
            mediaGif: paths.mediaGif,
            noNotifsPic: paths.noNotifsPic
        };
    }
}
