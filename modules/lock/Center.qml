// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260610

import "center"
import QtQuick
import QtQuick.Layouts
import CNS.Config
import qs.components
import qs.services

ColumnLayout {
  id: root

    required property var lock
    readonly property int centerWidth: Tokens.sizes.lock.centerWidth

    Layout.fillWidth: false
    Layout.preferredWidth: centerWidth
    Layout.fillHeight: true

    clip: true
    spacing: Tokens.spacing.largeIncreased

    Clock {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.topMargin: Tokens.padding.large
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter

        text: Time.format("dddd • d MMM yyyy").toUpperCase()
        color: Colours.palette.m3onSurface
        font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()
    }

    ProfilePic {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.topMargin: Tokens.spacing.extraExtraLarge
        Layout.bottomMargin: Tokens.spacing.extraLarge
        centerWidth: root.centerWidth
    }

    PasswordInput {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        centerWidth: root.centerWidth
        lock: root.lock
    }

  StateMessage {
    Layout.fillWidth: true
    pam: root.lock.pam
  }
}
