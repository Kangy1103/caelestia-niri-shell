pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

// Persists the set of favourited local wallpapers (by their name relative to
// the wallpaper folder, e.g. "Anime Chicks/sunset.jpg") in its own small file
// so it never pollutes settings.json. Mirrors the FileView/JsonAdapter pattern
// used elsewhere in CNS.
//
// CNS: keyed by relativePath rather than the source's bare fileName, matching
// what Wallpapers.list exposes and what PaletteCache keys its cache on, so all
// three agree on one identifier per wallpaper.
Scope {
    id: root

    // Reactive list of favourited wallpaper names.
    property alias favorites: favAdapter.favorites

    function has(name) {
        const f = favAdapter.favorites;
        for (let i = 0; i < f.length; i++)
            if (f[i] === name)
                return true;
        return false;
    }

    function toggle(name) {
        if (!name)
            return;
        let next = [];
        let removed = false;
        const cur = favAdapter.favorites;
        for (let i = 0; i < cur.length; i++) {
            if (cur[i] === name) {
                removed = true;
                continue;
            }
            next.push(cur[i]);
        }
        if (!removed)
            next.push(name);
        favAdapter.favorites = next;
    }

    Timer {
        id: writeTimer

        interval: 100
        repeat: false
        onTriggered: favFile.writeAdapter();
    }

    Timer {
        id: reloadTimer

        interval: 100
        repeat: false
        onTriggered: favFile.reload();
    }

    FileView {
        id: favFile

        path: `${Paths.cache}/wallpaper-favourites.json`
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeTimer.restart();
        }

        adapter: JsonAdapter {
            id: favAdapter

            property list<string> favorites: [];
        }
    }
}