import Quickshell.Io

JsonObject {
    property bool enabled: true
    property bool showOnHover: true
    property bool useWallpaperAvatar: true
    property int mediaUpdateInterval: 500
    property int resourceUpdateInterval: 5000
    property int dragThreshold: 50
    property int updateInterval: 1000
    property Sizes sizes: Sizes {}
    property Performance performance: Performance {}
    property CalendarColors calendarColors: CalendarColors {}

    component Performance: JsonObject {
        property bool showBattery: true
        property bool showGpu: true
        property bool showCpu: true
        property bool showMemory: true
        property bool showStorage: true
        property bool showNetwork: true
    }

    component Sizes: JsonObject {
        readonly property int tabIndicatorHeight: 3
        readonly property int tabIndicatorSpacing: 5
        readonly property int infoWidth: 200
        readonly property int infoIconSize: 25
        readonly property int dateTimeWidth: 110
        readonly property int mediaWidth: 200
        readonly property int mediaProgressSweep: 180
        readonly property int mediaProgressThickness: 8
        readonly property int resourceProgessThickness: 10
        readonly property int weatherWidth: 250
        readonly property int mediaCoverArtSize: 150
        readonly property int mediaIconSize: 20
        readonly property int mediaVisualiserSize: 80
        readonly property int resourceSize: 200
    }

    component CalendarColors: JsonObject {
        property string blue: "#4285F4"
        property string red: "#EA4335"
        property string yellow: "#FBBC04"
        property string green: "#34A853"
        property string purple: "#9C27B0"
        property string teal: "#009688"
        property string pink: "#E91E63"
        property string orange: "#FF9800"
        property string brown: "#795548"
    }
}
