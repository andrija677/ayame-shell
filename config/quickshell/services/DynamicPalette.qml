pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../settings"

QtObject {
    id: root

    property var colors: paletteCache.colors
    property bool generating: false
    property string error: ""
    property string outputBuffer: ""
    readonly property bool available: colors !== null
    readonly property bool active: ShellConfig.dynamicColorsEnabled && available

    function schemeForStyle(style) {
        if (style === "vibrant") return "scheme-vibrant";
        if (style === "expressive") return "scheme-expressive";
        return "scheme-tonal-spot";
    }

    function darkColor(name, fallback) {
        const entry = colors?.[name];
        return entry?.dark?.color ?? entry?.default?.color ?? fallback;
    }

    function generate() {
        const path = ShellConfig.dynamicColorWallpaper.trim();
        if (path.length === 0 || generator.running) {
            if (path.length === 0) error = "Choose a wallpaper image first";
            return;
        }
        error = "";
        outputBuffer = "";
        generating = true;
        generator.command = [
            "matugen", "image", path,
            "--dry-run", "-j", "hex", "-m", "dark",
            "-t", schemeForStyle(ShellConfig.dynamicColorStyle),
            "--source-color-index", "0"
        ];
        generator.running = true;
    }

    function disable() {
        ShellConfig.dynamicColorsEnabled = false;
        error = "";
    }

    property Process generator: Process {
        id: generator

        stdout: StdioCollector {
            onStreamFinished: root.outputBuffer = text
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    root.error = text.trim().split("\n").pop();
            }
        }

        onRunningChanged: {
            if (running) return;
            root.generating = false;
            if (root.outputBuffer.length === 0) {
                if (root.error.length === 0)
                    root.error = "Could not generate a palette from that image";
                return;
            }
            try {
                const result = JSON.parse(root.outputBuffer);
                if (!result.colors) throw new Error("missing colors");
                root.colors = result.colors;
                paletteCache.colors = result.colors;
                paletteCache.wallpaper = ShellConfig.dynamicColorWallpaper;
                paletteCache.style = ShellConfig.dynamicColorStyle;
                paletteFile.writeAdapter();
                ShellConfig.dynamicColorsEnabled = true;
                root.error = "";
            } catch (exception) {
                root.error = "Matugen returned an invalid palette";
            }
        }
    }

    property FileView paletteFile: FileView {
        id: paletteFile
        path: Quickshell.cacheDir + "/dynamic-palette.json"
        preload: true
        atomicWrites: true
        printErrors: false

        JsonAdapter {
            id: paletteCache
            property var colors: null
            property string wallpaper: ""
            property string style: ""
        }
    }

    Component.onCompleted: {
        const cacheMatches = paletteCache.wallpaper === ShellConfig.dynamicColorWallpaper
            && paletteCache.style === ShellConfig.dynamicColorStyle;
        if (ShellConfig.dynamicColorsEnabled && !cacheMatches)
            generate();
    }
}
