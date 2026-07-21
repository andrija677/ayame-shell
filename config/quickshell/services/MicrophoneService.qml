pragma Singleton

import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property var activeStreams: {
        Pipewire.linkGroups.values;
        const streams = [];
        const seen = [];
        for (const group of Pipewire.linkGroups.values) {
            const source = group.source;
            const target = group.target;
            if (!source || !target || group.state !== PwLinkState.Active)
                continue;
            const sourceClass = source.properties?.["media.class"] || "";
            const targetClass = target.properties?.["media.class"] || "";
            const mic = sourceClass === "Audio/Source" ? source
                : targetClass === "Audio/Source" ? target : null;
            const stream = sourceClass === "Stream/Input/Audio" ? source
                : targetClass === "Stream/Input/Audio" ? target : null;
            if (!mic || !stream || seen.indexOf(stream.id) >= 0)
                continue;
            seen.push(stream.id);
            streams.push(stream);
        }
        return streams;
    }
    readonly property bool active: activeStreams.length > 0
    readonly property string appName: {
        if (!active)
            return "";
        const stream = activeStreams[0];
        return stream.properties?.["application.name"]
            || stream.properties?.["media.name"]
            || stream.description
            || stream.nickname
            || stream.name
            || "Microphone";
    }
    readonly property int extraAppCount: Math.max(0, activeStreams.length - 1)
    readonly property var activeCameraStreams: {
        Pipewire.linkGroups.values;
        const streams = [];
        const seen = [];
        for (const group of Pipewire.linkGroups.values) {
            const source = group.source;
            const target = group.target;
            if (!source || !target || group.state !== PwLinkState.Active)
                continue;
            const sourceClass = source.properties?.["media.class"] || "";
            const targetClass = target.properties?.["media.class"] || "";
            const camera = sourceClass === "Video/Source" ? source
                : targetClass === "Video/Source" ? target : null;
            const stream = sourceClass === "Stream/Input/Video" ? source
                : targetClass === "Stream/Input/Video" ? target : null;
            if (!camera || !stream || seen.indexOf(stream.id) >= 0)
                continue;
            seen.push(stream.id);
            streams.push(stream);
        }
        return streams;
    }
    readonly property bool cameraActive: activeCameraStreams.length > 0
    readonly property string cameraAppName: {
        if (!cameraActive)
            return "";
        const stream = activeCameraStreams[0];
        return stream.properties?.["application.name"]
            || stream.properties?.["media.name"]
            || stream.description
            || stream.nickname
            || stream.name
            || "Camera";
    }
    readonly property int extraCameraAppCount:
        Math.max(0, activeCameraStreams.length - 1)

    property PwObjectTracker tracker: PwObjectTracker {
        objects: {
            const tracked = [];
            for (const group of Pipewire.linkGroups.values) {
                tracked.push(group);
                if (group.source) tracked.push(group.source);
                if (group.target) tracked.push(group.target);
            }
            return tracked;
        }
    }
}
