import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../components"
import "../../settings"
import "../../theme"
import "../launcher"

PanelWindow {
    id: dock

    required property var shellController
    readonly property var hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property var favorites: ShellConfig.dockFavorites()
    readonly property var appEntries: {
        const entries = {};
        const encountered = [];
        for (let id of favorites) {
            entries[id] = { id: id, toplevel: null };
            encountered.push(id);
        }
        const windows = Hyprland.toplevels.values;
        for (let i = 0; i < windows.length; ++i) {
            const candidate = windows[i];
            if (candidate.monitor !== hyprlandMonitor)
                continue;
            const id = desktopIdFor(candidate);
            if (!id)
                continue;
            if (!entries[id]) {
                entries[id] = { id: id, toplevel: candidate };
                encountered.push(id);
            } else if (!entries[id].toplevel || candidate.activated) {
                entries[id] = { id: id, toplevel: candidate };
            }
        }
        const order = ShellConfig.dockOrder();
        encountered.sort((a, b) => {
            const ai = order.indexOf(a);
            const bi = order.indexOf(b);
            if (ai < 0 && bi < 0)
                return 0;
            if (ai < 0)
                return 1;
            if (bi < 0)
                return -1;
            return ai - bi;
        });
        return encountered.map(id => entries[id]);
    }
    readonly property bool hasAppItems: appEntries.length > 0
    readonly property bool workspaceObstructed: {
        const workspace = hyprlandMonitor?.activeWorkspace;
        if (!workspace)
            return false;
        if (workspace.hasFullscreen)
            return true;

        const windows = workspace.toplevels.values;
        const monitorLeft = hyprlandMonitor.x;
        const monitorBottom = hyprlandMonitor.y + hyprlandMonitor.height;
        const dockLeft = monitorLeft
            + (hyprlandMonitor.width - dockSurface.implicitWidth) / 2;
        const dockRight = dockLeft + dockSurface.implicitWidth;
        const dockTop = monitorBottom
            - Theme.dockHeight - Theme.outerMargin * 2;
        for (let i = 0; i < windows.length; ++i) {
            const geometry = windows[i].lastIpcObject?.size;
            const position = windows[i].lastIpcObject?.at;
            if (!geometry || geometry.length < 2
                    || !position || position.length < 2)
                continue;
            const windowRight = position[0] + geometry[0];
            const windowBottom = position[1] + geometry[1];
            const overlapsDock = windowRight > dockLeft
                && position[0] < dockRight
                && windowBottom > dockTop
                && position[1] < monitorBottom;
            if (overlapsDock)
                return true;
        }
        return false;
    }
    readonly property bool dockHidden: ShellConfig.dockAutoHide
        && workspaceObstructed && !pointerReveal && !launcher.panelOpen
    property bool pointerReveal: false
    property bool pinHintPresented: false
    property bool pinHintOpen: false

    function offerPinHint() {
        if (!hasAppItems || ShellConfig.dockPinHintShown)
            return;
        ShellConfig.dockPinHintShown = true;
        pinHintPresented = true;
        pinHintOpen = true;
        pinHintTimer.restart();
    }

    onHasAppItemsChanged: offerPinHint()
    Component.onCompleted: Qt.callLater(offerPinHint)

    Connections {
        target: ShellConfig
        function onDockPinHintShownChanged() {
            if (!ShellConfig.dockPinHintShown)
                Qt.callLater(dock.offerPinHint);
        }
    }

    function desktopIdFor(toplevel) {
        const appId = toplevel?.wayland?.appId
            || toplevel?.lastIpcObject?.class || "";
        return DesktopEntries.heuristicLookup(appId)?.id || appId;
    }

    function toplevelFor(desktopId) {
        for (let i = 0; i < Hyprland.toplevels.values.length; ++i) {
            const candidate = Hyprland.toplevels.values[i];
            if (desktopIdFor(candidate) === desktopId)
                return candidate;
        }
        return null;
    }

    function reorderDockApp(sourceId, sceneX) {
        const local = dockRow.mapFromItem(null, sceneX, 0).x;
        let targetId = "";
        let afterTarget = false;
        let nearestDistance = Number.MAX_VALUE;
        for (let i = 0; i < dockRepeater.count; ++i) {
            const item = dockRepeater.itemAt(i);
            if (!item || item.favoriteId === sourceId)
                continue;
            const center = item.x + item.width / 2;
            const distance = Math.abs(local - center);
            if (distance < nearestDistance) {
                nearestDistance = distance;
                targetId = item.favoriteId;
                afterTarget = local > center;
            }
        }
        if (targetId)
            ShellConfig.reorderDockApp(sourceId, targetId,
                appEntries.map(entry => entry.id), afterTarget);
    }

    Connections {
        target: dock.shellController

        function onLauncherRequested(action) {
            if (action === "close") {
                if (launcher.panelOpen)
                    launcher.closePanel();
                return;
            }
            if (Hyprland.focusedMonitor !== dock.hyprlandMonitor)
                return;
            if (action === "open")
                launcher.openPanel();
            else
                launcher.toggle();
        }
    }

    anchors.bottom: true
    implicitWidth: dockSurface.implicitWidth + Theme.outerMargin * 2
    implicitHeight: Theme.dockHeight + Theme.outerMargin
        + (pinHintPresented ? 44 : 0)
    exclusiveZone: 0
    visible: ShellConfig.dockEnabled
    color: "transparent"
    WlrLayershell.namespace: "ayame-shell-dock"

    HoverHandler {
        id: dockHover
        onHoveredChanged: {
            if (hovered) {
                hideDelay.stop();
                dock.pointerReveal = true;
            } else {
                hideDelay.restart();
            }
        }
    }

    Timer {
        id: hideDelay
        interval: 420
        onTriggered: dock.pointerReveal = false
    }

    Timer {
        id: pinHintTimer
        interval: 5500
        onTriggered: {
            dock.pinHintOpen = false;
            pinHintUnmapTimer.restart();
        }
    }

    Timer {
        id: pinHintUnmapTimer
        interval: Theme.motionNormal + Theme.motionUnmapGrace
        onTriggered: dock.pinHintPresented = false
    }

    Surface {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: dockSurface.top
            bottomMargin: Theme.space8
        }
        implicitWidth: pinHintText.implicitWidth + Theme.space24
        implicitHeight: 34
        visible: dock.pinHintPresented
        opacity: dock.pinHintOpen ? 1 : 0
        scale: dock.pinHintOpen ? 1 : 0.94
        radius: Theme.radiusPill
        color: Theme.surfaceContainerHigh

        Behavior on opacity {
            NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter }
        }
        Behavior on scale {
            NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter }
        }

        StyledText {
            id: pinHintText
            anchors.centerIn: parent
            text: "Tip: Right-click an app to pin it"
            color: Theme.foregroundSurfaceVariant
            font.pixelSize: Theme.fontSmall
            font.weight: Theme.fontWeightLabel
        }
    }

    Surface {
        id: dockSurface
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: dock.dockHidden
                ? -Theme.dockHeight : Theme.outerMargin
        }
        implicitWidth: Math.max(
            Theme.dockHeight,
            dockRow.implicitWidth + Theme.space12
        )
        implicitHeight: Theme.dockHeight
        radius: Theme.radiusLarge
        color: Theme.surface

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: dock.dockHidden
                    ? Theme.motionNormal : Theme.motionSlow
                easing.type: dock.dockHidden
                    ? Theme.easeExit : Theme.easeEnter
            }
        }

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: Theme.space4

            move: Transition {
                NumberAnimation {
                    properties: "x"
                    duration: Theme.motionSlow
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.75
                }
            }

            Rectangle {
                implicitWidth: 42
                implicitHeight: 42
                radius: Theme.radiusMedium
                color: launcher.panelOpen ? Theme.primaryContainer
                    : launcherPointer.containsMouse ? Theme.surfaceContainerHigh
                    : "transparent"
                scale: launcherPointer.pressed ? 0.9 : 1

                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                Behavior on scale {
                    NumberAnimation { duration: Theme.motionFast; easing.type: Theme.easeEnter }
                }

                Grid {
                    anchors.centerIn: parent
                    columns: 3
                    spacing: 3

                    Repeater {
                        model: 9

                        Rectangle {
                            required property int index
                            width: 3.5
                            height: 3.5
                            radius: width / 2
                            color: launcher.panelOpen
                                ? Theme.primary : Theme.foregroundSurface
                            scale: launcher.panelOpen ? 1.12 : 1

                            Behavior on color {
                                ColorAnimation { duration: Theme.motionFast }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: Theme.motionFast
                                    easing.type: Theme.easeEnter
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: launcherPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: launcher.toggle()
                }
            }

            Rectangle {
                width: 1
                height: 26
                anchors.verticalCenter: parent.verticalCenter
                visible: dock.hasAppItems
                color: Theme.outlineVariant
            }

            Repeater {
                id: dockRepeater
                model: ScriptModel {
                    values: dock.appEntries
                    objectProp: "id"
                }

                DockItem {
                    required property var modelData
                    desktopId: modelData.id
                    toplevel: modelData.toplevel
                    dockController: dock
                }
            }
        }
    }

    AppLauncherPopup {
        id: launcher
        screen: dock.screen
    }
}
