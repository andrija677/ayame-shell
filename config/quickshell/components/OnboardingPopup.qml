import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../settings"
import "../theme"

PanelWindow {
    id: root
    property int page: 0
    readonly property var pages: [
        {
            icon: "󰣇", title: "Welcome to Ayame",
            body: "A calm, capability-aware Hyprland shell. Unsupported hardware controls stay out of your way automatically."
        },
        {
            icon: "󰌌", title: "The essentials",
            body: "Press Super for Applications, Super + L to lock, Shift + Print for Ayame capture, and Super + . for emoji."
        },
        {
            icon: "󰒓", title: "Make it yours",
            body: "Open Ayame Settings from Quick Settings to adjust the interface, services, Night Light, timeout rules, and diagnostics."
        }
    ]

    function finish() {
        ShellConfig.onboardingCompleted = true;
        visible = false;
    }

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0; color: "transparent"
    visible: false
    WlrLayershell.namespace: "ayame-shell-welcome"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrLayershell.Exclusive : WlrLayershell.None
    Shortcut { sequence: "Escape"; onActivated: root.finish() }
    Shortcut {
        sequence: "Right"
        onActivated: root.page < root.pages.length - 1 ? root.page++ : root.finish()
    }
    Shortcut { sequence: "Left"; enabled: root.page > 0; onActivated: root.page-- }
    Timer {
        interval: 250
        repeat: true
        running: true
        onTriggered: {
            if (!ShellConfig.ready)
                return;
            stop();
            if (!ShellConfig.onboardingCompleted)
                root.visible = true;
        }
    }

    Rectangle { anchors.fill: parent; color: Theme.translucent("#000000", 0.42) }
    Surface {
        anchors.centerIn: parent
        width: Math.min(520, root.width - Theme.space24 * 2)
        implicitHeight: 360
        color: Theme.surface
        ColumnLayout {
            anchors { fill: parent; margins: Theme.space24 }
            spacing: Theme.space16
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.pages[root.page].icon
                color: Theme.primary; font.pixelSize: 54
            }
            StyledText {
                Layout.fillWidth: true
                text: root.pages[root.page].title
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 22; font.weight: Theme.fontWeightTitle
            }
            StyledText {
                Layout.fillWidth: true; Layout.fillHeight: true
                text: root.pages[root.page].body
                color: Theme.foregroundSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: Theme.space6
                Repeater {
                    model: root.pages.length
                    Rectangle {
                        width: index === root.page ? 24 : 8; height: 8
                        radius: Theme.radiusPill
                        color: index === root.page ? Theme.primary : Theme.outlineVariant
                        Behavior on width { NumberAnimation { duration: Theme.motionNormal } }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: Theme.space8
                QuickActionButton {
                    Layout.fillWidth: true
                    icon: root.page === 0 ? "×" : "←"
                    label: root.page === 0 ? "Skip" : "Back"
                    onActivated: root.page === 0 ? root.finish() : root.page--
                }
                QuickActionButton {
                    Layout.fillWidth: true; primary: true
                    icon: root.page === root.pages.length - 1 ? "✓" : "→"
                    label: root.page === root.pages.length - 1 ? "Start using Ayame" : "Continue"
                    onActivated: root.page === root.pages.length - 1
                        ? root.finish() : root.page++
                }
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Use ← → and Escape from the keyboard"
                color: Theme.outline; font.pixelSize: 10
            }
        }
    }
}
