pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import CNS.Config
import qs.components
import qs.components.containers
import qs.components.misc
import qs.services
import qs.utils

// The wallpaper picker's window: one full-screen panel per screen, each
// loading the picker only while it is wanted. The source does the same from
// its shell.qml ("Loaded per opening and destroyed once closed, so its
// pictures don't stay in memory") — here it's a Loader per screen, driven by
// the wallpaperFan IPC target, Mod+Shift+W and the launcher's ">wallpaperfan ".
Scope {
    id: root

    property bool requested: false
    property bool openOnStart: false

    // The output selected when the picker is opened.
    property string targetScreen: ""

    // The loaded picker on the screen it was opened on, or null.
    function targetItem(): var {
        for (const w of windows.instances) {
            if (w.mine && w.pickerItem)
                return w.pickerItem;
        }
        return null;
    }

    function open(): void {
        teardownTimer.stop();
        // Compositor.focusedMonitorName is the output with the focused workspace. It
        // is reliably populated once the event stream has settled; screens[0]
        // is an arbitrary fallback that can land on a monitor nobody is on.
        targetScreen = Compositor.focusedMonitorName || (Screens.screens[0]?.name ?? "");
        // Reopening inside the teardown delay below: the Loader is still active
        // and its item still exists, so onLoaded will NOT fire again and
        // flipping `requested` (already true) changes nothing. Tell the item
        // directly so the picker comes back within that window.
        const existing = targetItem();
        if (existing) {
            existing.open();
            return;
        }
        requested = true;
    }

    function close(): void {
        for (const w of windows.instances)
            w.pickerItem?.close();
        // Keep the window and content alive through the existing close animation.
        if (!showing)
            teardownTimer.restart();
    }

    // Keyed off what is actually on screen, not off `requested`: Escape inside
    // the picker hides the content without going through close(), leaving
    // `requested` true with nothing showing — so a press closed an already
    // closed picker and the bind looked dead.
    readonly property bool showing: {
        for (const w of windows.instances) {
            if (w.showing)
                return true;
        }
        return false;
    }

    function toggle(): void {
        if (showing)
            close();
        else
            open();
    }

    Component.onCompleted: {
        if (openOnStart)
            Qt.callLater(open);
    }

    PickerConfig {
        id: pickerConfig
    }

    Favourites {
        id: favStore
    }

    PaletteCache {
        id: paletteStore
    }

    Variants {
        id: windows

        model: Screens.screens

        StyledWindow {
            id: win

            required property ShellScreen modelData

            name: "wallpaper-fan"
            screen: modelData

            // Only the screen the picker was opened on. Opening every screen put
            // a full-screen overlay with exclusive keyboard focus on all of them,
            // which locked the whole session up.
            readonly property bool mine: root.requested && modelData.name === root.targetScreen

            // Umbriel can release the surface while idle. Retain the Niri
            // mapping behaviour until hidden-first geometry is tested there.
            visible: !Compositor.isUmbriel || mine
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            // Expose the Loader item to the root lifecycle helpers; QML ids
            // are scoped names, not properties of their containing window.
            readonly property Item pickerItem: presenter.item
            readonly property bool showing: mine && (pickerItem?.visible ?? false)

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            mask: showing ? null : emptyRegion

            Region {
                id: emptyRegion
            }

            Loader {
                id: presenter

                anchors.fill: parent
                active: win.mine
                asynchronous: false
                focus: true

                sourceComponent: Wallpaper {
                    paletteCache: paletteStore
                    favourites: favStore
                    config: pickerConfig
                    screenName: win.modelData?.name ?? ""
                }

                // The picker is told to open when it actually exists, rather
                // than on a timer that could fire before the Loader had built it.
                onLoaded: {
                    if (win.mine)
                        item.open();
                }
            }

            // Closing from inside the picker (Escape, or the close button) runs
            // the item's own close(), which ends at `visible = false` — it never
            // touches `requested`. Without this the Loader stayed active holding
            // a hidden item, so the next open() found `requested` already true,
            // changed nothing, and onLoaded never fired again: the picker came
            // up once per shell load and never after. Same teardown the source
            // shell.qml does. Target is `presenter.item` rather than a lookup
            // helper so the binding re-evaluates when the item is replaced.
            Connections {
                target: presenter.item

                function onVisibleChanged(): void {
                    if (presenter.item && !presenter.item.visible)
                        teardownTimer.restart();
                }
            }
        }
    }

    Timer {
        id: teardownTimer
        interval: 600
        // unless it was opened again in the meantime
        onTriggered: {
            if (!root.showing) {
                root.requested = false;
                root.targetScreen = "";
            }
        }
    }

    IpcHandler {
        target: "wallpaperFan"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }
    }

    CustomShortcut {
        name: "open"
        description: "Open the wallpaper picker"
        onPressed: root.open()
    }

    CustomShortcut {
        name: "close"
        description: "Close the wallpaper picker"
        onPressed: root.close()
    }
}