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
    property string sourcePath: ""
    property string detectedWallpaper: ""
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

    function generate(requestedPath) {
        const path = (requestedPath ?? ShellConfig.dynamicColorWallpaper).trim();
        if (path.length === 0 || generator.running) {
            if (path.length === 0) error = "Choose a wallpaper image first";
            return;
        }
        error = "";
        outputBuffer = "";
        sourcePath = path;
        generating = true;
        generator.command = [
            "matugen", "image", path,
            "--dry-run", "-j", "hex", "-m", "dark",
            "-t", schemeForStyle(ShellConfig.dynamicColorStyle),
            "--source-color-index", "0"
        ];
        generator.running = true;
    }

    function followWallpaper(path) {
        const clean = path.trim();
        if (clean.length === 0) return;
        detectedWallpaper = clean;
        if (ShellConfig.dynamicColorMode !== "automatic") return;
        if (paletteCache.wallpaper === clean
                && paletteCache.style === ShellConfig.dynamicColorStyle
                && paletteCache.colors !== null) {
            colors = paletteCache.colors;
            ShellConfig.dynamicColorsEnabled = true;
            error = "";
            return;
        }
        automaticGenerate.restart();
    }

    function useAutomatic() {
        ShellConfig.dynamicColorMode = "automatic";
        if (detectedWallpaper.length > 0)
            followWallpaper(detectedWallpaper);
        else
            error = "Current wallpaper could not be detected";
    }

    function useManual() {
        ShellConfig.dynamicColorMode = "manual";
    }

    function disable() {
        ShellConfig.dynamicColorsEnabled = false;
        ShellConfig.dynamicColorMode = "off";
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
            if (root.outputBuffer.length === 0) {
                if (root.error.length === 0)
                    root.error = "Could not generate a palette from that image";
            } else {
                try {
                    const result = JSON.parse(root.outputBuffer);
                    if (!result.colors) throw new Error("missing colors");
                    root.colors = result.colors;
                    paletteCache.colors = result.colors;
                    paletteCache.wallpaper = root.sourcePath;
                    paletteCache.style = ShellConfig.dynamicColorStyle;
                    paletteFile.writeAdapter();
                    ShellConfig.dynamicColorsEnabled = true;
                    root.error = "";
                } catch (exception) {
                    root.error = "Matugen returned an invalid palette";
                }
            }
            root.generating = false;
        }
    }

    property Timer automaticGenerate: Timer {
        interval: 350
        onTriggered: root.generate(root.detectedWallpaper)
    }

    property FileView ml4wWallpaperFile: FileView {
        path: Quickshell.env("HOME")
            + "/.cache/ml4w/hyprland-dotfiles/current_wallpaper"
        preload: true
        watchChanges: true
        printErrors: false

        onLoaded: root.followWallpaper(text())
        onFileChanged: {
            reload();
            root.followWallpaper(text());
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
        if (ShellConfig.dynamicColorMode === "manual") {
            const cacheMatches = paletteCache.wallpaper
                    === ShellConfig.dynamicColorWallpaper
                && paletteCache.style === ShellConfig.dynamicColorStyle;
            if (ShellConfig.dynamicColorsEnabled && !cacheMatches)
                generate(ShellConfig.dynamicColorWallpaper);
        }
    }

    property Connections styleConnections: Connections {
        target: ShellConfig
        function onDynamicColorStyleChanged() {
            if (ShellConfig.dynamicColorMode === "automatic"
                    && root.detectedWallpaper.length > 0)
                root.followWallpaper(root.detectedWallpaper);
        }
    }
}
