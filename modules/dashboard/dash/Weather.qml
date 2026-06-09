import qs.components
import qs.services
import Caelestia.Config
import qs.utils
import QtQuick

Item {
    id: root

    anchors.centerIn: parent

    implicitWidth: content.implicitWidth + Config.appearance.padding.large * 2
    implicitHeight: content.implicitHeight + Config.appearance.padding.medium * 2

    Component.onCompleted: Weather.reload()

    // Today's high/low from forecast
    readonly property var today: Weather.forecast && Weather.forecast.length > 0 ? Weather.forecast[0] : null
    readonly property string highLow: {
        if (!today) return "";
        if (Config.services.useFahrenheit)
            return "↑" + today.maxTempF + "°  ↓" + today.minTempF + "°";
        return "↑" + today.maxTempC + "°  ↓" + today.minTempC + "°";
    }


    Row {
        id: content
        anchors.centerIn: parent
        spacing: Config.appearance.spacing.extraExtraLarge

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Config.appearance.spacing.extraSmall

            MaterialIcon {
                id: icon
                anchors.horizontalCenter: parent.horizontalCenter

                animate: true
                text: Weather.error ? "cloud_alert" : Weather.icon
                color: Weather.error ? Colours.palette.m3error : Colours.palette.m3secondary
                font.pointSize: Config.appearance.font.headline.large.size * 2
            }

            // Description below icon
            // StyledText {
            //     anchors.horizontalCenter: parent.horizontalCenter
            //     visible: !Weather.error
            //     animate: true
            //     text: Weather.description
            //     font.pointSize: Config.appearance.font.label.medium.size
            //     color: Colours.palette.m3onSurfaceVariant
            // }
        }

        Column {
            id: info

            anchors.verticalCenter: parent.verticalCenter
            spacing: Config.appearance.spacing.extraSmall

            // Temperature
            StyledText {
                animate: true
                text: Weather.error ? Weather.error : Weather.temp
                color: Weather.error ? Colours.palette.m3error : Colours.palette.m3primary
                font.pointSize: Weather.error ? Config.appearance.font.body.medium.size : Config.appearance.font.headline.large.size
                font.weight: 600
            }

            // High / Low temps
            StyledText {
                visible: !Weather.error && root.highLow !== ""
                animate: true
                text: root.highLow
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.label.large.size
                font.weight: 500
                opacity: 0.85
            }


            // City
            StyledText {
                visible: !Weather.error && Weather.city !== ""
                animate: true
                text: "  " + Weather.city
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.label.small.size
                font.weight: 400
                opacity: 0.7
                elide: Text.ElideRight
                width: Math.min(implicitWidth, root.parent ? root.parent.width - icon.implicitWidth - content.spacing - Config.appearance.padding.largeIncreased * 2 : implicitWidth)
            }
        }
    }
}
