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
    property string sourceStyle: ""
    property string pendingPath: ""
    property string pendingStyle: ""
    property string detectedWallpaper: ""
    property string ayameWallpaperPath: ""
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

    function modeColor(name, mode, fallback) {
        const entry = colors?.[name];
        return entry?.[mode]?.color ?? entry?.default?.color ?? fallback;
    }

    function generate(requestedPath) {
        const path = (requestedPath ?? ShellConfig.dynamicColorWallpaper).trim();
        if (path.length === 0) {
            error = "Choose a wallpaper image first";
            return;
        }
        if (generator.running) {
            pendingPath = path;
            pendingStyle = ShellConfig.dynamicColorStyle;
            generating = true;
            return;
        }
        error = "";
        outputBuffer = "";
        sourcePath = path;
        sourceStyle = ShellConfig.dynamicColorStyle;
        generating = true;
        generator.command = [
            "matugen", "image", path,
            "--dry-run", "-j", "hex", "-m", "dark",
            "-t", schemeForStyle(sourceStyle),
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

    function followAyameWallpaper(path) {
        const clean = path.trim();
        if (!ShellConfig.ready || clean.length === 0)
            return;
        // Migrate installations created with the old first-run defaults, but
        // never override an established user's chosen appearance.
        if (!ShellConfig.onboardingCompleted
                && clean.endsWith("/assets/wallpapers/ayame-default.jpg")) {
            ShellConfig.colorScheme = "light";
            ShellConfig.dynamicColorMode = "automatic";
        }
        followWallpaper(clean);
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
        syncKitty();
    }

    function syncKitty() {
        if (kittySync.running) return;
        const mode = ShellConfig.colorScheme === "light" ? "light" : "dark";
        function color(name, fallback) {
            return active ? modeColor(name, mode, fallback) : fallback;
        }
        kittySync.command = [
            Quickshell.shellDir + "/../../scripts/ayame-kitty-colors.sh",
            color("background", mode === "light" ? "#FEF7FF" : "#121116"),
            color("on_surface", mode === "light" ? "#1D1B20" : "#F0ECF4"),
            color("primary", mode === "light" ? "#68548E" : "#D0BCFF"),
            color("on_primary", mode === "light" ? "#FFFFFF" : "#381E72"),
            color("surface", mode === "light" ? "#FEF7FF" : "#1C1B22"),
            color("surface_container_high", mode === "light" ? "#EDE6EE" : "#302D39"),
            color("outline", mode === "light" ? "#7A757F" : "#958E9B"),
            color("error", mode === "light" ? "#BA1A1A" : "#FFB4AB"),
            mode === "light" ? "#386A3A" : "#A6D6A8",
            mode === "light" ? "#765A00" : "#FFDDB3"
        ];
        kittySync.running = true;
    }

    property Process kittySync: Process {
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    root.error = "Kitty colors: " + text.trim().split("\n").pop();
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.error.length === 0)
                root.error = "Kitty colors could not be updated";
        }
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
            if (root.pendingPath.length > 0
                    && (root.pendingPath !== root.sourcePath
                        || root.pendingStyle !== root.sourceStyle)) {
                root.queuedPath = root.pendingPath;
                root.pendingPath = "";
                root.pendingStyle = "";
                root.outputBuffer = "";
                root.error = "";
                queuedGenerate.restart();
                return;
            }
            root.pendingPath = "";
            root.pendingStyle = "";
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
                    paletteCache.style = root.sourceStyle;
                    paletteFile.writeAdapter();
                    ShellConfig.dynamicColorsEnabled = true;
                    root.syncKitty();
                    root.error = "";
                } catch (exception) {
                    root.error = "Matugen returned an invalid palette";
                }
            }
            root.generating = false;
        }
    }

    property string queuedPath: ""
    property Timer queuedGenerate: Timer {
        interval: 1
        onTriggered: {
            const path = root.queuedPath;
            root.queuedPath = "";
            root.generate(path);
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

    property FileView ayameWallpaperFile: FileView {
        path: (Quickshell.env("XDG_STATE_HOME")
            || Quickshell.env("HOME") + "/.local/state")
            + "/ayame-shell/wallpaper.path"
        preload: true
        watchChanges: true
        printErrors: false

        onLoaded: {
            root.ayameWallpaperPath = text().trim();
            if (ShellConfig.ready)
                root.followAyameWallpaper(root.ayameWallpaperPath);
        }
        onFileChanged: reload()
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
        // ShellConfig is backed by an asynchronously loaded FileView. Running
        // this immediately can briefly see the default dark mode during a live
        // update and overwrite an existing light Kitty palette.
        initialKittySync.restart();
        if (ShellConfig.dynamicColorWallpaper.length > 0)
            followWallpaper(ShellConfig.dynamicColorWallpaper);
        if (ShellConfig.dynamicColorMode === "manual") {
            const cacheMatches = paletteCache.wallpaper
                    === ShellConfig.dynamicColorWallpaper
                && paletteCache.style === ShellConfig.dynamicColorStyle;
            if (ShellConfig.dynamicColorsEnabled && !cacheMatches)
                generate(ShellConfig.dynamicColorWallpaper);
        }
    }

    property Timer initialKittySync: Timer {
        interval: 100
        onTriggered: {
            if (ShellConfig.ready)
                root.syncKitty();
            else
                restart();
        }
    }

    property Connections styleConnections: Connections {
        target: ShellConfig
        function onReadyChanged() {
            if (ShellConfig.ready && root.ayameWallpaperPath.length > 0)
                root.followAyameWallpaper(root.ayameWallpaperPath);
        }
        function onDynamicColorStyleChanged() {
            if (ShellConfig.dynamicColorMode === "automatic"
                    && root.detectedWallpaper.length > 0)
                root.followWallpaper(root.detectedWallpaper);
        }
        function onColorSchemeChanged() { root.syncKitty(); }
        function onDynamicColorsEnabledChanged() { root.syncKitty(); }
        function onDynamicColorWallpaperChanged() {
            if (ShellConfig.dynamicColorWallpaper.length > 0)
                root.followWallpaper(ShellConfig.dynamicColorWallpaper);
        }
    }
}
