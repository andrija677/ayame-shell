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
            const sourceIsMic = (source.type & PwNodeType.AudioSource) !== 0;
            const targetIsCapture = (target.type & PwNodeType.AudioInStream) !== 0;
            if (!sourceIsMic || !targetIsCapture || seen.indexOf(target.id) >= 0)
                continue;
            seen.push(target.id);
            streams.push(target);
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
            const sourceIsCamera = (source.type & PwNodeType.VideoSource) !== 0;
            const targetIsCapture = target.isStream
                && (target.type & PwNodeType.VideoSink) !== 0;
            if (!sourceIsCamera || !targetIsCapture || seen.indexOf(target.id) >= 0)
                continue;
            seen.push(target.id);
            streams.push(target);
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
