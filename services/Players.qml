pragma Singleton

import QtQml
import Caelestia.Config
import qs.services
import Caelestia
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values
    readonly property MprisPlayer active: props.manualActive ?? list.find(p => getIdentity(p) === Config.services.defaultPlayer) ?? list[0] ?? null
    property alias manualActive: props.manualActive

    function getIdentity(player: MprisPlayer): string {
        if (!player)
            return "";
        const alias = Config.services.playerAliases.find(a => a.from === player.identity);
        return alias?.to ?? player.identity;
    }

    function getArtUrl(player: MprisPlayer): string {
        if (!player)
            return "";

        const url = player.metadata["xesam:url"] ?? "";
        if (url.startsWith("https://www.youtube.com/watch")) {
            const id = url.match(/[?&]v=([\w-]{11})/)?.[1];
            if (id)
                return `https://img.youtube.com/vi/${id}/maxresdefault.jpg`;
        }

        return player.trackArtUrl;
    }

    Connections {
        target: root.active

        function onPostTrackChanged() {
            if (!Config.utilities.toasts.nowPlaying)
                return;
            if (root.active.trackArtist != "" && root.active.trackTitle != "")
                Toaster.toast(qsTr("Now Playing"), qsTr("%1 - %2").arg(root.active.trackArtist).arg(root.active.trackTitle), "music_note");
        }
    }

    PersistentProperties {
        id: props

        property MprisPlayer manualActive

        reloadableId: "players"
    }

    IpcHandler {
        target: "mpris"

        function getActive(prop: string): string {
            const active = root.active;
            return active ? active[prop] ?? "Invalid property" : "No active player";
        }

        function list(): string {
            return root.list.map(p => root.getIdentity(p)).join("\n");
        }

        function play(): void {
            const active = root.active;
            if (active?.canPlay)
                active.play();
        }

        function pause(): void {
            const active = root.active;
            if (active?.canPause)
                active.pause();
        }

        function playPause(): void {
            const active = root.active;
            if (active?.canTogglePlaying)
                active.togglePlaying();
        }

        function previous(): void {
            const active = root.active;
            if (active?.canGoPrevious)
                active.previous();
        }

        function next(): void {
            const active = root.active;
            if (active?.canGoNext)
                active.next();
        }

        function stop(): void {
            root.active?.stop();
        }
    }
}
