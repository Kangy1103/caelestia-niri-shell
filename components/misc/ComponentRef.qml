import QtQuick
import Quickshell
import qs.services

// Extracted from ShellState.qml's inline component.
//
// This was an INLINE component declared inside a QML singleton
// (ShellState.qml) and referenced across files as `ShellState.ComponentRef`.
// Cross-file inline-component references make the Qt type loader build a
// QQmlTypeData for ShellState.qml that is still mid-compile when
// qqmltypedata.cpp:1169 dereferences its (null) compilationUnit.
// Promoting it to a real singleton type removes that inline-component edge.
QtObject {
    id: root

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