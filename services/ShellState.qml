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
        // CNS: ShellScreen copies become dangling during output removal and
        // return default property values. Never match their empty name against
        // another dangling modelData (or dereference a null screen during the
        // Variants teardown window).
        if (!screen || !screen.name)
            return null;
        const name = screen.name;
        for (const s of states.instances)
            if (s.modelData && s.modelData.name && (s.modelData === screen || s.modelData.name === name))
                return s;
        console.warn(`[ShellState] forScreen null for "${name}" | instances=[${states.instances.map(s => s.modelData?.name || "<?>").join(",")}]`);
        return null;
    }

    function forActive(): ScreenState {
        const name = Niri.focusedMonitorName;
        if (!name)
            return null;
        for (const s of states.instances)
            if (s.modelData && s.modelData.name && s.modelData.name === name)
                return s;
        console.warn(`[ShellState] forActive null: focusedMonitorName="${name}" | instances=[${states.instances.map(s => s.modelData ? s.modelData.name : "<?>").join(",")}]`);
        return null;
    }

    function componentsFor(screen: ShellScreen): Components {
        if (!screen || !screen.name)
            return null;
        const name = screen.name;
        for (const c of components.instances)
            if (c.modelData && c.modelData.name && (c.modelData === screen || c.modelData.name === name))
                return c;
        return null;
    }

    function componentsForActive(): Components {
        const name = Niri.focusedMonitorName;
        if (!name)
            return null;
        for (const c of components.instances)
            if (c.modelData && c.modelData.name && c.modelData.name === name)
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
