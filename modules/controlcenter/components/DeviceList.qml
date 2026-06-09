pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import Caelestia.Config
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property Session session: null
    property var model: null
    property Component delegate: null

    property string title: ""
    property string description: ""
    property var activeItem: null
    property Component headerComponent: null
    property Component titleSuffix: null
    property bool showHeader: true

    signal itemSelected(var item)

    spacing: Config.appearance.spacing.small

    Loader {
        id: headerLoader

        Layout.fillWidth: true
        sourceComponent: root.headerComponent
        visible: root.headerComponent !== null && root.showHeader
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: root.headerComponent ? 0 : 0
        spacing: Config.appearance.spacing.small
        visible: root.title !== "" || root.description !== ""

        StyledText {
            visible: root.title !== ""
            text: root.title
            font.pointSize: Config.appearance.font.title.medium.size
            font.weight: 500
        }

        Loader {
            sourceComponent: root.titleSuffix
            visible: root.titleSuffix !== null
        }

        Item {
            Layout.fillWidth: true
        }
    }

    property alias view: view

    StyledText {
        visible: root.description !== ""
        Layout.fillWidth: true
        text: root.description
        color: Colours.palette.m3outline
    }

    StyledListView {
        id: view

        Layout.fillWidth: true
        implicitHeight: contentHeight

        model: root.model
        delegate: root.delegate

        spacing: Config.appearance.spacing.small / 2
        interactive: false
        clip: false
    }
}
