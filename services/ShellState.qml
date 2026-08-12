pragma Singleton

import QtQuick
import Quickshell
import CNS
import qs.components
import qs.services

Singleton {
    property ShellRoot shellRoot

    function anySidebarOpen(): bool {
        return states.instances.some(s => s.sidebar);
    }

    property var customScreenStates: ({})
    property int regVersion: 0

    function register(screenName: string, state: ScreenState): void {
        if (!screenName || !state) return;
        const copy = {};
        for (const key in customScreenStates)
            copy[key] = customScreenStates[key];
        copy[screenName] = state;
        customScreenStates = copy;
        regVersion++;
    }

    function forScreen(screen: ShellScreen): ScreenState {
        if (screen && customScreenStates[screen.name])
            return customScreenStates[screen.name];
        for (const s of states.instances)
            if (s.modelData && (s.modelData === screen || s.modelData.name === screen.name))
                return s;
        return null;
    }

    function forActive(): ScreenState {
        const name = Niri.focusedMonitorName;
        if (name && customScreenStates[name])
            return customScreenStates[name];
        for (const s of states.instances)
            if (s.modelData && s.modelData.name === name)
                return s;
        return null;
    }

    function componentsFor(screen: ShellScreen): Components {
        for (const c of components.instances)
            if (c.modelData && (c.modelData === screen || c.modelData.name === screen.name))
                return c;
        return null;
    }

    function componentsForActive(): Components {
        const name = Niri.focusedMonitorName;
        for (const c of components.instances)
            if (c.modelData && c.modelData.name === name)
                return c;
        return null;
    }

    Variants {
        id: states

        model: Screens.screens

        ScreenState {}
    }

    Variants {
        id: components

        model: Screens.screens

        Components {}
    }

    component Components: QtObject {
        required property ShellScreen modelData

        property var background
        property var rootWindow
        property var interactionWrapper
        property var bar
        property var panels

        function find(name: string, rootItem: Item): var {
            return CUtils.findChild(rootItem ?? rootWindow?.contentItem, name);
        }

        function findAll(name: string, rootItem: Item): var {
            return CUtils.findChildren(rootItem ?? rootWindow?.contentItem, name);
        }

        function findMatching(pattern: string, rootItem: Item): var {
            return CUtils.findChildrenMatching(rootItem ?? rootWindow?.contentItem, pattern);
        }
    }

    component ComponentRef: QtObject {
        required property ShellScreen screen
        required property string slot
        required property var component

        readonly property QtObject target: ShellState.componentsFor(screen)

        onTargetChanged: {
            if (target)
                target[slot] = component;
        }
        Component.onDestruction: {
            if (target && target[slot] === component)
                target[slot] = null;
        }
    }
}
