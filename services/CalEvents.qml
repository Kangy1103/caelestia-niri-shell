pragma Singleton
pragma ComponentBehavior: Bound

import CNS.Config
import qs.utils
import CNS
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property list<CalEvent> list: []

    signal eventsChanged()

    function _dateKey(date): string {
        const d = new Date(date);
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    }

    function _isSameDay(a, b): bool {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function eventsForDate(date) {
        return root.list.filter(e => root._isSameDay(e.startDate, date));
    }

    function upcoming(count) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        return root.list
            .filter(e => e.startDate >= today)
            .sort((a, b) => a.startDate.getTime() - b.startDate.getTime())
            .slice(0, count);
    }

    function addEvent(data): void {
        const id = Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
        const event = eventComp.createObject(root, {
            id: id,
            title: data.title || "",
            startDate: data.startDate || new Date(),
            startTime: data.startTime || "",
            endTime: data.endTime || "",
            allDay: data.allDay || false,
            color: data.color || GlobalConfig.dashboard.calendarColors.blue,
            source: "local",
        });
        root.list.push(event);
        root._onListChanged();
        root._saveToFile();
    }

    function removeEvent(id): void {
        const idx = root.list.findIndex(e => e.id === id);
        if (idx !== -1) {
            root.list.splice(idx, 1);
            root._onListChanged();
            root._saveToFile();
        }
    }

    function editEvent(id, data): void {
        const event = root.list.find(e => e.id === id);
        if (!event) return;
        if (data.title !== undefined) event.title = data.title;
        if (data.startDate !== undefined) event.startDate = data.startDate;
        if (data.startTime !== undefined) event.startTime = data.startTime;
        if (data.endTime !== undefined) event.endTime = data.endTime;
        if (data.allDay !== undefined) event.allDay = data.allDay;
        if (data.color !== undefined) event.color = data.color;
        root._onListChanged();
        root._saveToFile();
    }

    function _onListChanged(): void {
        root._triggerListChange();
        root._updateDatesWithEvents();
        root.eventsChanged();
    }

    function _triggerListChange(): void {
        root.list = root.list.slice(0);
    }

    function _updateDatesWithEvents(): void {
        const dates = {};
        root.list.forEach(e => {
            dates[root._dateKey(e.startDate)] = true;
        });
        root._datesWithEvents = dates;
    }

    property var _datesWithEvents: ({})

    function hasEventsOnDate(date): bool {
        return root._datesWithEvents[root._dateKey(date)] !== undefined;
    }

    function _eventToJSON(e) {
        return {
            id: e.id,
            title: e.title,
            startDate: e.startDate.toISOString(),
            startTime: e.startTime,
            endTime: e.endTime,
            allDay: e.allDay,
            color: e.color,
            source: e.source,
        };
    }

    function _saveToFile(): void {
        eventsFileView.setText(JSON.stringify(root.list.map(e => root._eventToJSON(e)), null, 2));
    }

    Component.onCompleted: {
        eventsFileView.reload();
    }

    FileView {
        id: eventsFileView

        path: Qt.resolvedUrl(Paths.eventsData)

        onLoaded: {
            let parsed = [];
            try {
                parsed = JSON.parse(eventsFileView.text());
            } catch (e) {
                console.warn("[CalEvents] Failed to parse events file:", e);
                parsed = [];
            }

            root.list = parsed.map(data => eventComp.createObject(root, {
                id: data.id || "",
                title: data.title || "",
                startDate: data.startDate ? new Date(data.startDate) : new Date(),
                startTime: data.startTime || "",
                endTime: data.endTime || "",
                allDay: data.allDay || false,
                color: data.color || GlobalConfig.dashboard.calendarColors.blue,
                source: data.source || "local",
            }));

            root._onListChanged();
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.list = [];
                root._saveToFile();
            } else {
                console.warn("[CalEvents] Error loading events file:", error);
            }
            root._onListChanged();
        }
    }

    component CalEvent: QtObject {
        property string id
        property string title
        property date startDate
        property string startTime
        property string endTime
        property bool allDay
        property string color
        property string source

        readonly property string dateKey: root._dateKey(startDate)
    }

    Component {
        id: eventComp
        CalEvent {}
    }
}
