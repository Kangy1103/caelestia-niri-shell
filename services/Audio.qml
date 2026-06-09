pragma Singleton

import Caelestia.Config
import qs.services
import Caelestia
import Caelestia.Services
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
    readonly property list<PwNode> streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio)

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    // readonly property alias cava: cava (disabled)
    // readonly property alias beatTracker: beatTracker (disabled)

    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(Config.services.maxVolume, newVolume));
        }
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || Config.services.audioIncrement));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || Config.services.audioIncrement));
    }

    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(Config.services.maxVolume, newVolume));
        }
    }

    function incrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume + (amount || Config.services.audioIncrement));
    }

    function decrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume - (amount || Config.services.audioIncrement));
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
            stream.audio.volume = Math.max(0, Math.min(Config.services.maxVolume, newVolume));
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

        if (previousSinkName && previousSinkName !== newSinkName && Config.utilities.toasts.audioOutputChanged)
            Toaster.toast(qsTr("Audio output changed"), qsTr("Now using: %1").arg(newSinkName), "volume_up");

        previousSinkName = newSinkName;
    }

    onSourceChanged: {
        if (!source?.ready)
            return;

        const newSourceName = source.description || source.name || qsTr("Unknown Device");

        if (previousSourceName && previousSourceName !== newSourceName && Config.utilities.toasts.audioInputChanged)
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

    // CavaProvider and BeatTracker from Caelestia.Services are disabled:
    // - CavaProvider: crashes in libcava/fftw3 during PipeWire init
    // - BeatTracker: "Element is not creatable" under Qt 6.11
    //   (smpl_t typedef + abstract Service base + optional plugin qmldir)
    //   Works upstream with older Qt. Re-enable after Qt upgrade.
    //   Fixes applied: QML_ELEMENT on Service+AudioProvider, smpl_t→float,
    //   qmldir plugin (not optional), prefer line removed.
    // CavaProvider {
    //     id: cava
    //     bars: Config.services.visualiserBars
    // }
    // BeatTracker {
    //     id: beatTracker
    // }

    IpcHandler {
        function cycleOutput(): void {
            root.cycleNextAudioOutput();
        }

        target: "audio"
    }
}
