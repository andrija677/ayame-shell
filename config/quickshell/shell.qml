import QtQuick
import Quickshell
import "modules/bar"

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
}
