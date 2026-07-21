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
    signal areaCaptureRequested()

    readonly property var appearanceService: AppearanceService
    readonly property var sessionService: SessionService

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.launcherRequested("toggle"); }
        function open(): void { root.launcherRequested("open"); }
        function close(): void { root.launcherRequested("close"); }
    }

    IpcHandler {
        target: "capture"
        function area(): void { root.areaCaptureRequested(); }
    }

    // Hyprland does not emit continuously updated geometry during a pointer
    // move. Refresh only while intelligent hiding is enabled so the dock can
    // react during a live Win-drag rather than waiting for a later event.
    Timer {
        interval: 120
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
                shellController: root
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
