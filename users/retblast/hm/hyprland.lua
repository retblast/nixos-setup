-- Hyprland configuration, Lua format (0.57 removes the hyprlang .conf
-- format). Hand-written body, injected by home-manager's extraConfig.
-- The dynamic border palette is applied at runtime by the shell's
-- palette reader via hyprctl eval (hyprctl keyword is refused under
-- the 0.57 Lua config).

-- Laptop panel: 133% — the same fraction GNOME applies on this
-- machine (monitors.xml stores its float32 rounding: 1.3333333730697632).
hl.monitor({
	output = "eDP-1",
	scale = 4/3,
})

-- External screen, matched by EDID instead of port: vendor code "CRT"
-- (unregistered in the PNP table, so it stays literal) + product name
-- "HDMI" from the EDID 0xFC descriptor. Port-independent; a different
-- screen with a different EDID falls through to the catch-all below.
hl.monitor({
	output = "desc:CRT HDMI",
	scale = 5/3,
})

-- Catch-all: any other screen (projectors, new docks) at 100%.
hl.monitor({
	output = "",
	scale = 1,
})

hl.config({
    xwayland = {
        force_zero_scaling = true
    },

	input = {
		-- es is the boot default; SUPER+K and the bar's layout widget
		-- toggle es <-> us at runtime through hl.config (see below).
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
hl.bind("SUPER + S", hl.dsp.exec_cmd("quickshell -c shell ipc call quicksettings toggle"))
hl.bind("SUPER + N", hl.dsp.exec_cmd("quickshell -c shell ipc call notifcenter toggle"))
hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd("float-workspace"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + M", hl.dsp.exit())

-- Window management
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + Space", hl.dsp.window.float({ action = "toggle" }))

-- Keyboard layout toggle (es <-> us). hl.config called from a bind
-- closure is a dynamic parse (isDynamicParse = not parsing config), so
-- the input:kb_layout refresh bit schedules setKeyboardLayout and the
-- keyboards reconfigure live. Runtime flips do not persist: a reload
-- or relog returns to the es boot default above.
local function currentLayout()
	local v = hl.get_config("input:kb_layout")
	if type(v) == "string" and #v > 0 then
		return v
	end
	return "es"
end

local function toggleLayout()
	hl.config({
		input = {
			kb_layout = currentLayout() == "us" and "es" or "us",
		},
	})
end

hl.bind("SUPER + K", function()
	toggleLayout()
end)

-- Workspaces
-- Numeric binds never focus beyond the highest existing id + 1, so a
-- far jump cannot create holes in the numbering: workspaces stay
-- packed. Empty unfocused workspaces are destroyed by the compositor.
local function maxWorkspaceId()
	local maxId = 0
	for _, ws in ipairs(hl.get_workspaces()) do
		if ws.id > maxId then
			maxId = ws.id
		end
	end
	return maxId
end

-- Sliding workspace window across monitors. The strip is the packed
-- id sequence; monitor i (physical left-to-right order) shows
-- base+i-1, so with two displays the visible pair is (base, base+1).
-- A swipe moves the whole window: (1,2) -> (2,3) -> (3,4) -> (4,5),
-- where 5 is created as the new right edge; swiping back retracts it
-- and the empty edge dies. The right edge may sit one empty workspace
-- past the last populated one, no further.
local function monitorsByPosition()
	local mons = {}
	for _, mon in ipairs(hl.get_monitors()) do
		table.insert(mons, mon)
	end
	table.sort(mons, function(a, b)
		if a.x ~= b.x then
			return a.x < b.x
		end
		return a.y < b.y
	end)
	return mons
end

-- The base anchors to the leftmost monitor's active workspace — the
-- left monitor IS the base by definition. Taking the minimum active id
-- instead mis-anchors when the monitors' actives are inverted (e.g.
-- left on 3, right on 2): the first swipe would move the wrong
-- monitor. A special workspace on the left monitor bails the step.
local function stripBase(mons)
	local ws = mons[1].active_workspace
	if ws and ws.id > 0 then
		return ws.id
	end
	return nil
end

local function maxPopulatedId()
	local maxId = 0
	for _, ws in ipairs(hl.get_workspaces()) do
		if ws.id > 0 and ws.windows > 0 and ws.id > maxId then
			maxId = ws.id
		end
	end
	return maxId
end

local function restoreFocus(name)
	if name then
		hl.dispatch(hl.dsp.focus({ monitor = name }))
	end
end

-- One unit slide. Every monitor shows base+i-1 before the call and
-- base+delta+i-1 after. Each monitor's pass: create the target id if
-- it died as an empty workspace (focus creates on the focused
-- monitor), claim ownership if another monitor holds it, then settle
-- the monitor on the target. The compositor's gap-plug fallback can
-- activate a dormant workspace instead of creating the expected id,
-- so ownership is never assumed — it is claimed. Right-slide passes
-- run right to left: a claim steals the source monitor's active
-- workspace, whose monitor is settled later in the loop. Left-slide
-- passes run left to right: the claimed workspace is dormant on the
-- already-settled left neighbour, so the claim is silent, and the
-- just-deactivated workspace is then passed to the right neighbour.
-- The user's focused monitor is restored last; focus churn inside
-- the sequence never renders a frame.
local function settleMonitor(mon, targetId)
	local tid = tostring(targetId)
	if not hl.get_workspace(tid) then
		hl.dispatch(hl.dsp.focus({ monitor = mon.name }))
		hl.dispatch(hl.dsp.focus({ workspace = tid }))
	end
	hl.dispatch(hl.dsp.workspace.move({ workspace = tid, monitor = mon.name }))
	hl.dispatch(hl.dsp.focus({ monitor = mon.name }))
	hl.dispatch(hl.dsp.focus({ workspace = tid }))
end

local function slideUnit(delta)
	local mons = monitorsByPosition()
	local n = #mons
	local base = stripBase(mons)
	if not base or n == 0 then
		return
	end
	if n == 1 then
		local target = base + delta
		if target >= 1 then
			hl.dispatch(hl.dsp.focus({ workspace = tostring(target) }))
		end
		return
	end
	local focused = hl.get_active_monitor()
	if delta > 0 then
		for i = n, 1, -1 do
			settleMonitor(mons[i], base + i)
		end
	else
		for i = 1, n do
			settleMonitor(mons[i], base + i - 2)
			if i < n then
				-- pass the just-deactivated workspace right; it may have
				-- died as an empty workspace, the next settle re-creates
				-- the id if so
				local passId = base + i - 1
				if hl.get_workspace(tostring(passId)) then
					hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(passId), monitor = mons[i + 1].name }))
				end
			end
		end
	end
	restoreFocus(focused and focused.name or nil)
