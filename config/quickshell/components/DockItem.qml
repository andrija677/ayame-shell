import QtQuick
import Quickshell
import Quickshell.Widgets
import "../settings"
import "../theme"

Rectangle {
    id: root

    property var toplevel: null
    property var dockController: null
    required property var hostWindow
    property string desktopId: ""
    property int windowCount: 0
    property int dockIndex: 0
    property int revealGeneration: 0
    readonly property string appId: desktopId.length > 0 ? desktopId
        : toplevel?.wayland?.appId || toplevel?.lastIpcObject?.class || ""
    readonly property var desktopEntry: desktopId.length > 0
        ? (DesktopEntries.byId(desktopId) || DesktopEntries.heuristicLookup(desktopId))
        : DesktopEntries.heuristicLookup(appId)
    readonly property string favoriteId: desktopEntry?.id || appId
    readonly property bool active: toplevel?.activated || false
    readonly property bool urgent: toplevel?.urgent || false
    readonly property bool pinned: ShellConfig.dockAppPinned(favoriteId)
    readonly property string displayName: desktopEntry?.name || appId || "Application"
    property bool pinChanging: false
    property real pinBounceDirection: -1
    property real dragOffset: 0
    property real pressSceneX: 0
    property bool dragInProgress: false
    property bool contextMenuOpen: false

    implicitWidth: 42
    implicitHeight: 42
    radius: Theme.radiusMedium
    color: active ? Theme.primaryContainer
        : pointer.containsMouse ? Theme.surfaceContainerHigh : "transparent"
    scale: pointer.pressed ? 0.9 : pointer.containsMouse ? 1.08 : 1
    y: pointer.containsMouse ? -Theme.space4 : 0
    opacity: 0

    transform: [
        Translate { id: pinSlide; x: 14 },
        Translate { x: root.dragOffset },
        Translate { id: revealLift },
        Translate { id: pinBounce }
    ]

    onRevealGenerationChanged: {
        if (revealGeneration > 0)
            revealBounce.restart();
    }

    SequentialAnimation {
        id: revealBounce
        PauseAnimation { duration: Math.max(0, root.dockIndex) * 38 }
        NumberAnimation {
            target: revealLift
            property: "y"
            to: -7
            duration: Theme.motionFast
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: revealLift
            property: "y"
            to: 1.5
            duration: Theme.motionNormal
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: revealLift
            property: "y"
            to: 0
            duration: Theme.motionFast
            easing.type: Easing.OutSine
        }
    }

    function playEntryAnimation() {
        enterAnimation.stop();
        pinChanging = false;
        opacity = 0;
        // Pinned items arrive from the running-app side. Unpinned running
        // items return from the favorites side to their previous position.
        pinSlide.x = pinned ? 14 : -14;
        enterAnimation.start();
    }

    function togglePinned() {
        if (pinChanging)
            return;
        contextMenuOpen = false;
        pinBounceDirection = pinned ? 1 : -1;
        pinChanging = true;
        pinBounceAnimation.restart();
    }

    function openNewWindow() {
        contextMenuOpen = false;
        desktopEntry?.execute();
    }

    function closeWindow() {
        contextMenuOpen = false;
        toplevel?.wayland?.close();
    }

    Component.onCompleted: {
        if (visible)
            playEntryAnimation();
    }
    onVisibleChanged: {
        if (visible)
            playEntryAnimation();
    }

    ParallelAnimation {
        id: enterAnimation
        NumberAnimation {
            target: root; property: "opacity"; to: 1
            duration: Theme.motionNormal; easing.type: Theme.easeEnter
        }
        NumberAnimation {
            target: pinSlide; property: "x"; to: 0
            duration: Theme.motionNormal; easing.type: Theme.easeEnter
        }
    }

    SequentialAnimation {
        id: pinBounceAnimation
        onFinished: {
            if (!root.pinChanging)
                return;
            ShellConfig.toggleDockFavorite(root.favoriteId);
            root.pinChanging = false;
        }
        NumberAnimation {
            target: pinBounce
            property: "y"
            to: root.pinBounceDirection * 6
            duration: Math.round(Theme.motionFast * 0.7)
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: pinBounce
            property: "y"
            to: 0
            duration: Math.round(Theme.motionNormal * 0.6)
            easing.type: Easing.OutSine
        }
        NumberAnimation {
            target: pinBounce
            property: "y"
            to: root.pinBounceDirection * 4
            duration: Math.round(Theme.motionFast * 0.7)
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: pinBounce
            property: "y"
            to: 0
            duration: Math.round(Theme.motionNormal * 0.6)
            easing.type: Easing.OutSine
        }
    }

    NumberAnimation {
        id: dragReturn
        target: root
        property: "dragOffset"
        to: 0
        duration: Theme.motionNormal
        easing.type: Theme.easeEnter
    }

    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    Behavior on scale {
        NumberAnimation { duration: Theme.motionFast; easing.type: Theme.easeEnter }
    }
    Behavior on y {
        NumberAnimation { duration: Theme.motionFast; easing.type: Theme.easeEnter }
    }
    readonly property string resolvedIcon: Quickshell.iconPath(
        root.desktopEntry?.icon || "", true)

    IconImage {
        id: appIcon
        anchors.centerIn: parent
        implicitSize: 28
        source: root.resolvedIcon
        visible: root.resolvedIcon.length > 0
        asynchronous: true
        mipmap: true
    }

    Rectangle {
        anchors.centerIn: parent
        width: 28
        height: 28
        visible: root.resolvedIcon.length === 0
        radius: Theme.radiusSmall
        color: Theme.primaryContainer
        StyledText {
            anchors.centerIn: parent
            text: (root.desktopEntry?.name || root.appId || "?").slice(0, 1).toUpperCase()
            color: Theme.foregroundPrimaryContainer
            font.weight: Theme.fontWeightTitle
        }
    }

    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 2
        }
        width: root.active ? 18 : 7
        height: 3
        visible: root.windowCount > 0
        radius: 2
        color: root.urgent ? Theme.error
            : root.active ? Theme.primary : Theme.outline

        Behavior on width {
            NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter }
        }
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.dragInProgress
            ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        onPressed: event => {
            tooltipDelay.stop();
            tooltipOpen = false;
            dragReturn.stop();
            root.dragOffset = 0;
            root.dragInProgress = false;
            root.pressSceneX = root.mapToItem(
                null, event.x, event.y).x;
        }

        onPositionChanged: event => {
            if (!pressed || !(event.buttons & Qt.LeftButton))
                return;
            const sceneX = root.mapToItem(null, event.x, event.y).x;
            const distance = sceneX - root.pressSceneX;
            if (!root.dragInProgress
                    && Math.abs(distance) >= 8)
                root.dragInProgress = true;
            if (root.dragInProgress) {
                root.z = 100;
                root.dragOffset = distance;
            }
        }

        onReleased: event => {
            if (event.button === Qt.RightButton && !root.dragInProgress) {
                root.contextMenuOpen = true;
                contextMenuTimer.restart();
                return;
            }

            if (root.dragInProgress) {
                const releasePoint = root.mapToItem(
                    null, root.width / 2, root.height / 2);
                if (root.dockController)
                    root.dockController.reorderDockApp(
                        root.favoriteId, releasePoint.x);
                root.dragInProgress = false;
                // ScriptModel applies the new row position on the next event
                // turn. Compensate for that base-position change so the icon
                // remains exactly under the release point, then settle it.
                Qt.callLater(() => {
                    const shiftedPoint = root.mapToItem(
                        null, root.width / 2, root.height / 2);
                    root.dragOffset += releasePoint.x - shiftedPoint.x;
                    root.z = 0;
                    dragReturn.restart();
                });
                return;
            }

            revealBounce.restart();
            if (!root.toplevel) {
                root.desktopEntry?.execute();
            } else if (!root.toplevel.wayland) {
                return;
            } else if (root.active) {
                root.toplevel.wayland.minimized = true;
            } else {
                root.toplevel.wayland.activate();
            }
        }

        onCanceled: {
            root.dragInProgress = false;
            root.z = 0;
            dragReturn.restart();
        }

        onEntered: tooltipDelay.restart()
        onExited: {
            tooltipDelay.stop();
            tooltipOpen = false;
        }
    }

    property bool tooltipOpen: false

    Timer {
        id: tooltipDelay
        interval: 420
        onTriggered: root.tooltipOpen = true
    }

    Timer {
        id: contextMenuTimer
        interval: 7000
        onTriggered: root.contextMenuOpen = false
    }

    PopupWindow {
        id: contextMenu
        anchor.window: root.hostWindow
        anchor.rect.x: Math.max(Theme.outerMargin,
            root.mapToItem(null, 0, 0).x - width / 2 + root.width / 2)
        anchor.rect.y: root.mapToItem(null, 0, 0).y - height - Theme.space8
        implicitWidth: 196
        implicitHeight: contextMenuColumn.implicitHeight + Theme.space16
        color: "transparent"
        grabFocus: true
        visible: root.contextMenuOpen
        onVisibleChanged: {
            if (!visible && root.contextMenuOpen) {
                contextMenuTimer.stop();
                root.contextMenuOpen = false;
            }
        }

        Shortcut {
            sequence: "Escape"
            onActivated: root.contextMenuOpen = false
        }

        Surface {
            anchors.fill: parent
            radius: Theme.radiusLarge
            color: Theme.surfaceContainerHigh

            Column {
                id: contextMenuColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Theme.space8
                }
                spacing: Theme.space4

                StyledText {
                    width: parent.width
                    height: 28
                    leftPadding: Theme.space8
                    rightPadding: Theme.space8
                    text: root.displayName
                    color: Theme.foregroundSurfaceVariant
                    font.pixelSize: Theme.fontSmall
                    font.weight: Theme.fontWeightLabel
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: Theme.radiusSmall
                    color: newWindowPointer.containsMouse
                        ? Theme.primaryContainer : "transparent"
                    opacity: root.desktopEntry ? 1 : 0.45
                    StyledText {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: Theme.space8
                        }
                        text: "Open New Window"
                        font.weight: Theme.fontWeightLabel
                    }
                    MouseArea {
                        id: newWindowPointer
                        anchors.fill: parent
                        enabled: root.desktopEntry !== null
                            && root.desktopEntry !== undefined
                        hoverEnabled: true
                        cursorShape: enabled
                            ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.openNewWindow()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: Theme.radiusSmall
                    color: pinPointer.containsMouse
                        ? Theme.primaryContainer : "transparent"
                    StyledText {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: Theme.space8
                        }
                        text: root.pinned ? "Unpin from Dock" : "Pin to Dock"
                        font.weight: Theme.fontWeightLabel
                    }
                    MouseArea {
                        id: pinPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePinned()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: root.windowCount > 0 ? 36 : 0
                    visible: root.windowCount > 0
                    radius: Theme.radiusSmall
                    color: closeWindowPointer.containsMouse
                        ? Theme.error : "transparent"
                    StyledText {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: Theme.space8
                        }
                        text: root.windowCount > 1
                            ? "Close One Window" : "Close Window"
                        color: closeWindowPointer.containsMouse
                            ? Theme.foregroundPrimary : Theme.error
                        font.weight: Theme.fontWeightLabel
                    }
                    MouseArea {
                        id: closeWindowPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeWindow()
                    }
                }
            }
        }
    }

    PopupWindow {
        anchor.window: root.hostWindow
        anchor.rect.x: root.mapToItem(null, 0, 0).x
            - width / 2 + root.width / 2
        anchor.rect.y: root.mapToItem(null, 0, 0).y - height - Theme.space4
        implicitWidth: Math.min(280,
            Math.max(110, tooltipContent.implicitWidth + Theme.space24))
        implicitHeight: tooltipContent.implicitHeight + Theme.space12
        color: "transparent"
        grabFocus: false
        visible: root.tooltipOpen && pointer.containsMouse
            && !root.contextMenuOpen

        Surface {
            anchors.fill: parent
            radius: Theme.radiusMedium
            color: Theme.surfaceContainerHigh

            Column {
                id: tooltipContent
                anchors.centerIn: parent
                spacing: 1

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.displayName
                    font.pixelSize: Theme.fontSmall
                    font.weight: Theme.fontWeightLabel
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.windowCount > 0
                    text: root.windowCount === 1 ? "1 window"
                        : root.windowCount + " windows"
                    color: Theme.foregroundSurfaceVariant
                    font.pixelSize: 9
                }
            }
        }
    }
}
