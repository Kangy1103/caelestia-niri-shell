import QtQuick
import QtQuick.Effects
import qs.components
import qs.services
import CNS.Config

Item {
    id: root

    property string imageSource: ""
    property string fallbackIcon: "person"

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Colours.layer(Colours.palette.m3primaryContainer, 2)
    }

    Image {
        id: profileImg
        anchors.fill: parent
        anchors.margins: 2
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: root.imageSource
        visible: false

        function loadPath(path) {
            if (path.startsWith("/"))
                source = "file://" + path;
            else
                source = path;
        }
    }

    MultiEffect {
        anchors.fill: parent
        anchors.margins: 2
        source: profileImg
        maskEnabled: true
        maskSource: maskItem
        visible: profileImg.status === Image.Ready && root.imageSource !== ""
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Item {
        id: maskItem
        anchors.centerIn: parent
        width: parent.width - 4
        height: parent.height - 4
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "black"
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        text: root.fallbackIcon
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.size(Math.round(parent.width * 0.6)).build()
        visible: profileImg.status !== Image.Ready || root.imageSource === ""
    }
}
