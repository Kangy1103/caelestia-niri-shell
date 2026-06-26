import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.services
import CNS.Config

Item {
    id: root

    property string text: ""
    property string currentValue: ""
    property var options: []

    signal valueChanged(string value)

    implicitHeight: 40
    implicitWidth: 200

    function closeDropdownMenu() {
        dropdownMenu.close();
    }

    function selectNext() {
        if (filteredOptions.length === 0) return;
        selectedIndex = (selectedIndex + 1) % filteredOptions.length;
        listView.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function selectPrevious() {
        if (filteredOptions.length === 0) return;
        selectedIndex = selectedIndex <= 0 ? filteredOptions.length - 1 : selectedIndex - 1;
        listView.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function selectCurrent() {
        if (selectedIndex < 0 || selectedIndex >= filteredOptions.length) return;
        root.currentValue = filteredOptions[selectedIndex];
        root.valueChanged(filteredOptions[selectedIndex]);
        close();
    }

    readonly property var filteredOptions: root.options

    property int selectedIndex: -1
    property int maxPopupHeight: 400
    property bool openUpwards: false
    property int popupWidth: 0

    Rectangle {
        id: dropdown
        width: parent.width
        height: 40
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        radius: Tokens.rounding.medium
        color: dropdownArea.containsMouse || dropdownMenu.visible
            ? Colours.tPalette.m3surfaceContainerHigh
            : Colours.tPalette.m3surfaceContainer
        border.color: dropdownMenu.visible
            ? Colours.palette.m3primary
            : Qt.alpha(Colours.palette.m3outline, 0.2)
        border.width: dropdownMenu.visible ? 2 : 1

        MouseArea {
            id: dropdownArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (dropdownMenu.visible) {
                    dropdownMenu.close();
                    return;
                }
                dropdownMenu.open();
                var idx = root.options.indexOf(root.currentValue);
                listView.positionViewAtIndex(idx, ListView.Beginning);

                var pos = dropdown.mapToItem(Overlay.overlay, 0, 0);
                var popupH = dropdownMenu.height;
                var overlayH = Overlay.overlay.height;
                var goUp = root.openUpwards || pos.y + dropdown.height + popupH + 4 > overlayH;
                dropdownMenu.x = pos.x;
                dropdownMenu.y = goUp ? pos.y - popupH - 4 : pos.y + dropdown.height + 4;
            }
        }

        StyledText {
            anchors.left: parent.left
            anchors.right: expandIcon.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spacing.medium
            anchors.rightMargin: Tokens.spacing.small
            text: root.currentValue
            font: Tokens.font.body.medium
            color: Colours.palette.m3onSurface
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }

        MaterialIcon {
            id: expandIcon
            text: dropdownMenu.visible ? "expand_less" : "expand_more"
            color: Colours.palette.m3onSurface
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Tokens.spacing.small
            fontStyle: Tokens.font.icon.medium
        }
    }

    Popup {
        id: dropdownMenu
        property int selectedIndex: -1

        parent: Overlay.overlay
        width: root.popupWidth > 0 ? root.popupWidth : dropdown.width
        height: Math.min(root.maxPopupHeight, Math.min(filteredOptions.length, 8) * 36 + 8)
        padding: 0
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Colours.tPalette.m3surfaceContainer
            border.color: Colours.palette.m3primary
            border.width: 2
            radius: Tokens.rounding.medium
        }

        contentItem: ListView {
            id: listView
            clip: true
            model: root.filteredOptions
            spacing: 2
            interactive: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property var modelData
                required property int index

                readonly property bool isCurrentValue: root.currentValue === modelData

                width: ListView.view.width
                height: 32
                radius: Tokens.rounding.small
                color: optionArea.containsMouse
                    ? Colours.layer(Colours.palette.m3primaryContainer, 1)
                    : "transparent"

                StyledText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.spacing.small
                    anchors.rightMargin: Tokens.spacing.small
                    text: modelData
                    font: isCurrentValue
                        ? Tokens.font.body.builders.medium.weight(Font.Medium).build()
                        : Tokens.font.body.medium
                    color: isCurrentValue ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: optionArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentValue = modelData;
                        root.valueChanged(modelData);
                        root.closeDropdownMenu();
                    }
                }
            }
        }
    }
}
