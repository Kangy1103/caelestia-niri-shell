pragma ComponentBehavior: Bound

import QtQuick
import CNS.Config
import qs.components
import qs.services

Item {
    id: root

    function calcTopOff(metrics: TextMetrics): real {
        return metrics.tightBoundingRect.y - metrics.boundingRect.y;
    }

    readonly property font baseFont: Tokens.font.headline.builders.large.scale(1).width(30).build()

    readonly property real scale_24h: 5
    readonly property real scale_12h: 2.7

    TextMetrics {
        id: baseHourMetrics

        text: Time.hourStr
        font: root.baseFont
    }

    TextMetrics {
        id: baseMinuteMetrics

        text: Time.minuteStr
        font: root.baseFont
    }

    readonly property real maxScale: 5
    readonly property real baseTotalWidth: baseHourMetrics.width + baseMinuteMetrics.width + Tokens.spacing.small
    readonly property real fitScale: root.width > 0 && baseTotalWidth > 0
        ? Math.min(maxScale, root.width / baseTotalWidth)
        : maxScale

    implicitWidth: clockGroup.implicitWidth
    implicitHeight: hourMetrics.tightBoundingRect.height

    Item {
        id: clockGroup
        anchors.centerIn: parent
        implicitWidth: hours.implicitWidth + minutes.implicitWidth + Tokens.spacing.small
        implicitHeight: hourMetrics.tightBoundingRect.height

        StyledText {
            id: hours

            y: -root.calcTopOff(hourMetrics)
            text: Time.hourStr
            color: Colours.palette.m3primary
            font: Tokens.font.headline.builders.large.scale(root.fitScale).width(30).build()

            TextMetrics {
                id: hourMetrics

                text: hours.text
                font: hours.font
            }
        }

        StyledText {
            id: minutes

            anchors.right: parent.right
            y: -root.calcTopOff(minuteMetrics)

            text: Time.minuteStr
            color: Colours.palette.m3secondary
            font: Tokens.font.headline.builders.large.scale(
                GlobalConfig.services.useTwelveHourClock
                    ? root.fitScale * (root.scale_12h / root.scale_24h)
                    : root.fitScale
            ).width(30).build()

            TextMetrics {
                id: minuteMetrics

                text: minutes.text
                font: minutes.font
            }
        }

        Loader {
            anchors.left: minutes.left
            anchors.leftMargin: minuteMetrics.tightBoundingRect.x
            y: hourMetrics.tightBoundingRect.height - implicitHeight

            active: GlobalConfig.services.useTwelveHourClock
            asynchronous: true

            sourceComponent: StyledRect {
                color: Colours.tPalette.m3surfaceContainerHigh
                radius: Tokens.rounding.large

                implicitWidth: minuteMetrics.tightBoundingRect.width
                implicitHeight: amPmMetrics.tightBoundingRect.height + Tokens.padding.large * 2

                StyledText {
                    id: amPm

                    anchors.centerIn: parent
                    width: amPmMetrics.tightBoundingRect.width
                    height: amPmMetrics.tightBoundingRect.height
                    transform: Translate {
                        x: -amPmMetrics.tightBoundingRect.x
                        y: -root.calcTopOff(amPmMetrics)
                    }

                    text: Time.amPmStr
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.headline.builders.small.scale(
                        root.fitScale * 2 / root.scale_24h
                    ).width(30).build()

                    TextMetrics {
                        id: amPmMetrics

                        text: amPm.text
                        font: amPm.font
                    }
                }
            }
        }
    }
}
