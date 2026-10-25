pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import CNS
import CNS.Internal
import CNS.Config
import qs.services
import qs.utils

// Shared compositor-facing CNS API; NiriIpc remains its Niri-native provider.
Singleton {
    id: root

    // The compositor service is the public shell API. The native IPC clients
    // remain backend-specific and are selected here, not in a Niri-named file.
    readonly property string backendName: {
        const requested = (Quickshell.env("CNS_COMPOSITOR") || "").toLowerCase();
        if (requested === "niri" || requested === "umbriel")
            return requested;
        if (Quickshell.env("UMBRIEL_SOCKET"))
            return "umbriel";
        if (Quickshell.env("NIRI_SOCKET"))
            return "niri";
        const desktop = (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase();
        if (desktop.includes("umbriel"))
            return "umbriel";
        if (desktop.includes("niri"))
            return "niri";
        return "unknown";
    }
    readonly property bool isNiri: backendName === "niri"
    readonly property bool isUmbriel: backendName === "umbriel"
    readonly property bool available: isUmbriel ? UmbrielIpc.available : isNiri && NiriIpc.available
    readonly property bool supportsWorkspaceReorder: isNiri
    readonly property bool supportsWindowScreenshot: isNiri || isUmbriel
    readonly property bool supportsWindowDrag: isNiri || isUmbriel

    // --- Workspaces ---
    readonly property var allWorkspaces: isUmbriel
        ? UmbrielIpc.workspaces.map(root.normalizeUmbrielWorkspace)
        : isNiri ? NiriIpc.workspaces : []
    readonly property int focusedWorkspaceIndex: isUmbriel
        ? allWorkspaces.findIndex(workspace => workspace.is_focused)
        : isNiri ? NiriIpc.focusedWorkspaceIndex : -1
    readonly property var focusedWorkspaceId: isUmbriel
        ? (allWorkspaces.find(workspace => workspace.is_focused)?.id ?? "")
        : isNiri ? NiriIpc.focusedWorkspaceId : ""
    readonly property string focusedMonitorName: isUmbriel
        ? root.umbrielFocusedOutput()
        : isNiri ? NiriIpc.focusedMonitorName : ""
    readonly property var currentOutputWorkspaces: isUmbriel
        ? allWorkspaces.filter(workspace => workspace.output === focusedMonitorName)
        : isNiri ? NiriIpc.currentOutputWorkspaces : []
    readonly property var workspaceHasWindows: isUmbriel
        ? root.umbrielWorkspaceOccupancy()
        : isNiri ? NiriIpc.workspaceHasWindows : ({})

    // UI context menu state
    property bool wsContextExpanded: false
    property var wsContextAnchor: null
    property string wsContextType: "none"

    // Workspace tooltip state
    property Item tooltipTarget: null
    property string tooltipText: ""
    property point tooltipPos: Qt.point(0, 0)
    property point mousePos: Qt.point(0, 0)
    
    property Timer wsAnchorClearTimer: Timer {
        interval: Tokens.anim.durations.normal
        repeat: false
        onTriggered: {
            if (root.wsContextAnchor === null) {
                root.wsContextType = "none";
            }
        }
    }

    // State machine for moveColumnToIndexAfterFocus
    property var _moveAfterFocusPendingCb: null
    property string _moveAfterFocusPendingId: ""

    // State machine for sequential group column moves
    property var _seqState: null

    onFocusedWindowIdChanged: {
        // Handle single window move after focus
        if (_moveAfterFocusPendingCb && sameId(focusedWindowId, _moveAfterFocusPendingId)) {
            var cb = _moveAfterFocusPendingCb;
            _moveAfterFocusPendingCb = null;
            _moveAfterFocusPendingId = "";
            cb();
        }

        // Handle sequential group moves
        var s = _seqState;
        if (s && sameId(focusedWindowId, s.curWindowId)) {
            if (s.i >= s.windowIds.length) {
                // Done sequential moves, restore initial focus
                _seqState = null;
                root.focusWindow(s.initialWindowId);
            } else {
                // Execute next move in sequence
                var wid = s.windowIds[s.i];
                s.curWindowId = wid; // Update what we are waiting for next
                s.i++;
                root.moveColumnToIndexAfterFocus(wid, s.targetIndex);
            }
        }
    }

    onWsContextAnchorChanged: {
        wsAnchorClearTimer.stop();
        if (wsContextAnchor === null) {
            wsAnchorClearTimer.start();
        }
    }

    // --- Windows ---
    readonly property var windows: isUmbriel
        ? UmbrielIpc.windows.map(root.normalizeUmbrielWindow)
        : isNiri ? NiriIpc.windows : []
    readonly property int focusedWindowIndex: isUmbriel
        ? windows.findIndex(window => window.active)
        : isNiri ? NiriIpc.focusedWindowIndex : -1
    readonly property string focusedWindowId: isUmbriel
        ? (focusedWindow?.id ?? "")
        : isNiri ? NiriIpc.focusedWindowId : ""
    readonly property string focusedWindowTitle: isUmbriel
        ? (focusedWindow?.title ?? "")
        : isNiri ? NiriIpc.focusedWindowTitle : ""
    readonly property string focusedWindowClass: isUmbriel
        ? (focusedWindow?.app_id ?? "")
        : isNiri ? NiriIpc.focusedWindowClass : ""
    readonly property var focusedWindow: isUmbriel
        ? (windows.find(window => window.active) ?? null)
        : isNiri ? NiriIpc.focusedWindow : null
    readonly property var lastFocusedWindow: isNiri ? NiriIpc.lastFocusedWindow : null
    readonly property string scrollDirection: isNiri ? NiriIpc.scrollDirection : "none"
    readonly property bool inOverview: isUmbriel ? UmbrielIpc.inOverview : isNiri && NiriIpc.inOverview
    readonly property bool hasFullscreen: isUmbriel
        ? windows.some(window => window.active && window.fullscreen)
        : isNiri && NiriIpc.hasFullscreen
    signal windowOpenedOrChanged(var windowData)
    signal workspacesChanged()
    signal focusedWorkspaceChanged()

    // --- Outputs ---
    readonly property var outputs: isUmbriel ? root.umbrielOutputsByName() : isNiri ? NiriIpc.outputs : ({})

    // Dispatch a compositor-native action through the selected IPC provider.
    function action(name: string): bool {
        if (!available)
            return false;
        if (isNiri)
            return NiriIpc.action(name);

        const aliases = {
            "toggle-overview": "overview-toggle",
            "focus-workspace-up": "workspace-previous",
            "focus-workspace-down": "workspace-next",
            "switch-layout": "keyboard-layout-next",
            "dpms off": "dpms-off",
            "dpms on": "dpms-on",
            "power-off-monitors": "dpms-off",
            "power-on-monitors": "dpms-on"
        };
        return UmbrielIpc.action(aliases[name] ?? name);
    }

    function switchKeyboardLayout(): bool {
        return isUmbriel ? UmbrielIpc.action("keyboard-layout-next")
            : isNiri && NiriIpc.action("switch-layout", []);
    }

    function quitSession(): void {
        if (isUmbriel)
            UmbrielIpc.action("session-quit:skip-confirmation");
        else if (isNiri)
            Quickshell.execDetached(["niri", "msg", "action", "quit", "-s"]);
    }

    IpcHandler {
        target: "compositor"
        function quit(): void { root.quitSession(); }
        function powerOffMonitors(): bool { return root.action("power-off-monitors"); }
        function powerOnMonitors(): bool { return root.action("power-on-monitors"); }
    }
    
    // --- Keyboard ---
    readonly property var kbLayoutsArray: isUmbriel ? UmbrielIpc.keyboardLayoutNames : isNiri ? NiriIpc.kbLayoutsArray : []
    readonly property int kbLayoutIndex: isUmbriel ? UmbrielIpc.keyboardLayoutIndex : isNiri ? NiriIpc.kbLayoutIndex : 0
    readonly property string kbLayouts: isUmbriel
        ? kbLayoutsArray.join(",")
        : isNiri ? NiriIpc.kbLayouts : "?"
    readonly property string defaultKbLayout: kbLayoutsArray.length > 0
        ? kbLayoutsArray[0].toString()
        : "?"
    readonly property string kbLayout: kbLayoutIndex >= 0 && kbLayoutIndex < kbLayoutsArray.length
        ? kbLayoutsArray[kbLayoutIndex].toString().slice(0, 2).toLowerCase()
        : "?"
    readonly property bool capsLock: NiriIpc.capsLock
    readonly property bool numLock: NiriIpc.numLock

    function normalizeUmbrielWorkspace(workspace) {
        return Object.assign({}, workspace, {
            id: String(workspace.id ?? ""),
            idx: Number(workspace.index ?? 0),
            is_active: !!workspace.active,
            is_focused: !!workspace.focused,
            is_urgent: !!workspace.urgent,
            active_window_id: String(workspace.focused_window || (workspace.occupied ? "occupied" : ""))
        });
    }

    function normalizeUmbrielWindow(window) {
        const layout = {};
        if (Number(window.column) >= 0 && Number(window.row) >= 0)
            layout.pos_in_scrolling_layout = [Number(window.column), Number(window.row)];
        if (Number(window.w) > 0 && Number(window.h) > 0)
            layout.window_size = [Number(window.w), Number(window.h)];

        return Object.assign({}, window, {
            id: String(window.id ?? ""),
            workspace_id: String(window.workspace ?? ""),
            is_focused: !!window.active,
            is_urgent: !!window.urgent,
            layout: layout
        });
    }

    function umbrielFocusedOutput() {
        const focusedOutput = UmbrielIpc.outputs.find(output => output.focused);
        if (focusedOutput)
            return focusedOutput.name;
        const focusedWorkspace = UmbrielIpc.workspaces.find(workspace => workspace.focused);
        return focusedWorkspace?.output ?? "";
    }

    function umbrielWorkspaceOccupancy() {
        const occupancy = {};
        for (const workspace of allWorkspaces)
            occupancy[String(workspace.idx)] = !!workspace.occupied;
        return occupancy;
    }

    function umbrielOutputsByName() {
        const result = {};
        for (const output of UmbrielIpc.outputs)
            result[output.name] = output;
        return result;
    }

    // grim can only read the composited screen, so a window is capturable only
    // when it is actually inside its output's viewport on the active workspace.
    // Off-screen scrolling columns report a global X that lands on another
    // output, and shared rectangles mean a tab group where only one tab shows.
    function isWindowCapturable(window) {
        if (!isUmbriel)
            return true;
        if (!window)
            return false;
        if (window.visible === false || window.tab_hidden)
            return false;

        const workspace = workspaceById(window.workspace_id);
        if (!workspace || !workspace.is_active)
            return false;

        const output = outputs[window.output];
        const ox = Number(output?.position?.x);
        const oy = Number(output?.position?.y);
        const ow = Number(output?.logical_size?.width);
        const oh = Number(output?.logical_size?.height);
        const x = Number(window.x);
        const y = Number(window.y);
        const w = Number(window.w);
        const h = Number(window.h);
        if (![ox, oy, ow, oh, x, y, w, h].every(value => Number.isFinite(value)))
            return false;
        if (x < ox || y < oy || x + w > ox + ow || y + h > oy + oh)
            return false;

        const peers = windows.filter(candidate =>
            !sameId(candidate.id, window.id) &&
            sameId(candidate.workspace_id, window.workspace_id) &&
            Number(candidate.x) === x && Number(candidate.y) === y &&
            Number(candidate.w) === w && Number(candidate.h) === h);
        return peers.length === 0 || !!window.focused;
    }

    function umbrielWorkspaceSelector(workspace) {
        if (!workspace)
            return "";
        const output = String(workspace.output ?? "");
        const name = String(workspace.name ?? "");
        const selector = workspace.named && name.length > 0
            ? `"${name.replace(/\\/g, "\\\\").replace(/"/g, "\\\"")}"`
            : String(workspace.index ?? workspace.idx ?? "");
        return output.length > 0 ? `${selector}/${output}` : selector;
    }

    function sameId(left, right) {
        return String(left ?? "") === String(right ?? "");
    }

    function workspaceById(id) {
        return allWorkspaces.find(workspace => sameId(workspace.id, id)) ?? null;
    }

    property bool _lockKeysInitialized: false
    Timer { interval: 1500; running: true; onTriggered: root._lockKeysInitialized = true }

    onCapsLockChanged: {
        if (!_lockKeysInitialized || !GlobalConfig.utilities.toasts.capsLockChanged)
            return;
        if (capsLock)
            Toaster.toast(qsTr("Caps lock enabled"), qsTr("Caps lock is currently enabled"), "keyboard_capslock_badge");
        else
            Toaster.toast(qsTr("Caps lock disabled"), qsTr("Caps lock is currently disabled"), "keyboard_capslock");
    }

    onNumLockChanged: {
        if (!_lockKeysInitialized || !GlobalConfig.utilities.toasts.numLockChanged)
            return;
        if (numLock)
            Toaster.toast(qsTr("Num lock enabled"), qsTr("Num lock is currently enabled"), "looks_one");
        else
            Toaster.toast(qsTr("Num lock disabled"), qsTr("Num lock is currently disabled"), "timer_1");
    }

    onKbLayoutChanged: {
        if (!_lockKeysInitialized || !GlobalConfig.utilities.toasts.kbLayoutChanged)
            return;
        Toaster.toast(qsTr("Keyboard layout changed"), qsTr("Layout changed to: %1").arg(kbLayout), "keyboard");
    }

    // --- Initialization ---
    Connections {
        target: root.isNiri ? NiriIpc : null
        enabled: root.isNiri
        function onWorkspacesChanged() {
            root.workspacesChanged();
            root.focusedWorkspaceChanged();
        }
        function onFocusedWorkspaceChanged() { root.focusedWorkspaceChanged(); }
        function onWindowOpenedOrChanged(windowData) {
            root.windowOpenedOrChanged(windowData);
        }
        function onConfigLoaded(failed) {
            if (!GlobalConfig.utilities.toasts.niriConfigLoaded)
                return;

            if (failed)
                Toaster.toast(qsTr("Niri config error"), qsTr("Configuration reload failed. Check your config."), "warning", Toast.Error);
            else
                Toaster.toast(qsTr("Niri config loaded"), qsTr("Configuration reloaded successfully."), "check");
        }
    }

    Connections {
        target: root.isUmbriel ? UmbrielIpc : null
        enabled: root.isUmbriel
        function onWorkspacesChanged() {
            root.workspacesChanged();
            root.focusedWorkspaceChanged();
        }
        function onWindowsChanged() {
            if (root.focusedWindow)
                root.windowOpenedOrChanged(root.focusedWindow);
        }
        function onOutputsChanged() {
            root.focusedWorkspaceChanged();
        }
    }

    // --- Workspace Functions ---
    function getWorkspaceIdxById(workspaceId) {
        return allWorkspaces.findIndex(workspace => sameId(workspace.id, workspaceId));
    }

    // Strips leading non-ASCII noise some Wayland/GTK apps prepend to window
    // titles (icon placeholders, PUA glyphs). Referenced by MultiWindowContext,
    // WindowIconContext and WorkspaceOverview.
    function cleanWindowTitle(windowTitle) {
        if (windowTitle) {
            return windowTitle.replace(/^[^ -~]+/, "");
        }
        return windowTitle;
    }

    function getActiveWorkspaceName() {
        if (allWorkspaces && focusedWorkspaceIndex >= 0 && focusedWorkspaceIndex < allWorkspaces.length) {
            return allWorkspaces[focusedWorkspaceIndex].name || "";
        }
        return "";
    }

    function getWorkspaceNameByIndex(idx) {
        if (allWorkspaces && idx >= 0 && idx < allWorkspaces.length) {
            return allWorkspaces[idx].name || "";
        }
        return "";
    }

    function getWorkspaceNameById(id) {
        if (allWorkspaces && id !== undefined && id !== null) {
            const ws = allWorkspaces.find(w => sameId(w.id, id));
            return ws?.name || "";
        }
        return "";
    }

    function getWorkspaceByIndex(index) {
        if (index >= 0 && index < allWorkspaces.length) {
            return allWorkspaces[index];
        }
        return null;
    }

    function getWorkspaceCount() {
        return allWorkspaces.length;
    }

    function getOccupiedWorkspaceCount() {
        return allWorkspaces.filter(w => w.active_window_id !== "").length;
    }

    function getCurrentOutputWorkspaceNumbers() {
        return currentOutputWorkspaces.map(w => isUmbriel ? w.idx : w.idx + 1);
    }

    function getCurrentWorkspaceNumber() {
        if (focusedWorkspaceIndex >= 0 && focusedWorkspaceIndex < allWorkspaces.length) {
            return allWorkspaces[focusedWorkspaceIndex].idx;
        }
        return 1;
    }

    function switchToWorkspace(workspaceId) {
        if (!available) return false;
        if (isUmbriel) {
            const workspace = allWorkspaces.find(candidate => sameId(candidate.id, workspaceId));
            const selector = umbrielWorkspaceSelector(workspace);
            return selector.length > 0 && UmbrielIpc.action(`workspace-switch:${selector}`);
        }
        return NiriIpc.action("focus-workspace", [workspaceId.toString()]);
    }

    function switchToWorkspaceUpDown(direction) {
        if (!available) return false;
        if (isUmbriel)
            return UmbrielIpc.action(direction === "up" ? "workspace-previous" : "workspace-next");
        return NiriIpc.action("focus-workspace-" + direction, []);
    }

    function switchToWorkspaceByIndex(index) {
        if (!available || index < 0 || index >= allWorkspaces.length) return false;
        const workspace = allWorkspaces[index];
        return switchToWorkspace(isUmbriel ? workspace.id : workspace.idx);
    }

    function switchToWorkspaceByNumber(number, output) {
        if (!available) return false;
        const targetOutput = output || focusedMonitorName;
        if (!targetOutput) {
            console.warn("NiriService: No output specified for workspace switching");
            return false;
        }
        const outputWorkspaces = allWorkspaces
            .filter(w => w.output === targetOutput)
            .sort((a, b) => a.idx - b.idx);
        if (number >= 1 && number <= outputWorkspaces.length) {
            const workspace = outputWorkspaces[number - 1];
            return switchToWorkspace(isUmbriel ? workspace.id : workspace.idx);
        }
        console.warn("NiriService: No workspace", number, "found on output", targetOutput);
        return false;
    }

    function moveWindowToWorkspace(workspaceIdx) {
        if (!available) return false;
        if (isUmbriel) {
            const workspace = allWorkspaces.find(candidate => Number(candidate.idx) === Number(workspaceIdx));
            const selector = umbrielWorkspaceSelector(workspace);
            return selector.length > 0 && UmbrielIpc.action(`window-move-to-workspace:${selector}`);
        }
        return NiriIpc.action("move-window-to-workspace", [workspaceIdx.toString()]);
    }

    // Umbriel only moves the focused window, so reveal the requested window,
    // move it silently, then restore the previous focus. Niri callers keep
    // using the window-targeted CLI path.
    function moveWindowToWorkspaceById(windowId, workspaceId) {
        if (!isUmbriel || !available) return false;
        const workspace = workspaceById(workspaceId);
        const selector = umbrielWorkspaceSelector(workspace);
        if (selector.length === 0) return false;

        const previousId = focusedWindowId;
        if (!UmbrielIpc.action(`window-focus:${windowId}`)) return false;
        const moved = UmbrielIpc.action(`window-move-to-workspace-silent:${selector}`);
        if (previousId && !sameId(previousId, windowId))
            UmbrielIpc.action(`window-focus:${previousId}`);
        return moved;
    }

    // --- Window Functions ---
    function getActiveWorkspaceWindows() {
        if (!allWorkspaces || focusedWorkspaceIndex === undefined) return [];
        const currentWs = allWorkspaces[focusedWorkspaceIndex];
        if (!currentWs?.id) return [];
        return windows.filter(w => w.workspace_id === currentWs.id);
    }

    function getWindowsByWorkspaceId(wsid) {
        return windows.filter(w => sameId(w.workspace_id, wsid));
    }

    function getWindowsByWorkspaceIndex(index) {
        if (index < 0 || index >= allWorkspaces.length) return [];
        const wsId = allWorkspaces[index].id;
        return windows.filter(w => sameId(w.workspace_id, wsId));
    }

    function getWindowsInScreen(screenX, screenY, screenWidth, screenHeight, windowBorder, padding) {
        if (!focusedWindow?.layout?.pos_in_scrolling_layout) return [];
        
        const focusedCol = focusedWindow.layout.pos_in_scrolling_layout[0];
        const focusedRow = focusedWindow.layout.pos_in_scrolling_layout[1];
        
        return getActiveWorkspaceWindows().map(window => {
            if (!window.layout?.pos_in_scrolling_layout || !window.layout?.window_size) return null;
            
            const colOffset = window.layout.pos_in_scrolling_layout[0] - focusedCol;
            const rowOffset = window.layout.pos_in_scrolling_layout[1] - focusedRow;
            const focusedWidth = focusedWindow.layout.window_size[0];
            
            let focusedScreenX;
            if (focusedWidth < screenWidth - windowBorder) {
                focusedScreenX = scrollDirection === "left" ? 5 : screenWidth - focusedWidth;
            } else {
                focusedScreenX = 0;
            }
            
            const winX = focusedScreenX + (colOffset * window.layout.window_size[0]) - windowBorder;
            const winY = rowOffset * window.layout.window_size[1] + windowBorder;
            const winW = window.layout.window_size[0] - padding * 2;
            const winH = window.layout.window_size[1] - padding * 2;
            
            if (winX < screenWidth + windowBorder && winY < screenHeight && winX + winW > 0 && winY + winH > 0) {
                return { window: window, screenX: winX, screenY: winY, screenW: winW, screenH: winH };
            }
            return null;
        }).filter(item => item !== null);
    }

    function focusWindow(windowID) {
        if (!available) return false;
        if (sameId(windowID, focusedWindowId) && GlobalConfig.bar.workspaces.doubleClickToCenter) {
            return centerWindow();
        }
        if (isUmbriel)
            return UmbrielIpc.action(`window-focus:${windowID}`);
        return NiriIpc.action("focus-window", ["--id", windowID.toString()]);
    }

    function closeWindow(windowId) {
        if (!available) return false;
        const id = windowId ? windowId.toString() : focusedWindowId.toString();
        if (isUmbriel)
            return UmbrielIpc.action(windowId ? `window-close:${id}` : "window-close");
        return NiriIpc.action("close-window", ["--id", id]);
    }

    function closeFocusedWindow() {
        if (!available) return false;
        if (isUmbriel)
            return UmbrielIpc.action("window-close");
        return NiriIpc.action("close-window", []);
    }

    function toggleWindowFloating(windowId) {
        if (!available) return false;
        const id = windowId ? windowId.toString() : focusedWindowId.toString();
        if (isUmbriel)
            return UmbrielIpc.action(windowId ? `window-toggle-floating:${id}` : "window-toggle-floating");
        return NiriIpc.action("toggle-window-floating", ["--id", id]);
    }

    function toggleWindowOpacity() {
        if (!isNiri || !available) return false;
        return NiriIpc.action("toggle-window-rule-opacity", []);
    }

    function expandColumnToAvailable() {
        if (!isNiri || !available) return false;
        return NiriIpc.action("expand-column-to-available-width", []);
    }

    function centerWindow() {
        if (!available) return false;
        if (isUmbriel)
            return UmbrielIpc.action(focusedWindow?.floating ? "window-center" : "column-center");
        return NiriIpc.action("center-window", []);
    }

    function screenshotWindow() {
        if (!isNiri || !available) return false;
        return NiriIpc.action("screenshot-window", []);
    }

    function keyboardShortcutsInhibitWindow() {
        if (!available) return false;
        if (isUmbriel)
            return UmbrielIpc.action("shortcuts-inhibit-toggle");
        return NiriIpc.action("toggle-keyboard-shortcuts-inhibit", []);
    }

    function toggleWindowedFullscreen() {
        if (!available) return false;
        if (isUmbriel)
            return UmbrielIpc.action("window-toggle-fullscreen");
        return NiriIpc.action("toggle-windowed-fullscreen", []);
    }

    function toggleFullscreen() {
        if (!available) return false;
        if (isUmbriel)
            return UmbrielIpc.action("window-toggle-fullscreen");
        return NiriIpc.action("fullscreen-window", []);
    }

    function toggleMaximize() {
        if (!available) return false;
        if (isUmbriel)
            return UmbrielIpc.action("window-toggle-maximize");
        return NiriIpc.action("maximize-column", []);
    }

    function toggleOverview() {
        if (!available) return false;
        if (isUmbriel)
            return UmbrielIpc.action("overview-toggle");
        return NiriIpc.action("toggle-overview", []);
    }

    function doScreenTransition(delayMs) {
        if (!isNiri || !available) return false;
        var delay = delayMs !== undefined ? delayMs : 500;
        return NiriIpc.action("do-screen-transition", ["-d", delay.toString()]);
    }

    function moveColumnToIndex(windowId, index) {
        if (!isNiri || !available) return false;
        if (focusWindow(windowId)) {
            return NiriIpc.action("move-column-to-index", [index.toString()]);
        }
        return false;
    }

    function moveColumnToIndexAfterFocus(windowId, index) {
        if (!isNiri || !available) return false;
        
        if (sameId(windowId, focusedWindowId)) {
            return NiriIpc.action("move-column-to-index", [index.toString()]);
        }
        
        _moveAfterFocusPendingId = windowId.toString();
        _moveAfterFocusPendingCb = function() {
            NiriIpc.action("move-column-to-index", [index.toString()]);
        };
        
        focusWindow(windowId);
        return true;
    }

    function moveGroupColumnsSequential(initialWindowId, windowIds, targetIndex) {
        if (!isNiri)
            return;
        if (!windowIds || windowIds.length === 0) return;
        
        // Start the state machine logic
        _seqState = {
            initialWindowId: initialWindowId,
            curWindowId: windowIds[0], // We wait for the first window to gain focus
            windowIds: windowIds,
            targetIndex: targetIndex,
            i: 1 // Start at 1, since we're immediately dispatching index 0 below
        };
        
        // Dispatch the first sequence trigger
        moveColumnToIndexAfterFocus(windowIds[0], targetIndex);
    }

    // --- Grouping Functions ---
    function sortWindows(windowList) {
        return windowList.slice().sort((a, b) => {
            const aPos = Array.isArray(a.layout?.pos_in_scrolling_layout) 
                ? a.layout.pos_in_scrolling_layout : [0, 0];
            const bPos = Array.isArray(b.layout?.pos_in_scrolling_layout) 
                ? b.layout.pos_in_scrolling_layout : [0, 0];
            if (aPos[0] !== bPos[0]) return aPos[0] - bPos[0];
            return aPos[1] - bPos[1];
        });
    }

    function groupWindowsByApp(windowList) {
        windowList = sortWindows(windowList);
        var groups = {};
        
        for (var j = 0; j < windowList.length; j++) {
            var w = windowList[j];
            var appId = w.app_id || "unknown";
            if (!groups[appId]) {
                groups[appId] = {
                    app_id: appId,
                    id: w.id,
                    title: w.title,
                    index: w.index,
                    windows: []
                };
            }
            groups[appId].windows.push(w);
        }
        
        var result = [];
        for (var key in groups) {
            var g = groups[key];
            g.count = g.windows.length;
            g.main = g.windows[0];
            result.push(g);
        }
        return result;
    }

    function groupWindowsByLayoutAndId(windowList) {
        windowList = sortWindows(windowList);
        var groups = [];
        var currentGroup = null;

        for (var j = 0; j < windowList.length; j++) {
            var w = windowList[j];
            if (!currentGroup || currentGroup.app_id !== w.app_id) {
                currentGroup = {
                    app_id: w.app_id,
                    windows: [w],
                    count: 1,
                    title: w.title,
                    id: w.id,
                    main: w
                };
                groups.push(currentGroup);
            } else {
                currentGroup.windows.push(w);
                currentGroup.count = currentGroup.windows.length;
            }
        }
        return groups;
    }
}
