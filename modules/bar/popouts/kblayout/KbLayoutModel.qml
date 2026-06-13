// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260610


pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import CNS.Config
import qs.services

Item {
    id: model

    property alias visibleModel: visibleModel
    property string activeLabel: ""
    property int activeIndex: -1
    property var _xkbMap: ({})
    property bool _notifiedLimit: false

    function start() {
        xkbXmlBase.running = true;
        readLayouts();
    }

    function refresh() {
        _notifiedLimit = false;
        readLayouts();
    }

    function cycleLayout() {
        Niri.action("switch-layout", []);
    }

    function readLayouts() {
        const arr = Niri.kbLayoutsArray;
        if (arr && arr.length > 0)
            _setLayoutsFromArray(arr);

        activeIndex = Niri.kbLayoutIndex;
        if (activeIndex >= 0 && activeIndex < layoutsModel.count)
            activeLabel = layoutsModel.get(activeIndex).label;
        else
            activeLabel = "";

        _rebuildVisible();
    }

    function _buildXmlMap(xml) {
        const map = {};

        const re = /<name>\s*([^<]+?)\s*<\/name>[\s\S]*?<description>\s*([^<]+?)\s*<\/description>/g;

        let m;
        while ((m = re.exec(xml)) !== null) {
            const code = (m[1] || "").trim();
            const desc = (m[2] || "").trim();
            if (!code || !desc)
                continue;
            map[code] = _short(desc);
        }

        if (Object.keys(map).length === 0)
            return;

        _xkbMap = map;

        if (layoutsModel.count > 0) {
            const tmp = [];
            for (let i = 0; i < layoutsModel.count; i++) {
                const it = layoutsModel.get(i);
                tmp.push({
                    layoutIndex: it.layoutIndex,
                    token: it.token,
                    label: _pretty(it.token)
                });
            }
            layoutsModel.clear();
            tmp.forEach(t => layoutsModel.append(t));
        }
    }

    function _short(desc) {
        const m = desc.match(/^(.*)\((.*)\)$/);
        if (!m)
            return desc;
        const lang = m[1].trim();
        const region = m[2].trim();
        const code = (region.split(/[,\s-]/)[0] || region).slice(0, 2).toUpperCase();
        return `${lang} (${code})`;
    }

    function _setLayoutsFromArray(arr) {
        layoutsModel.clear();

        const seen = new Set();
        let idx = 0;

        for (let i = 0; i < arr.length; i++) {
            const token = arr[i].toString().trim();
            if (!token || seen.has(token))
                continue;
            seen.add(token);
            layoutsModel.append({
                layoutIndex: idx,
                token: token,
                label: _pretty(token)
            });
            idx++;
        }
    }

    function _rebuildVisible() {
        visibleModel.clear();

        let arr = [];
        for (let i = 0; i < layoutsModel.count; i++)
            arr.push(layoutsModel.get(i));

        arr = arr.filter(i => i.layoutIndex !== activeIndex);
        arr.forEach(i => visibleModel.append(i));

        if (!Config.utilities.toasts.kbLimit)
            return;

        if (layoutsModel.count > 4) {
            Toaster.toast(qsTr("Keyboard layout limit"), qsTr("XKB supports only 4 layouts at a time"), "warning");
        }
    }

    function _pretty(token) {
        const code = token.replace(/\(.*\)$/, "").trim();
        if (_xkbMap[code])
            return code.toUpperCase() + " - " + _xkbMap[code];
        return code.toUpperCase() + " - " + code;
    }

    visible: false

    ListModel {
        id: visibleModel
    }

    ListModel {
        id: layoutsModel
    }

    Process {
        id: xkbXmlBase

        command: ["xmllint", "--xpath", "//layout/configItem[name and description]", "/usr/share/X11/xkb/rules/base.xml"]
        stdout: StdioCollector {
            onStreamFinished: model._buildXmlMap(text)
        }
        onRunningChanged: if (!running && (typeof xkbXmlBase.exitCode !== "undefined") && xkbXmlBase.exitCode !== 0) // qmllint disable missing-property
            xkbXmlEvdev.running = true
    }

    Process {
        id: xkbXmlEvdev

        command: ["xmllint", "--xpath", "//layout/configItem[name and description]", "/usr/share/X11/xkb/rules/evdev.xml"]
        stdout: StdioCollector {
            onStreamFinished: model._buildXmlMap(text)
        }
    }

    Connections {
        target: Niri

        function onKbLayoutIndexChanged() {
            activeIndex = Niri.kbLayoutIndex;
            if (activeIndex >= 0 && activeIndex < layoutsModel.count)
                activeLabel = layoutsModel.get(activeIndex).label;
            else
                activeLabel = "";
            _rebuildVisible();
        }
    }
}
