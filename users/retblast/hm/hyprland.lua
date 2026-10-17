-- Hyprland configuration, Lua format (0.57 removes the hyprlang .conf
-- format). Hand-written body, injected by home-manager's extraConfig.
-- The dynamic border palette is applied at runtime by the shell's
-- update-palette flow via hyprctl keyword.

hl.monitor({
	output = "eDP-1",
	scale = 1.25,
})

hl.config({
    xwayland = {
        force_zero_scaling = true
    },

	input = {
		kb_layout = "es",
		follow_mouse = 1,
		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
		},
	},

	cursor = {
		no_hardware_cursors = true,
	},

	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 2,
		col = {
			active_border = "rgba(3584e4b2)",
			inactive_border = "rgba(1d1d20aa)",
		},
		layout = "dwindle",
	},

	decoration = {
		rounding = 8,
		blur = {
			enabled = true,
			size = 6,
			passes = 2,
		},
	},

	misc = {
		disable_hyprland_logo = true,
		force_default_wallpaper = 0,
	},
})

hl.curve("smooth", { type = "bezier", points = { { 0.25, 0.9 }, { 0.1, 1.0 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "smooth" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "smooth" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "smooth" })

-- Session start: publish env to systemd/D-Bus, then regenerate the
-- wallpaper palette (the daemon needs a moment to restore the image).
hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
	hl.exec_cmd("fish -c 'sleep 4; and update-palette'")
end)

local term = "ptyxis"

-- Apps and session
hl.bind("SUPER + Return", hl.dsp.exec_cmd(term))
hl.bind("F12", hl.dsp.exec_cmd(term))
hl.bind("CTRL + ALT + ntilde", hl.dsp.exec_cmd("env TERM=xterm-256color fish -c dmmm-mouse-fix"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("nautilus"))
hl.bind("SUPER + D", hl.dsp.exec_cmd("fuzzel"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("clipboard-pick"))
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("quickshell -c shell ipc call overview toggle"))
hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd("float-workspace"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + M", hl.dsp.exit())

-- Window management
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + Space", hl.dsp.window.float({ action = "toggle" }))

-- Workspaces
for i = 1, 10 do
	hl.bind("SUPER + " .. (i % 10), hl.dsp.focus({ workspace = i }))
end
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + ALT + left", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + ALT + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("CTRL + ALT + SHIFT + left", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind("CTRL + ALT + SHIFT + right", hl.dsp.window.move({ workspace = "e+1" }))

-- Media and capture keys
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bind("Print", hl.dsp.exec_cmd("screenshot-region"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("screenshot-full"))

-- Mouse: move/resize with SUPER + drag
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Trackpad gestures. The workspace action is the 1:1 drag; the overview
-- toggle and focus cycling run their commands.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({
	fingers = 3,
	direction = "up",
	action = function()
		hl.exec_cmd("quickshell -c shell ipc call overview toggle")
	end,
})
hl.gesture({
	fingers = 4,
	direction = "left",
	action = function()
		hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
	end,
})
hl.gesture({
	fingers = 4,
	direction = "right",
	action = function()
		hl.dispatch(hl.dsp.window.cycle_next({ next = true }))
	end,
})

-- Fullscreened windows get their own workspace. Entering fullscreen
-- moves the window to a fresh workspace id (highest existing + 1): a
-- fresh id cannot name an existing workspace on the other monitor, and
-- Hyprland creates new ids on the focused monitor, so the window never
-- changes screens. The origin workspace is remembered per window and
-- restored on leaving fullscreen. The memory is dropped on close, so a
-- recycled address can never inherit a stale entry. FSMODE_NONE=0,
-- FSMODE_MAXIMIZED=1, FSMODE_FULLSCREEN=2 — maximize must not isolate.
-- The event covers every fullscreen path — the SUPER+F bind, video
-- players, games. Verified: fresh-id moves land on the focused
-- monitor; window objects are accepted as the move target.
local fullscreenOrigins = {}

hl.on("window.fullscreen", function(w)
	local mode = w.fullscreen
	local origin = fullscreenOrigins[w.address]
	if mode == 2 and not origin then
		local maxId = 0
		for _, ws in ipairs(hl.get_workspaces()) do
			if ws.id > maxId then
				maxId = ws.id
			end
		end
		fullscreenOrigins[w.address] = w.workspace.id
		hl.dispatch(hl.dsp.window.move({ workspace = tostring(maxId + 1), window = w }))
	elseif mode == 0 and origin then
		fullscreenOrigins[w.address] = nil
		hl.dispatch(hl.dsp.window.move({ workspace = tostring(origin), window = w }))
	end
end)

hl.on("window.close", function(w)
	fullscreenOrigins[w.address] = nil
end)
