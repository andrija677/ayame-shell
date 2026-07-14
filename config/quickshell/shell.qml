//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "modules/bar"
import "modules/dock"
import "services"
import "settings"

ShellRoot {
    id: root

    signal launcherRequested(string action)

    readonly property var appearanceService: AppearanceService
    readonly property var sessionService: SessionService

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.launcherRequested("toggle"); }
        function open(): void { root.launcherRequested("open"); }
        function close(): void { root.launcherRequested("close"); }
    }

    // Hyprland does not emit continuously updated geometry during a pointer
    // move. Keep a light fallback refresh while intelligent hiding is enabled
    // so the dock still reacts during a live Win-drag. A 120 ms refresh caused
    // full toplevel-model reconciliation several times during each popup
    // animation, producing intermittent frame pacing depending on timer phase.
    Timer {
        interval: 500
        repeat: true
        running: ShellConfig.dockEnabled && ShellConfig.dockAutoHide
        triggeredOnStart: true
        onTriggered: Hyprland.refreshToplevels()
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            TopBar {
                required property var modelData
                screen: modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            AppDock {
                required property var modelData
                screen: modelData
                shellController: root
            }
        }
    }
}
