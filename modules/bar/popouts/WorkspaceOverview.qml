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

    readonly property int sectionSpacing: Config.appearance.padding.medium
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
            const secH = headerHeight + gridH + (gridH > 0 ? Config.appearance.padding.small : cellMinHeight);
            total += secH;
            if (i < ws.length - 1) total += sectionSpacing;
        }
        return Math.max(total + Config.appearance.padding.large, 60);
    }

    clip: true

    StyledRect {
        anchors.fill: parent
        radius: Config.appearance.rounding.large
        color: Colours.palette.m3surfaceContainerLow
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: Config.appearance.padding.large
        anchors.leftMargin: Config.appearance.padding.medium
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
                    Layout.topMargin: index === 0 ? Config.appearance.padding.extraSmall : 0
                    implicitWidth: parent.width
                    implicitHeight: headerHeight + gridH + (gridH > 0 ? Config.appearance.padding.small : cellMinHeight)
                    color: "transparent"

                    Rectangle {
                        id: sectionHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: wsSection.headerHeight
                        radius: Config.appearance.rounding.small
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
                        anchors.topMargin: Config.appearance.padding.small
                        anchors.left: parent.left
                        width: wsSection.gridW
                        height: wsSection.gridH

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
                                radius: Config.appearance.rounding.small
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
                        anchors.topMargin: Config.appearance.padding.small
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
                Layout.topMargin: Config.appearance.padding.large
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
}