end

-- The strip may push one empty workspace past the last populated one,
-- but not two: block the right slide when the current right edge is
-- already an empty workspace beyond every populated one.
local function edgeBlocked(base, n)
	local edge = base + n - 1
	local maxPop = maxPopulatedId()
	if maxPop == 0 or edge <= maxPop then
		return false
	end
	for _, ws in ipairs(hl.get_workspaces()) do
		if ws.id == edge then
			return ws.windows == 0
		end
	end
	return true
end

local function slideStrip(delta)
	local mons = monitorsByPosition()
	local base = stripBase(mons)
	if not base then
		return
	end
	if delta > 0 and edgeBlocked(base, #mons) then
		return
	end
	if delta < 0 and base <= 1 then
		return
	end
	slideUnit(delta)
end

-- Numeric binds slide the window until the focused monitor shows the
-- requested workspace. Deliberate navigation, so the empty-edge limit
-- does not apply; the loop stops if a unit slide stops making
-- progress.
for i = 1, 10 do
	hl.bind("SUPER + " .. (i % 10), function()
		local mons = monitorsByPosition()
		local focused = hl.get_active_monitor()
		if not focused then
			return
		end
		local k = nil
		for idx, mon in ipairs(mons) do
			if mon.name == focused.name then
				k = idx
				break
			end
		end
		if not k then
			return
		end
		local target = i - (k - 1)
		local cur = stripBase(mons)
		while cur and cur < target do
			local before = cur
			slideUnit(1)
			cur = stripBase(monitorsByPosition())
			if not cur or cur <= before then
				break
			end
		end
		while cur and cur > target and cur > 1 do
			local before = cur
			slideUnit(-1)
			cur = stripBase(monitorsByPosition())
			if not cur or cur >= before then
				break
			end
		end
	end)
end
hl.bind("SUPER + mouse_down", function()
	slideStrip(1)
end)
hl.bind("SUPER + mouse_up", function()
	slideStrip(-1)
end)
hl.bind("CTRL + ALT + left", function()
	slideStrip(-1)
end)
hl.bind("CTRL + ALT + right", function()
	slideStrip(1)
end)
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

-- Trackpad gestures. The 3-finger horizontal swipe slides the
-- workspace window, content following the fingers: fingers right
-- pulls the view one step back, fingers left pushes one forward.
-- The overview toggle and focus cycling run their commands.
hl.gesture({
	fingers = 3,
	direction = "right",
	action = function()
		slideStrip(-1)
	end,
})
hl.gesture({
	fingers = 3,
	direction = "left",
	action = function()
		slideStrip(1)
	end,
})
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
		fullscreenOrigins[w.address] = w.workspace.id
		hl.dispatch(hl.dsp.window.move({ workspace = tostring(maxWorkspaceId() + 1), window = w }))
	elseif mode == 0 and origin then
		fullscreenOrigins[w.address] = nil
		hl.dispatch(hl.dsp.window.move({ workspace = tostring(origin), window = w }))
	end
end)

hl.on("window.close", function(w)
	fullscreenOrigins[w.address] = nil
end)
