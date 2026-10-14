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

    function forScreen(screen: ShellScreen): ScreenState {
        for (const s of states.instances)
            if (s.modelData && (s.modelData === screen || s.modelData.name === screen.name))
                return s;
        if (screen)
            console.warn(`[ShellState] forScreen null for "${screen.name}" | instances=[${states.instances.map(s => s.modelData ? s.modelData.name : "<?>").join(",")}]`);
        return null;
    }

    function forActive(): ScreenState {
        const name = Niri.focusedMonitorName;
        for (const s of states.instances)
            if (s.modelData && s.modelData.name === name)
                return s;
        console.warn(`[ShellState] forActive null: focusedMonitorName="${name}" | instances=[${states.instances.map(s => s.modelData ? s.modelData.name : "<?>").join(",")}]`);
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
}
