// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260607

pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property QtObject spacing: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
    }

    readonly property QtObject padding: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
    }

    readonly property QtObject rounding: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
        readonly property int full: 10000
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject body: QtObject {
            readonly property font small: Qt.font({ pointSize: 12, weight: Font.Normal })
            readonly property font medium: Qt.font({ pointSize: 14, weight: Font.Normal })
            readonly property font large: Qt.font({ pointSize: 16, weight: Font.Normal })

            readonly property QtObject builders: QtObject {
                readonly property FontBuilder large: FontBuilder { _size: 16; _weight: Font.Normal }
                readonly property FontBuilder medium: FontBuilder { _size: 14; _weight: Font.Normal }
                readonly property FontBuilder small: FontBuilder { _size: 12; _weight: Font.Normal }
            }
        }

        readonly property QtObject icon: QtObject {
            readonly property font extraLarge: Qt.font({ pointSize: 36, weight: Font.Normal })
            readonly property font large: Qt.font({ pointSize: 24, weight: Font.Normal })

            readonly property QtObject builders: QtObject {
                readonly property FontBuilder extraLarge: FontBuilder { _size: 36; _weight: Font.Normal }
            }
        }
    }

    component FontBuilder: QtObject {
        property int _size: 14
        property int _weight: Font.Normal

        function size(s) { _size = s; return this; }
        function weight(w) { _weight = w; return this; }
        function scale(f) { _size = Math.round(_size * f); return this; }
        function build() { return Qt.font({ pointSize: _size, weight: _weight }); }
    }
}
