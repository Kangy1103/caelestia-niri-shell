// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260612

import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    property ShellScreen screen
    property bool isWindow
    property int currentPageIdx
    property list<int> subPageIdxStack
    property bool searchOpen
    property string searchText

    property string selectedWallpaperCategory
    property string selectedEthernetInterface
    property BluetoothDevice selectedBtDevice
    property int editingVpnIndex: -1
    property string selectedNetworkSsid
    property bool networkDetailsFromSaved

    signal close
    signal subPageOpened(idx: int)
    signal subPageClosed

    function openSubPage(idx: int): void {
        subPageIdxStack.push(idx);
        subPageOpened(idx);
    }

    function closeSubPage(): void {
        subPageClosed();
        subPageIdxStack.pop();
    }

    onCurrentPageIdxChanged: subPageIdxStack.length = 0
}
