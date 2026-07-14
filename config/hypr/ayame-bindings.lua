-- Optional development bindings for Hyprland 0.55+.
local project = os.getenv("HOME") .. "/Projects/ayame-shell"
local ayame = "qs --path " .. project .. "/config/quickshell"
local screenshot = project .. "/scripts/ayame-screenshot.sh"

hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(ayame .. " ipc call launcher toggle"), { release = true })
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("Print", hl.dsp.exec_cmd(screenshot .. " desktop 0"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(screenshot .. " area 0"))
hl.bind("SUPER + Print", hl.dsp.exec_cmd(screenshot .. " monitor 0 AUTO"))
