pragma Singleton

import CNS.Config
import qs.services
import CNS
import CNS.Services
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    property string previousSinkName: ""
    property string previousSourceName: ""

    readonly property list<PwNode> sinks: Pipewire.nodes.values.filter(n => !n.isStream && n.isSink)
    readonly property list<PwNode> sources: Pipewire.nodes.values.filter(n => !n.isStream && n.audio && !n.isSink)
    readonly property list<PwNode> streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio && n.name !== "caelestia-niri-shell")

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    readonly property alias beatTracker: beatTracker

    // Role-based stream grouping
    function getStreamsByRole(role: string): list<PwNode> {
        return root.streams.filter(s => s.properties["media.role"] === role);
    }

    readonly property var streamRoles: {
        const roles = [];
        const seen = new Set();
        for (const s of root.streams) {
            const role = s.properties["media.role"];
            if (role && !seen.has(role)) {
                seen.add(role);
                roles.push(role);
            }
        }
        return roles;
    }

    function setRoleVolume(role: string, volume: real): void {
        const nodes = root.getStreamsByRole(role);
        for (const s of nodes) {
            if (s?.ready && s?.audio) {
                s.audio.muted = false;
                s.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, volume));
            }
        }
    }

    function setRoleMuted(role: string, muted: bool): void {
        const nodes = root.getStreamsByRole(role);
        for (const s of nodes) {
            if (s?.ready && s?.audio) {
                s.audio.muted = muted;
            }
        }
    }

    // Notification volume persistence (always shown even when idle)
    property real notificationVolume: 1.0
    property bool notificationMuted: false

    function setNotificationVolume(v: real): void {
        root.notificationVolume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, v));
        root.notificationMuted = false;
        root.setRoleVolume("Notification", root.notificationVolume);
    }

    function setNotificationMuted(m: bool): void {
        root.notificationMuted = m;
        root.setRoleMuted("Notification", m);
    }

    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setAudioSink(newSink: PwNode): void {
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    function setAudioSource(newSource: PwNode): void {
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    function cycleNextAudioOutput(): void {
        if (sinks.length === 0)
            return;

        const currentIndex = sinks.findIndex(s => s === sink);
        const nextIndex = (currentIndex + 1) % sinks.length;
        setAudioSink(sinks[nextIndex]);
    }

    function setStreamVolume(stream: PwNode, newVolume: real): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = false;
            stream.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function setStreamMuted(stream: PwNode, muted: bool): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = muted;
        }
    }

    function getStreamVolume(stream: PwNode): real {
        return stream?.audio?.volume ?? 0;
    }

    function getStreamMuted(stream: PwNode): bool {
        return !!stream?.audio?.muted;
    }

    function getStreamName(stream: PwNode): string {
        if (!stream)
            return qsTr("Unknown");
        return stream.properties["application.name"] || stream.description || stream.name || qsTr("Unknown Application");
    }

    onSinkChanged: {
        if (!sink?.ready)
            return;

        const newSinkName = sink.description || sink.name || qsTr("Unknown Device");

        if (previousSinkName && previousSinkName !== newSinkName && GlobalConfig.utilities.toasts.audioOutputChanged)
            Toaster.toast(qsTr("Audio output changed"), qsTr("Now using: %1").arg(newSinkName), "volume_up");

        previousSinkName = newSinkName;
    }

    onSourceChanged: {
        if (!source?.ready)
            return;

        const newSourceName = source.description || source.name || qsTr("Unknown Device");

        if (previousSourceName && previousSourceName !== newSourceName && GlobalConfig.utilities.toasts.audioInputChanged)
            Toaster.toast(qsTr("Audio input changed"), qsTr("Now using: %1").arg(newSourceName), "mic");

        previousSourceName = newSourceName;
    }

    Component.onCompleted: {
        previousSinkName = sink?.description || sink?.name || qsTr("Unknown Device");
        previousSourceName = source?.description || source?.name || qsTr("Unknown Device");
    }

    PwObjectTracker {
        objects: [...root.sinks, ...root.sources, ...root.streams]
    }

    BeatTracker {
        id: beatTracker
    }

    IpcHandler {
        function cycleOutput(): void {
            root.cycleNextAudioOutput();
        }

        target: "audio"
    }
}
