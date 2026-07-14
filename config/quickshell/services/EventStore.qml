pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property var events: adapter.events

    function dateKey(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, "0");
        const day = String(date.getDate()).padStart(2, "0");
        return year + "-" + month + "-" + day;
    }

    function eventsForDate(date) {
        const key = dateKey(date);
        const monthDay = key.slice(5);
        return events.filter(event => event.date === key
            || (event.recurrence === "yearly" && event.date.slice(5) === monthDay));
    }

    function addEvent(title, date, yearly) {
        const cleanTitle = title.trim();
        if (cleanTitle.length === 0)
            return false;

        const updated = events.slice();
        updated.push({
            id: Date.now().toString(),
            title: cleanTitle,
            date: dateKey(date),
            recurrence: yearly ? "yearly" : "none"
        });
        adapter.events = updated;
        eventFile.writeAdapter();
        return true;
    }

    function removeEvent(id) {
        adapter.events = events.filter(event => event.id !== id);
        eventFile.writeAdapter();
    }

    property FileView eventFile: FileView {
        id: eventFile
        path: Quickshell.dataDir + "/events.json"
        preload: true
        atomicWrites: true
        printErrors: false

        JsonAdapter {
            id: adapter
            property var events: []
        }
    }
}
