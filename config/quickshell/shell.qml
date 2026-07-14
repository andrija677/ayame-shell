import QtQuick
import Quickshell
import "modules/bar"
import "modules/dock"

ShellRoot {
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
