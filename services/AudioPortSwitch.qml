// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.4.0-20260612

pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property string speakersMatch: "Main Audio"
    readonly property string scarlettMatch: "Scarlett Solo 4th Gen"

    property PwNode speakersSink: null
    property PwNode scarlettSink: null
    property bool ready: false

    function _findSinks(): void {
        const sinks = Pipewire.nodes.values.filter(n => !n.isStream && n.isSink);
        root.speakersSink = sinks.find(n => (n.description || "").indexOf(root.speakersMatch) >= 0) || null;
        root.scarlettSink = sinks.find(n => (n.description || "").indexOf(root.scarlettMatch) >= 0) || null;
        root.ready = root.speakersSink !== null && root.scarlettSink !== null;
    }

    function _currentIsSpeakers(): bool {
        const def = Pipewire.defaultAudioSink;
        if (!def) return false;
        return (def.description || "").indexOf(root.speakersMatch) >= 0;
    }

    function toggle(): void {
        _findSinks();
        if (!root.ready) return;
        const target = _currentIsSpeakers() ? root.scarlettSink : root.speakersSink;
        _switchTo(target);
    }

    function speakers(): void {
        _findSinks();
        if (!root.speakersSink) return;
        _switchTo(root.speakersSink);
    }

    function scarlett(): void {
        _findSinks();
        if (!root.scarlettSink) return;
        _switchTo(root.scarlettSink);
    }

    function _switchTo(sink: PwNode): void {
        Pipewire.preferredDefaultAudioSink = sink;
    }

    Component.onCompleted: {
        _findSinks();
    }

    IpcHandler {
        target: "audioPort"

        function toggle(): void {
            root.toggle();
        }

        function speakers(): void {
            root.speakers();
        }

        function scarlett(): void {
            root.scarlett();
        }
    }
}
