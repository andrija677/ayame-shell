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
    readonly property bool workspaceObstructed: {
        const workspace = hyprlandMonitor?.activeWorkspace;
        if (!workspace)
            return false;
        if (workspace.hasFullscreen)
            return true;

        const windows = workspace.toplevels.values;
        for (let i = 0; i < windows.length; ++i) {
            const geometry = windows[i].lastIpcObject?.size;
            if (!geometry || geometry.length < 2)
                continue;
            const fillsWidth = geometry[0] >= screen.width * 0.78;
            const fillsHeight = geometry[1] >= screen.height * 0.65;
            if (fillsWidth && fillsHeight)
                return true;
        }
        return false;
    }
    readonly property bool dockHidden: ShellConfig.dockAutoHide
        && workspaceObstructed && !pointerReveal && !launcher.panelOpen
    property bool pointerReveal: false

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
                color: Theme.outlineVariant
            }

            Repeater {
                model: dock.favorites

                DockItem {
                    required property string modelData
                    desktopId: modelData
                    toplevel: dock.toplevelFor(modelData)
                }
            }

            Repeater {
                model: Hyprland.toplevels

                DockItem {
                    required property var modelData
                    toplevel: modelData
                    visible: modelData.monitor === dock.hyprlandMonitor
                        && dock.favorites.indexOf(dock.desktopIdFor(modelData)) < 0
                }
            }
        }
    }

    AppLauncherPopup {
        id: launcher
        screen: dock.screen
    }
}
