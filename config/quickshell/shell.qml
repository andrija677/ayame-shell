//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import "modules/bar"
import "modules/dock"
import "services"

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
