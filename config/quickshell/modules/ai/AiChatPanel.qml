import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../components"
import "../../settings"
import "../../theme"

PanelWindow {
    id: root
    required property var hostWindow
    property bool panelOpen: false
    property bool thinking: false
    property bool receiving: false
    property var messages: []
    property bool historyLoaded: false
    property string pendingImagePath: ""
    property string pendingImageUrl: ""
    property int copiedMessageIndex: -1
    property string pendingCopyText: ""
    readonly property string basePrompt:
        "You are Ayame, an AI assistant living inside a Linux and Hyprland desktop shell. "
        + "Be concise, helpful, warm, and technically accurate. Never claim you ran commands, "
        + "inspected files, or changed the system unless the user supplied the results. "
        + "Never execute commands. Explain risky or destructive actions clearly. Respect privacy."
    readonly property string systemPrompt: ShellConfig.aiPersonality === "custom"
        ? (ShellConfig.aiCustomPrompt.trim().length > 0
            ? ShellConfig.aiCustomPrompt : basePrompt)
        : basePrompt + (ShellConfig.aiPersonality === "cat"
            ? " You have a playful, affectionate cat-girl style with gentle :3 energy, "
                + "while remaining honest, supportive, and never emotionally manipulative."
            : ShellConfig.aiPersonality === "fox"
                ? " You have a warm, clever, lightly mischievous fox-girl style, "
                    + "while remaining honest, supportive, and never emotionally manipulative."
                : "")

    function toggle() { panelOpen ? closePanel() : openPanel(); }
    function openPanel() { visible = true; panelOpen = true; input.forceActiveFocus(); }
    function closePanel() { panelOpen = false; closeTimer.restart(); }
    function append(role, content) {
        const copy = messages.slice();
        copy.push({ role: role, content: content });
        messages = copy;
        saveHistory();
        Qt.callLater(() => chatList.positionViewAtEnd());
    }
    function saveHistory() {
        if (!historyLoaded) return;
        historyAdapter.messages = messages.slice(-60);
        historySaveTimer.restart();
    }
    function clearHistory() {
        if (chatProcess.running) chatProcess.signal(15);
        messages = [];
        saveHistory();
    }
    function send() {
        const text = input.text.trim();
        if ((!text && !pendingImagePath) || chatProcess.running) return;
        const prompt = text || "What can you tell me about this image?";
        const imagePath = pendingImagePath;
        input.text = "";
        pendingImagePath = "";
        pendingImageUrl = "";
        const copy = messages.slice();
        copy.push({ role: "user", content: prompt, imagePath: imagePath });
        messages = copy;
        saveHistory();
        append("assistant", "");
        startChat();
    }
    function startChat() {
        thinking = true;
        receiving = false;
        chatProcess.command = [
            Quickshell.shellDir + "/../../scripts/ayame-ai.py", "chat"
        ];
        chatProcess.running = true;
    }
    function retryLast() {
        if (chatProcess.running || messages.length < 2)
            return;
        const copy = messages.slice();
        if (copy[copy.length - 1].role !== "assistant")
            return;
        copy[copy.length - 1] = { role: "assistant", content: "" };
        messages = copy;
        saveHistory();
        startChat();
    }
    function copyMessage(index, content) {
        if (!content || copyProcess.running)
            return;
        pendingCopyText = content;
        copiedMessageIndex = index;
        copiedTimer.restart();
        copyProcess.command = [
            Quickshell.shellDir + "/../../scripts/ayame-ai.py", "copy"
        ];
        copyProcess.running = true;
    }
    function selectImage(url) {
        const value = url.toString();
        pendingImageUrl = value;
        pendingImagePath = decodeURIComponent(value.replace(/^file:\/\//, ""));
        input.forceActiveFocus();
    }
    function acceptEvent(line) {
        if (!line.trim()) return;
        try {
            const event = JSON.parse(line);
            if (event.type === "delta") {
                thinking = false;
                receiving = true;
                const copy = messages.slice();
                const last = copy.length - 1;
                copy[last] = { role: "assistant",
                    content: copy[last].content + event.text };
                messages = copy;
                Qt.callLater(() => chatList.positionViewAtEnd());
            } else if (event.type === "error") {
                thinking = false;
                receiving = false;
                const copy = messages.slice();
                copy[copy.length - 1] = { role: "assistant",
                    content: "⚠ " + event.message };
                messages = copy;
                saveHistory();
            } else if (event.type === "done") {
                thinking = false;
                receiving = false;
                saveHistory();
            }
        } catch (error) {}
    }

    Timer {
        id: historySaveTimer
        interval: 180
        onTriggered: historyFile.writeAdapter()
    }

    FileView {
        id: historyFile
        path: Quickshell.dataDir + "/ai-chat-history.json"
        preload: true
        atomicWrites: true
        printErrors: false
        onLoaded: {
            root.messages = historyAdapter.messages || [];
            root.historyLoaded = true;
        }
        JsonAdapter {
            id: historyAdapter
            property var messages: []
        }
    }

    FileDialog {
        id: imagePicker
        title: "Attach an image"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.gif)"]
        onAccepted: root.selectImage(selectedFile)
    }

    Timer {
        id: copiedTimer
        interval: 1600
        onTriggered: root.copiedMessageIndex = -1
    }

    Process {
        id: copyProcess
        stdinEnabled: true
        onStarted: write(JSON.stringify({ text: root.pendingCopyText }) + "\n")
        onExited: root.pendingCopyText = ""
    }

    screen: hostWindow.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    visible: false
    WlrLayershell.namespace: "ayame-shell-ai"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible
        ? WlrLayershell.OnDemand : WlrLayershell.None

    MouseArea { anchors.fill: parent; onClicked: root.closePanel() }
    Timer { id: closeTimer; interval: Theme.motionNormal + Theme.motionUnmapGrace; onTriggered: root.visible = false }

    Process {
        id: chatProcess
        stdinEnabled: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.acceptEvent(data)
        }
        onStarted: {
            const history = root.messages.slice(0, -1);
            write(JSON.stringify({
                provider: ShellConfig.aiProvider,
                model: ShellConfig.aiModel,
                baseUrl: ShellConfig.aiBaseUrl,
                systemPrompt: root.systemPrompt,
                history: history
            }) + "\n");
        }
        onExited: {
            root.thinking = false;
            root.receiving = false;
        }
    }

    Surface {
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left; margins: Theme.outerMargin }
        width: Math.min(430, root.width - Theme.space24)
        color: Theme.surface
        opacity: root.panelOpen ? 1 : 0
        x: root.panelOpen ? 0 : -48
        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
        Behavior on x { NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter } }
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors { fill: parent; margins: Theme.space16 }
            spacing: Theme.space12
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    StyledText { text: "Ayame AI  ✦"; font.pixelSize: Theme.fontTitle; font.weight: Theme.fontWeightTitle }
                    StyledText { text: ShellConfig.aiProvider + " • " + ShellConfig.aiPersonality; color: Theme.foregroundSurfaceVariant; font.pixelSize: Theme.fontSmall }
                }
                StyledText {
                    text: "New chat"; color: clearPointer.containsMouse ? Theme.primary : Theme.outline; font.pixelSize: 9
                    MouseArea {
                        id: clearPointer
                        anchors { fill: parent; margins: -Theme.space8 }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearHistory()
                    }
                }
                StyledText {
                    text: "Close"; color: closePointer.containsMouse ? Theme.primary : Theme.outline; font.pixelSize: 9
                    MouseArea {
                        id: closePointer
                        anchors { fill: parent; margins: -Theme.space8 }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closePanel()
                    }
                }
            }

            ListView {
                id: chatList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.space8
                model: root.messages
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: bubble.implicitHeight
                    Surface {
                        id: bubble
                        width: parent.modelData.imagePath
                            ? Math.min(parent.width * 0.88, 300)
                            : Math.min(parent.width * 0.88, body.implicitWidth + Theme.space24)
                        anchors.right: parent.modelData.role === "user" ? parent.right : undefined
                        anchors.left: parent.modelData.role === "assistant" ? parent.left : undefined
                        implicitHeight: messageColumn.implicitHeight + Theme.space16
                        color: parent.modelData.role === "user"
                            ? Theme.primaryContainer : Theme.surfaceContainerHigh
                        Column {
                            id: messageColumn
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space8 }
                            spacing: Theme.space8
                            Image {
                                width: parent.width
                                height: visible ? Math.min(180, implicitHeight) : 0
                                visible: bubble.parent.modelData.imagePath
                                    && bubble.parent.modelData.imagePath.length > 0
                                source: visible ? "file://" + bubble.parent.modelData.imagePath : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: false
                            }
                            StyledText {
                                id: body
                                width: parent.width
                                text: bubble.parent.modelData.content
                                // Plain text prevents model output from loading remote
                                // images or interpreting HTML inside the shell.
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap
                                color: bubble.parent.modelData.role === "user"
                                    ? Theme.foregroundPrimaryContainer : Theme.foregroundSurface
                            }
                            Row {
                                anchors.right: parent.right
                                spacing: Theme.space12
                                opacity: messagePointer.containsMouse ? 1 : 0
                                visible: body.text.length > 0
                                Behavior on opacity {
                                    NumberAnimation { duration: Theme.motionFast }
                                }
                                StyledText {
                                    text: root.copiedMessageIndex === bubble.parent.index
                                        ? "COPIED" : "COPY"
                                    color: copyPointer.containsMouse
                                        ? Theme.primary : Theme.outline
                                    font.pixelSize: 8
                                    font.weight: Theme.fontWeightTitle
                                    MouseArea {
                                        id: copyPointer
                                        anchors { fill: parent; margins: -Theme.space6 }
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.copyMessage(
                                            bubble.parent.index, body.text)
                                    }
                                }
                                StyledText {
                                    visible: bubble.parent.modelData.role === "assistant"
                                        && bubble.parent.index === root.messages.length - 1
                                    text: "RETRY"
                                    color: retryPointer.containsMouse
                                        ? Theme.primary : Theme.outline
                                    font.pixelSize: 8
                                    font.weight: Theme.fontWeightTitle
                                    MouseArea {
                                        id: retryPointer
                                        anchors { fill: parent; margins: -Theme.space6 }
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.retryLast()
                                    }
                                }
                            }
                        }
                        MouseArea {
                            id: messagePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: root.messages.length === 0
                    text: "Ask about Linux, Hyprland, or anything else :3"
                    color: Theme.outline
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: root.thinking || root.receiving ? 24 : 0
                opacity: implicitHeight > 0 ? 1 : 0
                Behavior on implicitHeight { NumberAnimation { duration: Theme.motionNormal } }
                Row {
                    anchors.centerIn: parent
                    spacing: Theme.space6
                    Repeater {
                        model: 5
                        Rectangle {
                            required property int index
                            width: root.receiving ? 5 : 7
                            height: width
                            radius: width / 2
                            color: index % 2 ? Theme.primary : Theme.foregroundPrimaryContainer
                            SequentialAnimation on y {
                                running: (root.thinking || root.receiving) && ShellConfig.animationsEnabled
                                loops: Animation.Infinite
                                PauseAnimation { duration: index * 55 }
                                NumberAnimation { to: -5; duration: 280; easing.type: Easing.OutSine }
                                NumberAnimation { to: 3; duration: 320; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0; duration: 260; easing.type: Easing.OutSine }
                                PauseAnimation { duration: (4 - index) * 55 }
                            }
                        }
                    }
                }
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: root.pendingImagePath ? 82 : 0
                opacity: root.pendingImagePath ? 1 : 0
                visible: implicitHeight > 0
                color: Theme.surfaceContainerHigh
                Behavior on implicitHeight { NumberAnimation { duration: Theme.motionNormal } }
                Image {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; margins: Theme.space8 }
                    width: 66; height: 66
                    source: root.pendingImageUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }
                StyledText {
                    anchors { right: parent.right; top: parent.top; margins: Theme.space12 }
                    text: "Remove"
                    color: removeImagePointer.containsMouse ? Theme.primary : Theme.outline
                    font.pixelSize: 9
                    MouseArea {
                        id: removeImagePointer
                        anchors { fill: parent; margins: -Theme.space8 }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.pendingImagePath = "";
                            root.pendingImageUrl = "";
                        }
                    }
                }
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: Math.max(48, input.implicitHeight + Theme.space16)
                color: Theme.surfaceContainer
                border.width: input.activeFocus ? 1 : 0
                border.color: Theme.primary
                TextArea {
                    id: input
                    anchors { left: attachButton.right; right: sendButton.left; top: parent.top; bottom: parent.bottom; margins: Theme.space8 }
                    placeholderText: "Message Ayame…"
                    color: Theme.foregroundSurface
                    placeholderTextColor: Theme.outline
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontNormal
                    wrapMode: TextEdit.Wrap
                    background: null
                    Keys.onPressed: event => {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                && !(event.modifiers & Qt.ShiftModifier)) {
                            root.send(); event.accepted = true;
                        }
                    }
                }
                Rectangle {
                    id: attachButton
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.space8 }
                    width: 34; height: 34; radius: 17
                    color: attachPointer.containsMouse
                        ? Theme.surfaceContainerHigh : "transparent"
                    StyledText {
                        anchors.centerIn: parent
                        text: "＋"
                        color: root.pendingImagePath ? Theme.primary : Theme.foregroundSurfaceVariant
                        font.pixelSize: Theme.fontTitle
                    }
                    MouseArea {
                        id: attachPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: imagePicker.open()
                    }
                }
                Rectangle {
                    id: sendButton
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Theme.space8 }
                    width: 34; height: 34; radius: 17
                    color: sendPointer.containsMouse ? Theme.primary : Theme.primaryContainer
                    StyledText { anchors.centerIn: parent; text: chatProcess.running ? "■" : "↑"; color: Theme.foregroundPrimaryContainer; font.weight: Theme.fontWeightTitle }
                    MouseArea {
                        id: sendPointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: chatProcess.running ? chatProcess.signal(15) : root.send()
                    }
                }
            }
            StyledText {
                Layout.fillWidth: true
                text: ShellConfig.aiProvider === "ollama"
                    ? "Local provider • Ayame cannot execute commands"
                    : "Messages are sent to " + ShellConfig.aiProvider + " • no automatic system access"
                color: Theme.outline; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
