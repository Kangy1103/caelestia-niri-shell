// Created by Kangy w/ OpenCode AI Assistance
// Based on Noctalia Shell (v4.7.7) Workspace.qml
// Version: 4.1.0-20260603

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Internal
import qs.components
import qs.config
import qs.services
import qs.utils

StyledRect {
    id: root

    readonly property bool isVertical: true
    readonly property real barHeight: Config.bar.sizes.innerWidth
    readonly property real capsuleHeight: Config.bar.sizes.innerWidth * 0.85
    readonly property real barFontSize: Appearance.font.size.labelLarge

    required property ShellScreen screen

    readonly property bool showApplications: Config.bar.workspaces.showWindows
    readonly property int iconSize: Config.bar.workspaces.windowIconSize

    readonly property string labelMode: "index"
    readonly property bool hasLabel: labelMode !== "none"
    readonly property int fontWeight: Font.Medium
    readonly property int characterCount: 2
    readonly property real textRatio: 0.50

    readonly property real pillSize: 1.0
    readonly property real baseDimensionRatio: pillSize
    readonly property bool showLabelsOnlyWhenOccupied: false
    readonly property bool enableScrollWheel: true
    readonly property bool reverseScroll: false

    readonly property string focusedColor: "primary"
    readonly property string occupiedColor: "surfaceContainerHigh"
    readonly property string emptyColor: "outlineVariant"

    property ListModel localWorkspaces: ListModel {}
    property int lastFocusedWorkspaceId: -1
    property real masterProgress: 0.0
    property bool effectsActive: false
    property color effectColor: Colours.palette.m3primary

    property int horizontalPadding: Math.round(Appearance.padding.xs)
    property int spacingBetweenPills: Math.round(Appearance.spacing.sm / 2)
    property int windowRevision: 0

    property int wheelAccumulatedDelta: 0
    property bool wheelCooldown: false

    signal requestWindowPopout

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: showApplications ? computeGroupedHeight() : (pillColumn.visible ? pillColumn.implicitHeight : groupedGrid.visible ? groupedGrid.implicitHeight : capsuleHeight) + horizontalPadding * 2
    Component.onCompleted: {
        refreshWorkspaces()
    }

    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.full

    Connections {
        target: Niri
        function onWsContextTypeChanged() {
            if (Niri.wsContextType === "workspaces")
                Niri.wsContextAnchor = root;
        }
    }

    // ===== Dimension helpers =====

    function getWorkspaceWidth(ws, activeOverride) {
        const d = Math.round(capsuleHeight * root.baseDimensionRatio);
        const isActive = activeOverride !== undefined ? activeOverride : ws.isActive;
        const factor = isActive ? 2.2 : 1;
        if (labelMode === "none")
            return Math.round(d * factor);

        var displayText = (ws.idx ?? 0).toString();
        if (ws.name && ws.name.length > 0) {
            if (root.labelMode === "name")
                displayText = ws.name.substring(0, characterCount);
            else if (root.labelMode === "index+name")
                displayText = (ws.idx ?? 0).toString() + " " + ws.name.substring(0, characterCount);
        }
        const textWidth = displayText.length * (d * 0.4);
        const padding = d * 0.6;
        return Math.round(Math.max(d * factor, textWidth + padding));
    }

    function getWorkspaceHeight(ws, activeOverride) {
        const d = Math.round(capsuleHeight * root.baseDimensionRatio);
        const isActive = activeOverride !== undefined ? activeOverride : ws.isActive;
        const factor = isActive ? 2.2 : 1;
        return Math.round(d * factor);
    }

    function computeHeight() {
        let total = 0;
        for (var i = 0; i < localWorkspaces.count; i++) {
            const ws = localWorkspaces.get(i);
            total += getWorkspaceHeight(ws, false);
        }
        total += Math.max(localWorkspaces.count - 1, 0) * spacingBetweenPills;
        total += horizontalPadding * 2;
        return Math.round(total);
    }

    function computeGroupedHeight() {
        let h = localWorkspaces.count * (iconSize + horizontalPadding)
                + (localWorkspaces.count - 1) * spacingBetweenPills
                + horizontalPadding * 2;
        return Math.max(capsuleHeight, h);
    }

    // ===== Workspace switching =====

    function getFocusedLocalIndex() {
        for (var i = 0; i < localWorkspaces.count; i++) {
            if (localWorkspaces.get(i).isFocused === true)
                return i;
        }
        return -1;
    }

    function switchByOffset(offset) {
        if (localWorkspaces.count <= 1) return;
        var current = getFocusedLocalIndex();
        if (current < 0) current = 0;
        var next = (current + offset) % localWorkspaces.count;
        if (next < 0) next = localWorkspaces.count - 1;
        if (next === current) return;
        const ws = localWorkspaces.get(next);
        if (ws && ws.id !== undefined)
            Niri.switchToWorkspace(ws.id);
    }

    // ===== Sync logic =====

    function scheduleRefresh() {
        Qt.callLater(root.refreshWorkspaces);
    }

    // Workaround: NiriIpc binary doesn't handle WorkspaceActivated events,
    // so ws.is_focused is stale after initial load. Derive focus from the
    // focused window's workspace_id instead, since WindowFocusChanged IS handled.
    property int _focusedWsId: -1

    function updateFocusedWorkspaceId() {
        var fwId = Number(Niri.focusedWindowId);
        if (fwId > 0) {
            var wins = Niri.windows;
            for (var i = 0; i < wins.length; i++) {
                if (Number(wins[i].id) === fwId) {
                    root._focusedWsId = Number(wins[i].workspace_id);
                    return;
                }
            }
        }
        // Fallback: empty workspace or no focused window — use stale is_focused
        var allWs = Niri.allWorkspaces;
        for (var i = 0; i < allWs.length; i++) {
            if (allWs[i].is_focused) {
                root._focusedWsId = Number(allWs[i].id);
                return;
            }
        }
        root._focusedWsId = -1;
    }

    function refreshWorkspaces() {
        root.updateFocusedWorkspaceId();

        var allWs = Niri.allWorkspaces;
        if (!allWs) allWs = [];

        var outputName = root.screen.name;
        var wsList = [];
        for (var i = 0; i < allWs.length; i++) {
            if (allWs[i].output === outputName) {
                wsList.push(allWs[i]);
            }
        }
        if (wsList.length === 0) wsList = allWs;

        var targetList = [];
        for (var i = 0; i < wsList.length; i++) {
            const ws = wsList[i];
            targetList.push({
                id: ws.id,
                idx: ws.idx,
                name: ws.name ?? "",
                output: ws.output ?? "",
                isFocused: Number(ws.id) === root._focusedWsId,
                isActive: Number(ws.id) === root._focusedWsId,
                isUrgent: ws.is_urgent ?? false,
                isOccupied: Niri.workspaceHasWindows[String(ws.idx)] ?? false
            });
        }

        var j = 0;
        while (j < localWorkspaces.count || j < targetList.length) {
            if (j < localWorkspaces.count && j < targetList.length) {
                var existing = localWorkspaces.get(j);
                var target = targetList[j];
                if (existing.id === target.id) {
                    localWorkspaces.set(j, target);
                    j++;
                } else {
                    localWorkspaces.remove(j);
                }
            } else if (j < localWorkspaces.count) {
                localWorkspaces.remove(j);
            } else {
                localWorkspaces.append(targetList[j]);
                j++;
            }
        }

        updateWorkspaceFocus();
    }

    function updateWorkspaceFocus() {
        for (var i = 0; i < localWorkspaces.count; i++) {
            const ws = localWorkspaces.get(i);
            if (ws.isFocused === true) {
                if (root.lastFocusedWorkspaceId !== -1 && root.lastFocusedWorkspaceId !== ws.id) {
                    root.triggerUnifiedWave();
                }
                root.lastFocusedWorkspaceId = ws.id;
                break;
            }
        }
    }

    // ===== Burst effect =====

    function triggerUnifiedWave() {
        effectColor = Colours.palette.m3primary;
        masterAnimation.restart();
    }

    SequentialAnimation {
        id: masterAnimation
        PropertyAction {
            target: root; property: "effectsActive"; value: true
        }
        NumberAnimation {
            target: root; property: "masterProgress"
            from: 0.0; to: 1.0
            duration: 600
            easing.type: Easing.OutQuint
        }
        PropertyAction {
            target: root; property: "effectsActive"; value: false
        }
        PropertyAction {
            target: root; property: "masterProgress"; value: 0.0
        }
    }

    // ===== Signal connections =====

    Connections {
        target: NiriIpc
        function onWorkspacesChanged() { scheduleRefresh(); }
        function onFocusedWorkspaceChanged() { scheduleRefresh(); }
        function onWorkspaceHasWindowsChanged() { scheduleRefresh(); }
    }

    Connections {
        target: Niri
        function onWindowOpenedOrChanged() {
            if (showApplications) root.windowRevision++;
            scheduleRefresh();
        }
        function onFocusedWindowIdChanged() {
            if (showApplications) root.windowRevision++;
            scheduleRefresh();
        }
        function onWindowsChanged() {
            if (showApplications) root.windowRevision++;
            scheduleRefresh();
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: scheduleRefresh()
    }

    // ===== Wheel scrolling =====

    Timer {
        id: wheelDebounce
        interval: 150
        repeat: false
        onTriggered: {
            root.wheelCooldown = false;
            root.wheelAccumulatedDelta = 0;
        }
    }

    WheelHandler {
        id: wheelHandler
        target: root
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        enabled: root.enableScrollWheel
        onWheel: function (event) {
            if (root.wheelCooldown) return;
            var dy = event.angleDelta.y;
            var dx = event.angleDelta.x;
            var useDy = Math.abs(dy) >= Math.abs(dx);
            var delta = useDy ? dy : dx;
            root.wheelAccumulatedDelta += delta;
            var step = 120;
            if (Math.abs(root.wheelAccumulatedDelta) >= step) {
                var direction = root.wheelAccumulatedDelta > 0 ? -1 : 1;
                if (root.reverseScroll) direction *= -1;
                root.switchByOffset(direction);
                root.wheelCooldown = true;
                wheelDebounce.restart();
                root.wheelAccumulatedDelta = 0;
                event.accepted = true;
            }
        }
    }

    // ===== Standard pill mode =====

    Column {
        id: pillColumn
        visible: !showApplications
        spacing: spacingBetweenPills
        x: Math.round((parent.width - width) / 2)
        y: horizontalPadding
        width: capsuleHeight

        Repeater {
            id: workspaceRepeater
            model: localWorkspaces
            delegate: WorkspacePill {
                required property var modelData
                workspace: modelData
                isVertical: root.isVertical
                baseDimensionRatio: root.baseDimensionRatio
                capsuleHeight: root.capsuleHeight
                barHeight: root.barHeight
                labelMode: root.labelMode
                fontWeight: root.fontWeight
                characterCount: root.characterCount
                textRatio: root.textRatio
                showLabelsOnlyWhenOccupied: root.showLabelsOnlyWhenOccupied
                focusedColor: root.focusedColor
                occupiedColor: root.occupiedColor
                emptyColor: root.emptyColor
                masterProgress: root.masterProgress
                effectsActive: root.effectsActive
                effectColor: root.effectColor
                getWorkspaceWidth: root.getWorkspaceWidth
                getWorkspaceHeight: root.getWorkspaceHeight
            }
        }
    }

    // ===== Grouped mode (app icons) =====

    Flow {
        id: groupedGrid
        visible: showApplications
        flow: Flow.TopToBottom
        spacing: spacingBetweenPills

        anchors.centerIn: parent

        Repeater {
            model: showApplications ? localWorkspaces : null
            delegate: Rectangle {
                id: groupedContainer
                required property var modelData

                property var liveWindows: {
                    var _ = root.windowRevision;
                    var wins = Niri.getWindowsByWorkspaceId(modelData.id) ?? [];
                    var focusedId = Number(Niri.focusedWindowId);
                    var result = [];
                    for (var i = 0; i < wins.length; i++) {
                        if (Number(wins[i].id) === focusedId) {
                            result.unshift(wins[i]);
                        } else {
                            result.push(wins[i]);
                        }
                    }
                    if (result.length === 0) result = wins;
                    return result;
                }

                width: iconSize + horizontalPadding
                height: iconSize + horizontalPadding

                color: modelData.isFocused ? Colours.palette.m3primaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)
                radius: Appearance.rounding.small
                border.color: modelData.isFocused ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outlineVariant, 0.2)
                border.width: modelData.isFocused ? 2 : 1

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Repeater {
                        model: groupedContainer.liveWindows.length > 0 ? [groupedContainer.liveWindows[0]] : []

                        delegate: IconImage {
                            required property var modelData
                            width: iconSize
                            height: iconSize
                            source: Icons.getAppIcon(modelData.app_id ?? "", "image-missing")
                            smooth: true
                            asynchronous: true
                        }
                    }

                    StyledText {
                        text: modelData.idx.toString()
                        font.pointSize: 7
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: groupedContainer.liveWindows.length === 0
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        Niri.switchToWorkspace(modelData.id);
                    }
                }
            }
        }

        Behavior on visible {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.OutBack
            }
        }
    }
}
