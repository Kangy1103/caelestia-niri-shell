// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.8.0-20260615


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.components
import CNS.Config
import qs.services

Item {
    id: root

    required property ShellScreen screen

    readonly property int sectionSpacing: Tokens.padding.medium
    readonly property int cellGap: 3
    readonly property int cellMinWidth: 210
    readonly property int cellMinHeight: 190
    readonly property int headerHeight: 36

    readonly property var workspaces: {
        const all = Niri.allWorkspaces;
        if (!all || !all.length) return [];
        return all.filter(ws => ws.output === root.screen.name);
    }

    readonly property int maxCols: {
        let max = 0;
        for (const ws of workspaces) {
            const wsWindows = Niri.getWindowsByWorkspaceId(ws.id) || [];
            let mc = 0;
            for (const w of wsWindows) {
                const col = (w.layout?.pos_in_scrolling_layout || [0, 0])[0];
                if (col > mc) mc = col;
            }
            if (mc + 1 > max) max = mc + 1;
        }
        return max;
    }

    readonly property int contentWidth: Math.max(
        Config.bar.workspaces.windowContextWidth,
        (maxCols * (cellMinWidth + cellGap)) + cellGap
    )

    // Flat window list for sequential capture
    readonly property var captureList: {
        Niri.windows;
        const list = [];
        for (const ws of workspaces)
            for (const w of Niri.getWindowsByWorkspaceId(ws.id) || [])
                list.push(w);
        return list;
    }
    property string previewDir: "/tmp"
    property var cellMap: ({})

    // ── Drag-and-Drop ────────────────────────────────────────────────
    property var dragData: null
    property point dragPos
    property int dropWsIndex: -1

    function findWsAndCell(mx, my) {
        var children = contentColumn.children
        if (!children || !children.length) return null
        var dIdx = 0
        for (var i = 0; i < children.length; i++) {
            var sec = children[i]
            if (!sec || sec.modelData === undefined) continue
            var pt = sec.mapFromItem(root, mx, my)
            var localX = pt.x; var localY = pt.y
            var secH = sec.implicitHeight
            if (localX < 0 || localY < 0 || localX > sec.width || localY > secH) { dIdx++; continue }
            if (localY <= headerHeight)
                return { type: "workspace", wsIndex: dIdx, wsId: sec.modelData.id, wsName: sec.modelData.name || "" }
            var wsWindows = Niri.getWindowsByWorkspaceId(sec.modelData.id) || []
            if (wsWindows.length === 0) { dIdx++; continue }
            var gridTop = headerHeight + Tokens.padding.medium
            var cellY = localY - gridTop
            if (cellY < 0) cellY = 0
            var cellX = localX
            var rowIdx = Math.floor(cellY / (cellMinHeight + cellGap))
            var colIdx = Math.floor(cellX / (cellMinWidth + cellGap))
            var minR = 999, minC = 999
            for (var w = 0; w < wsWindows.length; w++) {
                var p = wsWindows[w].layout?.pos_in_scrolling_layout || [0, 0]
                if (typeof p[1] === "number" && p[1] < minR) minR = p[1]
                if (typeof p[0] === "number" && p[0] < minC) minC = p[0]
            }
            if (minR === 999) minR = 0
            if (minC === 999) minC = 0
            var tR = rowIdx + minR, tC = colIdx + minC
            for (var w = 0; w < wsWindows.length; w++) {
                var pos = wsWindows[w].layout?.pos_in_scrolling_layout || [0, 0]
                if (pos[0] === tC && pos[1] === tR)
                    return { type: "window", wsIndex: dIdx, wsId: sec.modelData.id, windowId: wsWindows[w].id }
            }
            dIdx++
        }
        return null
    }

    function recomputeDropTarget() {
        if (!dragData) return
        var children = contentColumn.children
        if (!children || !children.length) return
        dropWsIndex = -1
        if (dragData.type === "window") {
            var dIdx = 0
            for (var i = 0; i < children.length; i++) {
                var sec = children[i]
                if (!sec || sec.modelData === undefined) continue
                var pt = sec.mapFromItem(root, dragPos.x, dragPos.y)
                if (pt.x >= 0 && pt.y >= 0 && pt.x <= sec.width && pt.y <= sec.implicitHeight) { dropWsIndex = dIdx; return }
                dIdx++
            }
        } else {
            var target = -1, dIdx2 = 0
            var cy = dragPos.y - Tokens.padding.large
            for (var j = 0; j < children.length; j++) {
                var sec2 = children[j]
                if (!sec2 || sec2.modelData === undefined) continue
                var midY = sec2.y + sec2.implicitHeight / 2
                if (cy < midY) { target = dIdx2; break }
                dIdx2++
            }
            if (target === -1) target = dIdx2
            dropWsIndex = target + 1
        }
    }

    function beginDrag() { recomputeDropTarget(); dragPreview.visible = true }
    function endDrag(doDrop) {
        if (doDrop && dragData) {
            var d = dragData
            if (d.type === "window" && dropWsIndex >= 0) {
                var wsList = workspaces
                var sameWs = d.wsId && dropWsIndex < wsList.length && wsList[dropWsIndex].id === d.wsId
                if (!sameWs && dropWsIndex < wsList.length) {
                    var ref = wsList[dropWsIndex].name || wsList[dropWsIndex].id.toString()
                    moveWinProc.exec({ command: ["/usr/bin/niri", "msg", "action", "move-window-to-workspace", "--window-id", d.windowId.toString(), "--focus", "false", ref] })
                }
            } else if (d.type === "workspace" && dropWsIndex >= 1) {
                var wref = d.wsName || d.wsId.toString()
                moveWsProc.exec({ command: ["/usr/bin/niri", "msg", "action", "move-workspace-to-index", "--reference", wref, dropWsIndex.toString()] })
            }
        }
        dragData = null; dragPreview.visible = false; dropWsIndex = -1
    }

    Process { id: moveWinProc }
    Process { id: moveWsProc }

    MouseArea {
        id: dragHandler
        anchors.fill: parent; z: 1
        pressAndHoldInterval: 250
        property var clickTarget: null
        onPressed: function(mouse) {
            clickTarget = findWsAndCell(mouse.x, mouse.y)
            mouse.accepted = clickTarget !== null
        }
        onPressAndHold: function(mouse) {
            if (!clickTarget || dragData) return
            dragData = { type: clickTarget.type, wsIndex: clickTarget.wsIndex, wsId: clickTarget.wsId, wsName: clickTarget.wsName, windowId: clickTarget.windowId }
            dragPos = Qt.point(mouse.x, mouse.y); beginDrag()
        }
        onPositionChanged: function(mouse) {
            if (!dragData) return
            dragPos = Qt.point(mouse.x, mouse.y); recomputeDropTarget()
        }
        onReleased: function(mouse) {
            if (dragData) { endDrag(true); clickTarget = null }
            else if (clickTarget) {
                if (clickTarget.type === "workspace") { var wsList = workspaces; if (clickTarget.wsIndex < wsList.length) Niri.switchToWorkspace(wsList[clickTarget.wsIndex].id) }
                else if (clickTarget.type === "window") Niri.focusWindow(clickTarget.windowId)
                clickTarget = null
            }
        }
    }

    Rectangle {
        id: dragPreview; visible: false; z: 100
        x: dragPos.x - width / 2; y: dragPos.y - height / 2
        width: dragData?.type === "workspace" ? Math.min(root.width - Tokens.padding.medium * 2, root.contentWidth - Tokens.padding.medium) : cellMinWidth
        height: dragData?.type === "workspace" ? headerHeight : cellMinHeight
        radius: Tokens.rounding.small
        color: Colours.palette.m3primaryContainer; opacity: 0.8
        border.width: 1; border.color: Colours.palette.m3primary
        StyledText {
            anchors.centerIn: parent
            text: dragData?.type === "workspace" ? (dragData.wsName || (dragData.wsIndex + 1).toString()) : (dragData?.windowTitle || "Window")
            font.pointSize: Config.appearance.font.label.small.size
            font.bold: dragData?.type === "workspace"; color: Colours.palette.m3onPrimaryContainer
            elide: Text.ElideRight; width: parent.width - 8; horizontalAlignment: Text.AlignHCenter
        }
    }

    implicitWidth: contentWidth
    implicitHeight: {
        Niri.windows;
        let total = 0;
        const ws = workspaces;
        for (let i = 0; i < ws.length; i++) {
            const wsWindows = Niri.getWindowsByWorkspaceId(ws[i].id) || [];
            let mc = 0, mr = 0, minC = Infinity, minR = Infinity;
            for (const w of wsWindows) {
                const pos = w.layout?.pos_in_scrolling_layout || [0, 0];
                if (pos[0] > mc) mc = pos[0];
                if (pos[0] < minC) minC = pos[0];
                if (pos[1] > mr) mr = pos[1];
                if (pos[1] < minR) minR = pos[1];
            }
            const cols = mc - (isFinite(minC) ? minC : 0) + 1;
            const rows = mr - (isFinite(minR) ? minR : 0) + 1;
            const gridH = rows > 0 ? (rows * (cellMinHeight + cellGap)) - cellGap : 0;
            const secH = headerHeight + gridH + (gridH > 0 ? Tokens.padding.small : cellMinHeight);
            total += secH;
            if (i < ws.length - 1) total += sectionSpacing;
        }
        return Math.max(total + Tokens.padding.large, 60);
    }

    clip: true

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: Tokens.padding.large
        anchors.leftMargin: Tokens.padding.medium
        contentHeight: contentColumn.implicitHeight
        clip: true

        ScrollBar.vertical: ScrollBar {}

        ColumnLayout {
            id: contentColumn
            width: flickable.width
            spacing: sectionSpacing

            Repeater {
                model: root.workspaces

                delegate: Rectangle {
                    id: wsSection
                    required property var modelData
                    required property int index

                    readonly property var windows: {
                        const wsWindows = Niri.getWindowsByWorkspaceId(modelData.id) || [];
                        return wsWindows.map(w => {
                            const pos = w.layout?.pos_in_scrolling_layout || [0, 0];
                            return { col: pos[0], row: pos[1], window: w };
                        });
                    }

                    readonly property var gridMetrics: {
                        if (windows.length === 0) return { cols: 0, rows: 0, minCol: 0, minRow: 0 };
                        let mc = 0, mr = 0, minC = Infinity, minR = Infinity;
                        for (const c of windows) {
                            if (c.col > mc) mc = c.col;
                            if (c.col < minC) minC = c.col;
                            if (c.row > mr) mr = c.row;
                            if (c.row < minR) minR = c.row;
                        }
                        return { cols: mc - minC + 1, rows: mr - minR + 1, minCol: minC, minRow: minR };
                    }

                    readonly property int cellW: cellMinWidth
                    readonly property int cellH: cellMinHeight

                    readonly property int gridW: (gridMetrics.cols || 0) === 0 ? 0
                        : (gridMetrics.cols * (cellW + cellGap)) - cellGap
                    readonly property int gridH: (gridMetrics.rows || 0) === 0 ? 0
                        : (gridMetrics.rows * (cellH + cellGap)) - cellGap

                    readonly property bool isFocused: modelData.isFocused ?? false
                    readonly property string wsLabel: modelData.name || (index + 1).toString()

                    Layout.fillWidth: true
                    Layout.topMargin: index === 0 ? Tokens.padding.extraSmall : 0
                    implicitWidth: parent.width
                    implicitHeight: headerHeight + gridH + (gridH > 0 ? Tokens.padding.small : cellMinHeight)
                    color: "transparent"

                    // Drop indicator bar (workspace reorder)
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right
                        y: -3; height: 4; radius: 2; color: Colours.palette.m3primary
                        opacity: root.dragData?.type === "workspace" && root.dropWsIndex === wsSection.index + 1 ? 0.9 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Rectangle {
                        id: sectionHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: wsSection.headerHeight
                        radius: Tokens.rounding.small
                        color: wsSection.isFocused ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest
                        border.width: headerMouse.containsMouse ? 1 : 0
                        border.color: wsSection.isFocused ? Colours.palette.m3primary : Colours.palette.m3outline

                        Behavior on border.width { NumberAnimation { duration: 150 } }

                        StyledText {
                            anchors.centerIn: parent
                            text: wsSection.wsLabel
                            font.pointSize: Config.appearance.font.label.small.size
                            font.bold: wsSection.isFocused
                            color: wsSection.isFocused ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                        }

                        MouseArea {
                            id: headerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Niri.switchToWorkspace(modelData.id)
                        }
                    }

                    Item {
                        id: gridContainer
                        anchors.top: sectionHeader.bottom
                        anchors.topMargin: Tokens.padding.medium
                        anchors.left: parent.left
                        width: wsSection.gridW
                        height: wsSection.gridH

                        // Blue drop indicator at end of row
                        Rectangle {
                            visible: root.dragData?.type === "window" && root.dropWsIndex === wsSection.index
                            x: wsSection.gridW > 0 ? wsSection.gridW + 2 : 0
                            y: 0
                            width: 3; height: wsSection.gridH > 0 ? wsSection.gridH : cellMinHeight
                            radius: 2; color: Colours.palette.m3primary
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        Repeater {
                            model: wsSection.windows

                            delegate: Rectangle {
                                id: cell
                                required property var modelData
                                required property int index

                                readonly property var win: modelData.window
                                readonly property int col: modelData.col
                                readonly property int row: modelData.row
                                readonly property bool isFocused: Number(Niri.focusedWindowId) === Number(win.id)
                                readonly property string appId: win.app_id || ""
                                readonly property string displayTitle: Niri.cleanWindowTitle(win.title || "Untitled")
                                readonly property string previewPath: root.previewDir + "/cns-preview-" + Number(win.id) + ".png"
                                property int screenshotRev: 0

                                x: (col - wsSection.gridMetrics.minCol) * (wsSection.cellW + cellGap)
                                y: (row - wsSection.gridMetrics.minRow) * (wsSection.cellH + cellGap)
                                width: wsSection.cellW
                                height: wsSection.cellH
                                radius: Tokens.rounding.small
                                color: isFocused ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest
                                border.width: isFocused ? 2 : 0
                                border.color: Colours.palette.m3primary

                                Behavior on border.width { NumberAnimation { duration: 150 } }

                                Component.onCompleted: { root.cellMap[Number(win.id)] = cell }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Niri.focusWindow(win.id)
                                }

                                Image {
                                    id: previewImage
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    fillMode: Image.PreserveAspectCrop
                                    source: cell.screenshotRev > 0 ? "file:" + cell.previewPath + "?r=" + cell.screenshotRev : ""
                                    cache: false
                                    visible: status === Image.Ready
                                }

                                IconImage {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: -6
                                    implicitSize: Math.max(wsSection.cellW * 0.5, 24)
                                    source: Icons.getAppIcon(cell.appId, "image-missing")
                                    smooth: true
                                    visible: previewImage.status !== Image.Ready
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 2
                                    width: parent.width - 4
                                    text: cell.displayTitle
                                    elide: Text.ElideRight
                                    font.pointSize: Math.max(Config.appearance.font.label.small.size * 0.7, 6)
                                    color: previewImage.status === Image.Ready ? Colours.palette.m3onSurface
                                        : (cell.isFocused ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant)
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }

                    StyledText {
                        visible: wsSection.windows.length === 0
                        anchors.top: sectionHeader.bottom
                        anchors.topMargin: Tokens.padding.medium
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "empty"
                        font.pointSize: Config.appearance.font.label.small.size * 0.8
                        color: emptyMouse.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: emptyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Niri.switchToWorkspace(modelData.id)
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: Colours.palette.m3outlineVariant
                    }
                }
            }

            StyledText {
                visible: root.workspaces.length === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.padding.large
                text: "No workspaces on this monitor"
                font.pointSize: Config.appearance.font.label.small.size
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    // ── Capture Chain ────────────────────────────────────────────────

    property int captureIndex: 0

    Process {
        id: captureProc
        onExited: {
            // Update cell immediately for this window
            if (captureIndex < captureList.length && exitCode === 0) {
                const cell = cellMap[Number(captureList[captureIndex].id)]
                if (cell) cell.screenshotRev += 1
            }
            captureIndex += 1
            if (captureIndex < captureList.length) {
                captureNext()
            } else {
                // All done — clean up cliphist via detached process (survives popout close)
                Quickshell.execDetached(["sh", "-c",
                    "sleep 0.5; " +
                    "for i in $(seq 1 " + captureList.length + "); do " +
                    "id=$(/usr/bin/cliphist -db-path /home/kangy/.cache/cliphist/db list | head -1 | awk '{print $1}'); " +
                    "[ -n \"$id\" ] && printf '%s' \"$id\" | /usr/bin/cliphist -db-path /home/kangy/.cache/cliphist/db delete; " +
                    "done"
                ])
            }
        }
    }

    function captureNext() {
        if (captureIndex >= captureList.length) return
        const wid = captureList[captureIndex].id
        const path = previewDir + "/cns-preview-" + wid + ".png"
        captureProc.exec({ command: ["sh", "-c",
            "/usr/bin/niri msg action screenshot-window --id " + wid + " --path " + path] })
    }

    function startCaptureChain() {
        if (captureList.length === 0) return
        captureIndex = 0
        captureNext()
    }

    Component.onCompleted: {
        startCaptureChain()
    }

    Timer { id: recaptureTimer; interval: 300; onTriggered: startCaptureChain() }
    Connections { target: Niri; function onWindowsChanged() { recaptureTimer.restart() } }
}
