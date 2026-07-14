import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../components"
import "../../settings"
import "../../theme"

PanelWindow {
    id: dock

    readonly property var hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property var favorites: ShellConfig.dockFavorites()

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

    anchors.bottom: true
    implicitWidth: dockSurface.implicitWidth + Theme.outerMargin * 2
    implicitHeight: Theme.dockHeight + Theme.outerMargin
    exclusiveZone: 0
    visible: ShellConfig.dockEnabled
    color: "transparent"
    WlrLayershell.namespace: "ayame-shell-dock"

    Surface {
        id: dockSurface
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Theme.outerMargin
        }
        implicitWidth: Math.max(
            Theme.dockHeight,
            dockRow.implicitWidth + Theme.space12
        )
        implicitHeight: Theme.dockHeight
        radius: Theme.radiusLarge
        color: Theme.surface

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: Theme.space4

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
}
