import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../settings"
import "../theme"

PopupWindow {
    id: root
    required property var hostWindow
    property string status: ""
    function open() {
        keyInput.text = "";
        visible = true;
        checkKey();
    }
    function checkKey() {
        keyProcess.command = [Quickshell.shellDir + "/../../scripts/ayame-ai.py",
            "key-status", ShellConfig.aiProvider];
        keyProcess.running = true;
    }
    function saveKey() {
        if (!keyInput.text.trim()) return;
        keyAction = "store";
        keyProcess.command = [Quickshell.shellDir + "/../../scripts/ayame-ai.py",
            "key-store", ShellConfig.aiProvider];
        keyProcess.running = true;
    }
    function removeKey() {
        keyAction = "delete";
        keyProcess.command = [Quickshell.shellDir + "/../../scripts/ayame-ai.py",
            "key-delete", ShellConfig.aiProvider];
        keyProcess.running = true;
    }
    property string keyAction: "status"
    anchor.window: hostWindow
    anchor.rect.x: Math.round((hostWindow.width - width) / 2)
    anchor.rect.y: hostWindow.height + Theme.space24
    implicitWidth: Math.min(480, hostWindow.screen.width - Theme.space24 * 2)
    implicitHeight: Math.min(setup.implicitHeight + Theme.space24,
        hostWindow.screen.height - hostWindow.height - Theme.space24 * 3)
    color: "transparent"
    grabFocus: true
    visible: false

    Surface {
        anchors.fill: parent
        color: Theme.surfaceContainerHigh
        ColumnLayout {
            id: setup
            anchors { fill: parent; margins: Theme.space12 }
            spacing: Theme.space12
            RowLayout {
                Layout.fillWidth: true
                StyledText { text: "Ayame AI"; font.pixelSize: Theme.fontTitle; font.weight: Theme.fontWeightTitle; Layout.fillWidth: true }
                StyledText {
                    text: "Close"; color: closePointer.containsMouse ? Theme.primary : Theme.outline; font.pixelSize: 9
                    MouseArea {
                        id: closePointer
                        anchors { fill: parent; margins: -Theme.space8 }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.visible = false
                    }
                }
            }
            QuickToggleTile {
                Layout.fillWidth: true
                title: "AI companion"
                subtitle: checked ? "Visible in the top bar" : "Disabled • no network activity"
                checked: ShellConfig.aiEnabled
                onActivated: ShellConfig.aiEnabled = !checked
            }
            RowLayout {
                Layout.fillWidth: true; spacing: Theme.space6
                Repeater {
                    model: [{label:"Gemini",value:"gemini"},{label:"OpenAI",value:"openai"},{label:"Ollama",value:"ollama"}]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; implicitHeight: 32; radius: Theme.radiusPill
                        color: ShellConfig.aiProvider === modelData.value ? Theme.primary : Theme.outlineVariant
                        StyledText { anchors.centerIn: parent; text: parent.modelData.label; color: ShellConfig.aiProvider === parent.modelData.value ? Theme.foregroundPrimary : Theme.foregroundSurfaceVariant; font.pixelSize: 9; font.weight: Theme.fontWeightTitle }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ShellConfig.aiProvider = parent.modelData.value; ShellConfig.aiModel = parent.modelData.value === "gemini" ? "gemini-2.5-flash" : parent.modelData.value === "openai" ? "gpt-4.1-mini" : "llama3.2"; root.checkKey(); } }
                    }
                }
            }
            Surface {
                Layout.fillWidth: true; implicitHeight: 48; color: Theme.surfaceContainer
                TextField {
                    anchors.fill: parent; anchors.margins: Theme.space8
                    text: ShellConfig.aiModel
                    placeholderText: "Model name"
                    color: Theme.foregroundSurface; font.family: Theme.fontFamily
                    background: null
                    onEditingFinished: ShellConfig.aiModel = text.trim()
                }
            }
            Surface {
                Layout.fillWidth: true
                implicitHeight: 48
                visible: ShellConfig.aiProvider !== "gemini"
                color: Theme.surfaceContainer
                TextField {
                    anchors.fill: parent
                    anchors.margins: Theme.space8
                    text: ShellConfig.aiBaseUrl
                    placeholderText: ShellConfig.aiProvider === "ollama"
                        ? "http://127.0.0.1:11434"
                        : "https://api.openai.com"
                    color: Theme.foregroundSurface
                    font.family: Theme.fontFamily
                    background: null
                    onEditingFinished: ShellConfig.aiBaseUrl = text.trim()
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: Theme.space6
                Repeater {
                    model: [{label:"Assistant",value:"assistant"},{label:"Cat-girl",value:"cat"},{label:"Fox-girl",value:"fox"},{label:"Custom",value:"custom"}]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; implicitHeight: 30; radius: Theme.radiusPill
                        color: ShellConfig.aiPersonality === modelData.value ? Theme.primaryContainer : Theme.outlineVariant
                        StyledText { anchors.centerIn: parent; text: parent.modelData.label; color: Theme.foregroundSurfaceVariant; font.pixelSize: 8; font.weight: Theme.fontWeightTitle }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellConfig.aiPersonality = parent.modelData.value }
                    }
                }
            }
            Surface {
                Layout.fillWidth: true
                implicitHeight: 130
                visible: ShellConfig.aiPersonality === "custom"
                color: Theme.surfaceContainer
                TextArea {
                    anchors.fill: parent; anchors.margins: Theme.space8
                    text: ShellConfig.aiCustomPrompt
                    placeholderText: "Write the custom system prompt…"
                    color: Theme.foregroundSurface; placeholderTextColor: Theme.outline
                    font.family: Theme.fontFamily; wrapMode: TextEdit.Wrap
                    background: null
                    onTextChanged: ShellConfig.aiCustomPrompt = text
                }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: ShellConfig.aiProvider !== "ollama"
                Surface {
                    Layout.fillWidth: true; implicitHeight: 44; color: Theme.surfaceContainer
                    TextField {
                        id: keyInput
                        anchors.fill: parent; anchors.margins: Theme.space8
                        echoMode: TextInput.Password
                        placeholderText: "API key • stored in system keyring"
                        color: Theme.foregroundSurface; font.family: Theme.fontFamily; background: null
                        onAccepted: root.saveKey()
                    }
                }
                Rectangle {
                    implicitWidth: 72; implicitHeight: 32; radius: Theme.radiusPill; color: Theme.primaryContainer
                    StyledText { anchors.centerIn: parent; text: "SAVE KEY"; font.pixelSize: 8; font.weight: Theme.fontWeightTitle }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.saveKey() }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    text: ShellConfig.aiProvider === "ollama"
                        ? "Ollama stays local and needs no API key."
                        : root.status
                    color: Theme.foregroundSurfaceVariant
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WordWrap
                }
                StyledText {
                    visible: ShellConfig.aiProvider !== "ollama"
                        && root.status.indexOf("stored") >= 0
                    text: "Remove key"
                    color: removePointer.containsMouse
                        ? Theme.error : Theme.outline
                    font.pixelSize: 9
                    font.weight: Theme.fontWeightTitle
                    MouseArea {
                        id: removePointer
                        anchors { fill: parent; margins: -Theme.space8 }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.removeKey()
                    }
                }
            }
            StyledText {
                Layout.fillWidth: true
                text: "Ayame never gives the model automatic command, clipboard, screenshot, or file access."
                color: Theme.outline; font.pixelSize: 9; wrapMode: Text.WordWrap
            }
        }
    }
    Process {
        id: keyProcess
        stdinEnabled: true
        property string failureText: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.keyAction === "status")
                    root.status = text.trim() === "1" ? "A key is stored securely." : "No key stored yet.";
            }
        }
        stderr: StdioCollector {
            onStreamFinished: keyProcess.failureText = text.trim()
        }
        onRunningChanged: {
            if (running)
                failureText = "";
        }
        onStarted: {
            if (root.keyAction === "store")
                write(keyInput.text.trim() + "\n");
        }
        onExited: (code, status) => {
            if (root.keyAction === "store") {
                root.status = code === 0 ? "Key saved securely."
                    : (failureText.length > 0 ? failureText
                        : "The key could not be saved.");
                if (code === 0) keyInput.text = "";
            } else if (root.keyAction === "delete") {
                root.status = code === 0 ? "Key removed."
                    : (failureText.length > 0 ? failureText
                        : "The key could not be removed.");
            }
            root.keyAction = "status";
        }
    }
}
