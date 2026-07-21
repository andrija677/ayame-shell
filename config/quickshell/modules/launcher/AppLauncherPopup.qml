import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../../components"
import "../../theme"

PanelWindow {
    id: root

    property bool panelOpen: false
    property var recentAppIds: []
    MotionProgress { id: motion; open: root.panelOpen }
    readonly property bool commandMode: search.text.startsWith("/")
    readonly property string commandText: commandMode
        ? search.text.slice(1).trim() : ""
    readonly property var filteredApps: {
        DesktopEntries.applications.values;
        if (commandMode)
            return [];
        const needle = search.text.trim().toLowerCase();
        const apps = DesktopEntries.applications.values.filter(entry => {
            if (entry.noDisplay)
                return false;
            if (needle.length === 0)
                return true;
            return (entry.name + " " + entry.genericName + " "
                + entry.keywords.join(" ")).toLowerCase().includes(needle);
        });
        apps.sort((a, b) => {
            if (needle.length === 0 && recentAppIds.length > 0) {
                const aRecent = recentAppIds.indexOf(a.id);
                const bRecent = recentAppIds.indexOf(b.id);
                if (aRecent >= 0 || bRecent >= 0) {
                    if (aRecent < 0) return 1;
                    if (bRecent < 0) return -1;
                    return aRecent - bRecent;
                }
            }
            return a.name.localeCompare(b.name);
        });
        return apps.slice(0, 10);
    }
    readonly property bool showingRecents: !commandMode
        && search.text.trim().length === 0 && recentAppIds.length > 0

    function toggle() {
        if (panelOpen)
            closePanel();
        else
            openPanel();
    }

    function openPanel() {
        closeTimer.stop();
        panelOpen = false;
        visible = true;
        focusRetry.start();
        openTimer.restart();
    }

    function closePanel() {
        openTimer.stop();
        focusRetry.stop();
        panelOpen = false;
        search.text = "";
        closeTimer.restart();
    }

    function launch(entry) {
        if (!entry)
            return;
        const id = entry.id || "";
        if (id.length > 0) {
            const recents = recentAppIds.filter(recentId => recentId !== id);
            recentAppIds = [id].concat(recents).slice(0, 5);
        }
        entry.execute();
        closePanel();
    }

    function runCommand() {
        if (commandText.length === 0 || commandProcess.running)
            return;
        commandProcess.command = [
            Quickshell.shellDir + "/../../scripts/ayame-run-command.sh",
            commandText
        ];
        commandProcess.running = true;
        closePanel();
    }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false
    WlrLayershell.namespace: "ayame-shell-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible
        ? WlrLayershell.OnDemand : WlrLayershell.None

    Shortcut {
        sequence: "Escape"
        onActivated: root.closePanel()
    }

    onVisibleChanged: {
        if (!visible) {
            focusRetry.stop();
            closeTimer.stop();
            panelOpen = false;
            search.text = "";
        }
    }

    Timer {
        id: openTimer
        interval: Theme.motionMapGrace
        onTriggered: {
            root.panelOpen = true;
            focusRetry.start();
        }
    }

    Timer {
        id: focusRetry
        interval: 8
        repeat: true
        onTriggered: {
            search.forceActiveFocus();
            if (search.activeFocus)
                stop();
        }
    }

    Timer {
        id: closeTimer
        interval: Theme.motionNormal + Theme.motionUnmapGrace
        onTriggered: root.visible = false
    }

    Process { id: commandProcess }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        opacity: 0.34 * motion.value
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closePanel()
    }

    Surface {
        id: launcherSurface
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Theme.dockHeight
                + Theme.outerMargin * 3 * motion.value
        }
        width: Math.min(420, root.width - Theme.space24)
        implicitHeight: launcherContent.implicitHeight + Theme.space24
        opacity: motion.value
        radius: Theme.radiusLarge
        color: Theme.surface

        transform: Scale {
            origin.x: launcherSurface.width / 2
            origin.y: launcherSurface.height
            xScale: 0.94 + 0.06 * motion.value
            yScale: 0.86 + 0.14 * motion.value
        }

        ColumnLayout {
            id: launcherContent
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space12 }
            spacing: Theme.space8

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: root.showingRecents ? "Recent Applications" : "Applications"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Theme.fontWeightTitle
                    Layout.fillWidth: true
                }
                StyledText {
                    text: "Esc to Close"
                    color: Theme.outline
                    font.pixelSize: 9
                    font.weight: Theme.fontWeightTitle
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Theme.radiusMedium
                color: root.commandMode
                    ? Theme.primaryContainer : Theme.surfaceContainer
                border.color: search.activeFocus ? Theme.primary : Theme.outlineVariant
                border.width: root.commandMode ? 2 : 1

                Canvas {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.space12
                        verticalCenter: parent.verticalCenter
                    }
                    width: 18
                    height: 18
                    property color strokeColor: Theme.primary
                    onStrokeColorChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = strokeColor;
                        ctx.lineWidth = 2;
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.arc(7.25, 7.25, 5, 0, Math.PI * 2);
                        ctx.moveTo(11, 11);
                        ctx.lineTo(16, 16);
                        ctx.stroke();
                    }
                }

                TextInput {
                    id: search
                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; leftMargin: 42; rightMargin: Theme.space12 }
                    color: Theme.foregroundSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontNormal
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    clip: true
                    Keys.onDownPressed: {
                        appList.currentIndex = 0;
                        appList.forceActiveFocus();
                    }
                    onAccepted: {
                        if (root.commandMode)
                            root.runCommand();
                        else
                            root.launch(root.filteredApps[0]);
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: parent.text.length === 0
                        text: "Search apps or type /command…"
                        color: Theme.outline
                        font.weight: Theme.fontWeightBody
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                visible: root.commandMode
                radius: Theme.radiusMedium
                color: commandPointer.containsMouse
                    ? Theme.primaryContainer : Theme.surfaceContainerHigh

                RowLayout {
                    anchors { fill: parent; leftMargin: Theme.space12; rightMargin: Theme.space12 }
                    spacing: Theme.space12
                    StyledText {
                        text: ">_"
                        color: Theme.primary
                        font.family: Theme.fontFamilyNumeric
                        font.weight: Theme.fontWeightTitle
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            Layout.fillWidth: true
                            text: root.commandText.length > 0
                                ? root.commandText : "Type a command after /"
                            font.family: Theme.fontFamilyNumeric
                            font.weight: Theme.fontWeightLabel
                            elide: Text.ElideRight
                        }
                        StyledText {
                            text: root.commandText.length > 0
                                ? "Run Command • Enter" : "The / prefix is not executed"
                            color: Theme.foregroundSurfaceVariant
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                }

                MouseArea {
                    id: commandPointer
                    anchors.fill: parent
                    enabled: root.commandText.length > 0 && !commandProcess.running
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.runCommand()
                }
            }

            ListView {
                id: appList
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, 460)
                clip: true
                spacing: Theme.space4
                model: root.filteredApps
                visible: !root.commandMode
                currentIndex: count > 0 ? 0 : -1
                keyNavigationWraps: true
                Keys.onUpPressed: event => {
                    if (currentIndex === 0) {
                        search.forceActiveFocus();
                        event.accepted = true;
                    } else {
                        event.accepted = false;
                    }
                }
                Keys.onPressed: event => {
                    if (event.text.length > 0 && event.modifiers === Qt.NoModifier) {
                        search.text += event.text;
                        search.cursorPosition = search.text.length;
                        search.forceActiveFocus();
                        event.accepted = true;
                    }
                }
                Keys.onReturnPressed: root.launch(root.filteredApps[currentIndex])
                Keys.onEnterPressed: root.launch(root.filteredApps[currentIndex])

                delegate: Rectangle {
                    id: appDelegate
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 46
                    radius: Theme.radiusMedium
                    color: ListView.isCurrentItem || appPointer.containsMouse
                        ? Theme.surfaceContainerHigh : "transparent"

                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.space8; rightMargin: Theme.space12 }
                        spacing: Theme.space12
                        Item {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            readonly property string resolvedIcon: Quickshell.iconPath(
                                appDelegate.modelData.icon || "", true)

                            IconImage {
                                anchors.fill: parent
                                source: parent.resolvedIcon
                                visible: parent.resolvedIcon.length > 0
                                asynchronous: true
                                mipmap: true
                            }
                            Rectangle {
                                anchors.fill: parent
                                visible: parent.resolvedIcon.length === 0
                                radius: Theme.radiusSmall
                                color: Theme.primaryContainer
                                StyledText {
                                    anchors.centerIn: parent
                                    text: (appDelegate.modelData.name || "?").slice(0, 1).toUpperCase()
                                    color: Theme.foregroundPrimaryContainer
                                    font.weight: Theme.fontWeightTitle
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                text: appDelegate.modelData.name
                                font.weight: Theme.fontWeightLabel
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            StyledText {
                                visible: text.length > 0
                                text: appDelegate.modelData.genericName || appDelegate.modelData.comment
                                color: Theme.foregroundSurfaceVariant
                                font.pixelSize: Theme.fontSmall
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        id: appPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: appList.currentIndex = appDelegate.index
                        onClicked: root.launch(appDelegate.modelData)
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: !root.commandMode && root.filteredApps.length === 0
                text: "No applications found"
                color: Theme.foregroundSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSmall
            }

            RowLayout {
                Layout.fillWidth: true
                visible: !root.commandMode && root.filteredApps.length > 0

                StyledText {
                    text: "↑↓  Navigate"
                    color: Theme.outline
                    font.pixelSize: 9
                    font.family: Theme.fontFamily
                }
                StyledText {
                    text: "Enter  Open"
                    color: Theme.outline
                    font.pixelSize: 9
                    font.family: Theme.fontFamily
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
                StyledText {
                    text: "/  Command"
                    color: Theme.outline
                    font.pixelSize: 9
                    font.family: Theme.fontFamily
                }
            }
        }
    }
}
