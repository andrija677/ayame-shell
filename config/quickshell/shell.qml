//@ pragma UseQApplication

import QtQuick
import Quickshell
import "modules/bar"
import "modules/dock"
import "services"

ShellRoot {
    readonly property var appearanceService: AppearanceService
    readonly property var sessionService: SessionService

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
            }
        }
    }
}
