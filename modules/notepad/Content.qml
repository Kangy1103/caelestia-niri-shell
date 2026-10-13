// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.3.0-20260615

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CNS
import CNS.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property ScreenState screenState: ShellState.forScreen(screen)

    readonly property string defaultNotesDir: `${Paths.home}/Documents/cns-notes`
    property string notesDir: ""
    property string currentNote: ""
    property string editorContent: ""
    property string oldEditorContent: ""
    property string previewMode: "off"
    property bool hasUnsavedChanges: false
    property bool showSaveIndicator: false

    implicitWidth: 680
    implicitHeight: 620

    ListModel {
        id: notesModel
    }

    Process {
        id: scanProc
        running: false
        command: ["sh", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                notesModel.clear()
                const lines = (text || "").trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var f = lines[i].trim()
                    if (f !== "") notesModel.append({ name: f })
                }
            }
        }
    }

    Process {
        id: loadProc
        running: false
        command: ["cat", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                var content = text || ""
                root.editorContent = content
                root.oldEditorContent = content
                root.hasUnsavedChanges = false
                root.saveSettings()
            }
        }
    }

    Timer {
        id: focusTimer
        interval: 200
        repeat: false
        onTriggered: { if (titleInput) titleInput.forceActiveFocus() }
    }

    Component.onCompleted: {
        var dir = notesDir || defaultNotesDir
        Quickshell.execDetached(["mkdir", "-p", dir])
        scanNotes()
        focusTimer.start()
    }

    Connections {
        target: Qt.application
        function onActiveChanged() {
            if (!Qt.application.active && root.hasUnsavedChanges && root.currentNote.trim() !== "")
                root.saveNote()
        }
    }

    Component.onDestruction: {
        if (root.hasUnsavedChanges && root.currentNote.trim() !== "")
            root.saveNote()
    }

    Timer { id: saveIndicatorTimer; interval: 1500; onTriggered: root.showSaveIndicator = false }
    Timer { id: scanTimer; interval: 300; repeat: false; onTriggered: scanNotes() }

    Connections {
        target: root.screenState
        function onNotepadChanged(): void {
            if (root.screenState.notepad) {
                scanNotes()
                focusTimer.start()
            }
        }
    }

    function scanNotes(): void {
        var dir = notesDir || defaultNotesDir
        scanProc.command = ["sh", "-c", "ls -1t \"" + dir + "\" 2>/dev/null || true"]
        scanProc.running = true
    }

    function saveNote(): void {
        var name = currentNote.trim()
        if (name === "") { name = "untitled.md"; currentNote = name }
        var dir = notesDir || defaultNotesDir
        var filePath = dir + "/" + name
        var escDir = dir.replace(/'/g, "'\\''")
        var escContent = editorContent.replace(/'/g, "'\\''")
        var escPath = filePath.replace(/'/g, "'\\''")
        var cmd = "mkdir -p '" + escDir + "' && printf '%s' '" + escContent + "' > '" + escPath + "'"
        Quickshell.execDetached(["sh", "-c", cmd])
        currentNote = name
        oldEditorContent = editorContent
        hasUnsavedChanges = false
        showSaveIndicator = true
        var found = false
        for (var i = 0; i < notesModel.count; i++) {
            if (notesModel.get(i).name === name) { found = true; break }
        }
        if (!found) notesModel.append({ name: name })
        saveIndicatorTimer.restart()
        scanTimer.restart()
        saveSettings()
        Toaster.toast(qsTr("Note saved"), name, "save")
    }

    function deleteNote(name: string): void {
        if (!name || name.trim() === "") return
        var dir = notesDir || defaultNotesDir
        Quickshell.execDetached(["rm", "-f", dir + "/" + name.trim()])
        for (var i = 0; i < notesModel.count; i++) {
            if (notesModel.get(i).name === name.trim()) {
                notesModel.remove(i)
                break
            }
        }
        if (currentNote === name.trim()) {
            currentNote = ""; editorContent = ""; oldEditorContent = ""; hasUnsavedChanges = false
            saveSettings()
        }
        scanTimer.restart()
        Toaster.toast(qsTr("Note deleted"), name, "delete")
    }

    function loadNote(name: string): void {
        if (!name || name.trim() === "") return
        currentNote = name.trim()
        var dir = notesDir || defaultNotesDir
        loadProc.command = ["cat", dir + "/" + name.trim()]
        loadProc.running = true
    }

    function newNote(): void {
        currentNote = ""; editorContent = ""; oldEditorContent = ""; hasUnsavedChanges = false
        saveSettings()
        titleInput.forceActiveFocus()
    }

    function cyclePreview(): void { previewMode = previewMode === "off" ? "full" : "off" }

    function saveSettings(): void {
        var settings = {
            notesDir: notesDir !== "" && notesDir !== defaultNotesDir ? notesDir : "",
            currentNote: currentNote,
            currentContent: editorContent
        }
        var path = Paths.state + "/notepad/settings.json"
        var escSettings = JSON.stringify(settings).replace(/'/g, "'\\''")
        var escPath = path.replace(/'/g, "'\\''")
        var escState = Paths.state.replace(/'/g, "'\\''")
        Quickshell.execDetached(["sh", "-c", "mkdir -p '" + escState + "/notepad' && printf '%s' '" + escSettings + "' > '" + escPath + "'"])
    }

    // ── UI ──

    Rectangle {
        anchors.fill: parent
        color: Colours.tPalette.m3surface
        radius: Tokens.rounding.large

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            RowLayout {
                spacing: Tokens.spacing.small

                Button {
                    id: newBtn
                    flat: true
                    contentItem: RowLayout {
                        spacing: Tokens.spacing.small
                        MaterialIcon { text: "add"; color: Colours.palette.m3onPrimary }
                        StyledText { text: "New"; color: Colours.palette.m3onPrimary; font: Tokens.font.label.small }
                    }
                    background: Rectangle { color: newBtn.hovered ? Colours.layer(Colours.palette.m3primary, 2) : Colours.palette.m3primary; radius: Tokens.rounding.full }
                    onClicked: newNote()
                }
                Button {
                    id: saveBtn
                    flat: true
                    contentItem: RowLayout {
                        spacing: Tokens.spacing.small
                        MaterialIcon { text: "save"; color: Colours.palette.m3onPrimary }
                        StyledText { text: "Save"; color: Colours.palette.m3onPrimary; font: Tokens.font.label.small }
                    }
                    background: Rectangle { color: saveBtn.hovered ? Colours.layer(Colours.palette.m3primary, 2) : Colours.palette.m3primary; radius: Tokens.rounding.full }
                    enabled: currentNote.trim() !== ""
                    onClicked: saveNote()
                }
                Button {
                    id: previewBtn
                    flat: true
                    contentItem: RowLayout {
                        spacing: Tokens.spacing.small
                        MaterialIcon { text: "visibility"; color: Colours.palette.m3onPrimaryContainer }
                        StyledText { text: previewMode === "off" ? "Preview" : "Full"; color: Colours.palette.m3onPrimaryContainer; font: Tokens.font.label.small }
                    }
                    background: Rectangle { color: previewBtn.hovered ? Colours.layer(Colours.palette.m3primaryContainer, 2) : Colours.palette.m3primaryContainer; radius: Tokens.rounding.full }
                    onClicked: cyclePreview()
                }
                Item { Layout.fillWidth: true }
                StyledText { text: currentNote || "No note open"; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.body.small; elide: Text.ElideRight; Layout.maximumWidth: 200 }
                StyledText { text: "Saved"; color: Colours.palette.m3primary; font: Tokens.font.label.small; opacity: root.showSaveIndicator ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 200 } } }
            }

            TextField {
                id: titleInput
                Layout.fillWidth: true
                placeholderText: "filename.md"
                text: root.currentNote
                font: Tokens.font.body.medium
                color: Colours.palette.m3onSurface
                placeholderTextColor: Colours.palette.m3outline
                background: Rectangle { radius: Tokens.rounding.medium; color: Colours.tPalette.m3surfaceContainer; border.color: titleInput.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline; border.width: 1 }
                onTextChanged: { root.currentNote = text; root.hasUnsavedChanges = true }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 200
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.medium
                border.color: Colours.palette.m3outline
                border.width: 1

                TextArea {
                    id: editorArea
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    text: root.editorContent
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.mono.small
                    selectByMouse: true
                    background: null
                    wrapMode: TextEdit.WordWrap
                    visible: previewMode === "off"
                    onTextChanged: { root.editorContent = text; root.hasUnsavedChanges = text !== root.oldEditorContent }
                }
                TextEdit {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    textFormat: TextEdit.MarkdownText
                    readOnly: true; selectByMouse: true
                    color: Colours.palette.m3onSurface
                    text: root.editorContent
                    visible: previewMode !== "off"
                    onLinkActivated: function(link) { Qt.openUrlExternally(link) }
                }
            }

            // ── NOTES LIST ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                visible: notesModel.count > 0
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.medium
                border.color: Colours.palette.m3outline
                border.width: 1
                clip: true

                StyledText {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: Tokens.padding.medium
                    text: "Notes (" + notesModel.count + ")"
                    font: Tokens.font.title.small
                    color: Colours.palette.m3onSurface
                }

                ListView {
                    id: notesListView
                    anchors.topMargin: Tokens.padding.large * 2
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    clip: true
                    model: notesModel
                    spacing: 1

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 32
                        radius: Tokens.rounding.small
                        color: mouseArea.containsMouse ? Qt.alpha(Colours.palette.m3primary, 0.12) : "transparent"
                        required property string name
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.loadNote(name)
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Tokens.padding.small
                            text: name
                            color: name === currentNote ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            font.weight: name === currentNote ? Font.Bold : Font.Normal
                            elide: Text.ElideRight
                        }
                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: Tokens.padding.small
                            text: "delete"
                            color: Colours.palette.m3error

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.deleteNote(name)
                            }
                        }
                    }
                }
            }
        }
    }
}
