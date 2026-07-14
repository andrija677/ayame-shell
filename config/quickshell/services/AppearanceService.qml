pragma Singleton

import QtQuick
import Quickshell.Io
import "../settings"

QtObject {
    id: root

    property string error: ""

    function applyBlur() {
        if (ruleProcess.running) return;
        error = "";
        if (ShellConfig.blurEnabled) {
            ruleProcess.command = [
                "hyprctl", "eval",
                "if ayame_blur_rule then "
                    + "ayame_blur_rule:set_enabled(true) else "
                    + "ayame_blur_rule=hl.layer_rule({"
                    + "match={namespace=\"ayame-shell-.*\"},"
                    + "blur=true,blur_popups=true,ignore_alpha=0.2}) end"
            ];
        } else {
            ruleProcess.command = [
                "hyprctl", "eval",
                "if ayame_blur_rule then "
                    + "ayame_blur_rule:set_enabled(false) end"
            ];
        }
        ruleProcess.running = true;
    }

    property Process ruleProcess: Process {
        id: ruleProcess
        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim()
        }
    }

    property Connections configConnections: Connections {
        target: ShellConfig
        function onBlurEnabledChanged() { root.applyBlur(); }
    }

    Component.onCompleted: applyBlur()
}
