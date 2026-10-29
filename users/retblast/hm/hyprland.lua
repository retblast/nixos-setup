-- Hyprland configuration, Lua format (0.57 removes the hyprlang .conf
-- format). Hand-written body, injected by home-manager's extraConfig.
-- The dynamic border palette is applied at runtime by the shell's
-- palette reader via hyprctl eval (hyprctl keyword is refused under
-- the 0.57 Lua config).

-- Laptop panel: 133% — the same fraction GNOME applies on this
-- machine (monitors.xml stores its float32 rounding: 1.3333333730697632).
--
-- The panel is the right screen: the external screen stands to its
-- left. The external screen is 2560 wide at 166%, so it takes 1536
-- logical pixels.
hl.monitor({
	output = "eDP-1",
	scale = 4/3,
	position = "1536,0",
})

-- External screen, matched by EDID instead of port: vendor code "CRT"
-- (unregistered in the PNP table, so it stays literal) + product name
-- "HDMI" from the EDID 0xFC descriptor. Port-independent; a different
-- screen with a different EDID falls through to the catch-all below.
-- It is the left screen and the main display.
hl.monitor({
	output = "desc:CRT HDMI",
	scale = 5/3,
	position = "0,0",
})

-- Catch-all: any other screen (projectors, new docks) at 100%.
hl.monitor({
	output = "",
	scale = 1,
})

-- The external screen is the main display when it is connected: it
-- takes the focus, so the keyboard and the new workspaces follow it.
-- The screen is found by its EDID description, so the port does not
-- matter.
hl.on("monitor.added", function(mon)
	if mon.description == "CRT HDMI" then
		hl.dispatch(hl.dsp.focus({ monitor = mon.name }))
	end
end)

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

-- Trackpad gestures. The 3-finger horizontal swipe drags the
-- workspace strip with the finger; the 3-finger up swipe opens the
-- overview. Focus cycling runs its command.
--
-- The swipe is finger tracked: the content of the strip follows the
-- fingers, and the gesture decides how far the content travels.
--
-- The factor follows the model GNOME uses for its own workspace swipe
-- (js/ui/swipeTracker.js in gnome-shell): a full horizontal swipe is
-- TOUCHPAD_BASE_WIDTH touchpad units, and the swipe is normalized
-- against it. The screen width is therefore STRIP_SWIPE_UNITS units of
-- finger travel. This is normalized, so it does not depend on the
-- resolution of the touchpad: the touchpad reports no resolution and
-- libinput has no public API for one, so nothing better is available.
--
-- The strip keeps its layout while it moves: the leftmost monitor
-- shows the base workspace, the next monitor the next id. The drag
-- moves the whole band, so the content of the right monitor slides
-- across the border onto the left one while the left monitor's
-- content leaves the screen. The release commits the step through the
-- same path the keyboard binds use.
local STRIP_SWIPE_UNITS = 400
local STRIP_FLICK_MS = 150

-- Pixels per touchpad unit on this monitor. A full screen width is a
-- full swipe of STRIP_SWIPE_UNITS units.
local function stripPixelsPerUnit(mon)
	local width = mon.width
	if not width or width <= 0 then
		return nil
	end
	return width / STRIP_SWIPE_UNITS
end

-- The workspaces of the strip: one per monitor, the ids counting up
-- from the base of the leftmost monitor.
local function stripIds(base, count)
	local ids = {}
	for i = 1, count do
		ids[i] = base + i - 1
	end
	return ids
end

local stripDrag = nil

-- Moves the whole strip by the travelled distance. Every workspace
-- gets the same offset, so the band keeps its shape.
local function stripApply(drag)
	for i = 1, #drag.ids do
		local id = tostring(drag.ids[i])
		hl.ws.force_render(id, true)
		hl.ws.set_render_offset(id, drag.travel, 0)
	end
end

-- Puts the workspaces back into their resting state. The animated
-- variant slides the content home, which is what a release below the
-- threshold does.
local function stripRelease(drag, animate)
	for i = 1, #drag.ids do
		local id = tostring(drag.ids[i])
		if animate then
			hl.ws.animate_render_offset(id, 0, 0)
		else
			hl.ws.reset(id)
		end
		hl.ws.force_render(id, false)
	end
end

-- The commit hands the workspaces over to the compositor: the step
-- moves them between the monitors and the compositor animates it. A
-- workspace that changed its monitor keeps its offset, so the
-- animation starts where the finger left the content. A workspace that
-- stayed or left the strip is put back at rest.
local function stripCommit(drag)
	local before = drag.monitors
	slideStrip(drag.step)
	for i = 1, #drag.ids do
		local id = drag.ids[i]
		local ws = hl.get_workspace(tostring(id))
		local now = ws and ws.monitor and ws.monitor.name or nil
		if now and now ~= before[id] then
			-- Changed its monitor: the compositor animates the move, and
			-- the offset it starts from is where the finger left it.
			hl.ws.force_render(tostring(id), false)
		else
			-- Stayed in place or left the strip: back at rest.
			hl.ws.reset(tostring(id))
		end
	end
end

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = {
		start = function(event)
			local mons = monitorsByPosition()
			local base = stripBase(mons)
			if not base or #mons == 0 then
				return
			end
			local focused = hl.get_active_monitor()
			local reference = focused and focused.name or mons[1].name
			local mon = nil
			for _, candidate in ipairs(mons) do
				if candidate.name == reference then
					mon = candidate
					break
				end
			end
			if not mon then
				return
			end
			local units = stripPixelsPerUnit(mon)
			if not units then
				return
			end
			local ids = stripIds(base, #mons)
			local monitors = {}
			for i = 1, #mons do
				monitors[ids[i]] = mons[i].name
			end
			stripDrag = {
				ids = ids,
				monitors = monitors,
				units = units,
				limit = mon.width,
				-- The swipe completes when it covers a whole screen,
				-- the same normalization GNOME uses.
				threshold = mon.width,
				travel = 0,
				previous = 0,
				time = event.time_ms,
				previousTime = event.time_ms,
				step = 0,
			}
		end,
		update = function(event)
			local drag = stripDrag
			if not drag then
				return
			end
			-- The gesture delta is the movement of this event, not the
			-- total since the gesture began, so the travel accumulates
			-- here.
			local travel = drag.travel + event.delta.x * drag.units
			if travel > drag.limit then
				travel = drag.limit
			elseif travel < -drag.limit then
				travel = -drag.limit
			end
			if drag.step == 0 and math.abs(travel) > 4 then
				-- Fingers left push the strip forward, fingers right pull
				-- it back.
				drag.step = travel < 0 and 1 or -1
			end
			drag.previous = drag.travel
			drag.previousTime = drag.time
			drag.travel = travel
			drag.time = event.time_ms
			stripApply(drag)
		end,
		finish = function(event)
			local drag = stripDrag
			stripDrag = nil
			if not drag or drag.step == 0 then
				if drag then
					stripRelease(drag, true)
				end
				return
			end
			local committed = math.abs(drag.travel) >= drag.threshold
			if not committed then
				-- A flick commits as well: the finger moved far enough
				-- in a short time to cover the threshold.
				local elapsed = event.time_ms - drag.previousTime
				if elapsed > 0 then
					local speed = math.abs(drag.travel - drag.previous) / elapsed
					committed = speed * STRIP_FLICK_MS >= drag.threshold
				end
			end
			if committed then
				stripCommit(drag)
			else
				stripRelease(drag, true)
			end
		end,
	},
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

-- Fullscreen isolation.
--
-- The workspace list is positional: the workspaces above the
-- fullscreened one move one place to the right, so the fullscreened
-- window takes the place right after the one it came from.
--
-- - The origin workspace holds only the fullscreened window: the window
--   is fullscreened in place. The list keeps its shape.
--
-- - The origin workspace holds other windows too: the content of every
--   workspace above the origin moves one id up, the fullscreened window
--   moves into the next id, and the strip advances by one place. The
--   window stays on the monitor it was fullscreened on. The content of
--   the other monitors moves in the background, without an animation
--   of their own.
--
-- The origin workspace is reaped by the compositor when the window
-- leaves it and it was the last window there. Unfullscreening puts
-- everything back: the content moves down again, the window returns to
-- its origin id, and the origin workspace is recreated on its monitor.
--
-- The workspace change animates on the monitor of the fullscreened
-- window. The other monitors change in the background.
--
-- TODO: support the same for vertical setups.
local fullscreenOrigins = {}

-- The windows of a workspace.
local function workspaceWindows(id)
	local ws = hl.get_workspace(tostring(id))
	if not ws then
		return {}
	end
	return ws:get_windows() or {}
end

-- Moves the content of the workspaces from `lowest` to `highest` one id
-- up: the workspace that held the content of id `n` holds it under id
-- `n+1`. The windows move silently, so the change happens in the
-- background, no monitor follows them and no workspace is activated.
--
-- The workspaces above the origin are walked from the top down, so the
-- target of a move is empty when the windows arrive. Only the topmost
-- workspace needs a new id: a silent window move creates it on the
-- focused monitor, so the monitor of the source is focused first.
local function shiftContentUp(lowest, highest)
	local focused = hl.get_active_monitor()
	for id = highest, lowest, -1 do
		local ws = hl.get_workspace(tostring(id))
		if ws then
			local monitor = ws.monitor and ws.monitor.name or nil
			local target = tostring(id + 1)
			local wins = ws:get_windows() or {}
			if #wins > 0 then
				if not hl.get_workspace(target) and monitor then
					hl.dispatch(hl.dsp.focus({ monitor = monitor }))
				end
				for _, win in ipairs(wins) do
					hl.dispatch(hl.dsp.window.move({ workspace = target, window = win, follow = false }))
				end
			end
		end
	end
	restoreFocus(focused and focused.name or nil)
end

-- The other way round: the content of id `n` moves to id `n-1`. The
-- workspaces are walked from the bottom up, so the target of a move is
-- empty when the windows arrive.
local function shiftContentDown(lowest, highest)
	local focused = hl.get_active_monitor()
	for id = lowest, highest do
		local ws = hl.get_workspace(tostring(id))
		if ws then
			local monitor = ws.monitor and ws.monitor.name or nil
			local target = tostring(id - 1)
			local wins = ws:get_windows() or {}
			if #wins > 0 then
				if not hl.get_workspace(target) and monitor then
					hl.dispatch(hl.dsp.focus({ monitor = monitor }))
				end
				for _, win in ipairs(wins) do
					hl.dispatch(hl.dsp.window.move({ workspace = target, window = win, follow = false }))
				end
			end
		end
	end
	restoreFocus(focused and focused.name or nil)
end

-- The strip advances by one place: every monitor shows the next
-- workspace of the list. The monitor of the fullscreened window keeps
-- its own window and follows it; the other monitors change in the
-- background.
local function advanceStrip(monitor, delta)
	for _, mon in ipairs(monitorsByPosition()) do
		if mon.name ~= monitor then
			local ws = mon.active_workspace
			if ws and ws.id > 0 then
				local target = tostring(ws.id + delta)
				if hl.get_workspace(target) then
					hl.dispatch(hl.dsp.workspace.move({ workspace = target, monitor = mon.name }))
				end
			end
		end
	end
end

local function focusMonitorByName(name)
	if name then
		hl.dispatch(hl.dsp.focus({ monitor = name }))
	end
end

hl.on("window.fullscreen", function(w)
	local mode = w.fullscreen
	local origin = fullscreenOrigins[w.address]
	if mode == 2 and not origin then
		local monitor = w.monitor and w.monitor.name or nil
		local id = w.workspace.id
		local others = workspaceWindows(id)
		-- The fullscreened window is the only window of its workspace:
		-- it is fullscreened in place and the list keeps its shape.
		if #others <= 1 then
			fullscreenOrigins[w.address] = { workspace = id, monitor = monitor, shifted = false }
			return
		end
		fullscreenOrigins[w.address] = { workspace = id, monitor = monitor, shifted = true }
		-- The workspaces above the origin move one place to the right.
		shiftContentUp(id + 1, maxWorkspaceId())
		-- The fullscreened window takes the place right after its own.
		focusMonitorByName(monitor)
		if hl.get_workspace(tostring(id + 1)) then
			hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(id + 1), monitor = monitor }))
		end
		hl.dispatch(hl.dsp.window.move({ workspace = tostring(id + 1), window = w }))
		-- The strip advances by one place.
		advanceStrip(monitor, 1)
	elseif mode == 0 and origin then
		fullscreenOrigins[w.address] = nil
		if not origin.shifted then
			return
		end
		-- The window returns to its origin, which the compositor
		-- recreates on the monitor it came from.
		focusMonitorByName(origin.monitor)
		hl.dispatch(hl.dsp.window.move({ workspace = tostring(origin.workspace), window = w }))
		-- The workspaces above the origin move one place back.
		shiftContentDown(origin.workspace + 2, maxWorkspaceId())
		-- The strip goes back by one place.
		advanceStrip(origin.monitor, -1)
	end
end)

hl.on("window.close", function(w)
	fullscreenOrigins[w.address] = nil
end)
