# Migration status

Source of truth for progress. Update at the end of every work session.
Runbook: `docs/HYPRLAND_QUICKSHELL_MIGRATION.md`.

## Batch status

| # | Batch | Status | Gate |
|---|-------|--------|------|
| 1 | NixOS plumbing: greetd, services, GNOME off | done | switched + rebooted 2026-10-12; greetd cmd fixed to start-hyprland |
| 2 | HM Hyprland: config, binds, idle/lock, daemons | done | runtime verified after re-switch (F12, gradient, keybinds) |
| 3 | Quickshell skeleton: theme, bar, dock, toasts | done | live: bar/dock render; notifications fixed (see journal) |
| 4 | Shell completion | in-progress | waves 1-3 committed; wave 4 live-verified (hyprplayground sandbox, gestures, Ctrl+Alt binds, tray centering). Deploy gate pending |
| 5 | Cleanup: dconf trim, package audit | done | trim + live DB reset + audit clean + cliphist/pointerCursor deprecations fixed; build warning-free |
| 6 | Future: custom greeter, dynamic theming, overview | in-progress | greeter built (opt-in pending logout test); overview built (SUPER+TAB + 3-finger-up); palette theming + weather built — all pending Master's switch + runtime gates |

## Decisions

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-10-12 | nixpkgs hyprland + quickshell, no upstream flakes | 0.56.2 newer than flake master label; shared Qt/Mesa tree; cache.nixos.org; escape hatch in runbook |
| 2026-10-12 | gnome-keyring for secrets | ~30-line module, Secret portal backend, libsecret clients (Bitwarden/Chrome/Fractal); KWallet incompatible with org.freedesktop.secrets |
| 2026-10-12 | hyprpolkitagent | HM user service on session target; no Qt/KF deps |
| 2026-10-12 | greetd + tuigreet, stock look | full replacement same generation; fingerprint at login deferred to custom greeter |
| 2026-10-12 | no UWSM in v1 | HM systemd target chain sufficient (verified: hyprland-session BindsTo graphical-session) |
| 2026-10-12 | keep GTK apps + adw-gtk3 + dconf | apps are not the desktop; Qt keeps adwaita platformtheme + adwaita-qt style (no KDE deps) |
| 2026-10-12 | Hyprland configType forced to hyprlang | HM would default to Lua for stateVersion >= 26.05; hyprlang is the documented stable format |
| 2026-10-12 | retTheme as theme source of truth | zed.nix previously derived font sizes from dconf, which died with GNOME; shell reads generated Theme.qml |
| 2026-10-13 | per-workspace float mode is client-side (script + marker files + IPC), no Hyprland rules | 0.56 removed workspaceopt (no-op) and all:float rules; setfloating is a no-op; togglefloating is the only working per-window toggle |
| 2026-10-13 | dock visible only on floating workspaces | Master's call: tiling = no dock; dock returns on float-mode workspaces (SUPER SHIFT F) |
| 2026-10-13 | track active workspace via Hyprland.rawEvent, not focusedWorkspace | quickshell 0.3.1 focusedWorkspace never updates after startup (empirically stale); the event socket is reliable |
| 2026-10-13 | native wifi widget (Quickshell.Networking) replaces nm-applet | full NM bindings ship in quickshell 0.3.1; nm-applet's fallback pixmaps were misaligned and off-theme; SSID + signal strength now render in the bar |
| 2026-10-18 | hyprlock fingerprint via hyprlock-native auth.fingerprint, PAM stack untouched | raw pam_fprintd prompts block password retries for the reader timeout (~30s, journal-verified) when the native manager is off; fallback is Option A: fprintAuth = false (password-only lock screen) |
| 2026-10-18 | border palette via hyprctl eval + hl.config | hyprctl keyword is refused under the 0.57 Lua config; eval is the supported runtime override (verified live before applying) |
| 2026-10-18 | restore empty-workspace reaping via a Hyprland overlay patch | 0.56.2 dropped the explicit reap (markInert has zero callers in the tree) and has no delete dispatcher in the Lua API; query-level inert filtering already existed, so calling markInert at the canonical sites restores the semantics the slide design and pill assume |
| 2026-10-28 | fullscreen isolation focuses the window's monitor before the move | a workspace id that does not exist yet is created on the FOCUSED monitor (resolveWorkspaceStr), so the fresh fullscreen id would land on the wrong screen |
| 2026-10-28 | overview click goes through the compositor focus dispatcher | the generic wlr activate() needs a pointer device and does nothing when the pointer never moved, which is the normal case for a keyboard-opened overview |
| 2026-10-28 | workspace swipe is a Lua-driven continuous gesture, the strip straddle comes from a compositor patch | the built-in gesture slides one monitor only and the renderer draws a workspace only on its own monitor, so a strip across monitors needs both halves patched |
| 2026-10-28 | the strip swipe uses the GNOME 50 model: 400 touchpad units per full screen | the Lua gesture delta is per event, not cumulative, so the old code moved the strip in jerks and never reached the commit threshold |
| 2026-10-28 | a fullscreen window moves to the workspace right after its own and pushes the list | the list is positional, so the content above the origin moves one place up and the origin is recreated in place on exit |
| 2026-10-28 | the CRT is the main display: it sits left of the laptop panel and takes the focus when it appears | the physical layout is CRT left, laptop right, and the automatic layout put the CRT on the wrong side |

## Journal

Newest first.

### 2026-10-28 — strip swipe fixed, fullscreen shifts the list, CRT becomes the main display (agent session, Master live)

- **Context**: Master reported three problems: the 3-finger swipe was
  jerky and could not switch workspaces, a fullscreen window had to land
  on the workspace right after its own, and he wanted to know which
  value GNOME uses for the swipe distance.
- **The swipe bug**: the Lua gesture event carries the delta of ONE
  event. The compositor accumulates it internally
  (TrackpadGestures.cpp: m_currentTotalDelta), but the Lua binding gets
  the raw per-event delta. The old config treated it as cumulative, so
  every update replaced the offset instead of adding to it: the strip
  jumped back and forth and the accumulated travel never passed the
  commit threshold. The config now adds the delta to the travel of the
  drag.
- **GNOME's value**: gnome-shell 50, js/ui/swipeTracker.js:
  TOUCHPAD_BASE_WIDTH = 400 (a full horizontal swipe is 400 touchpad
  units), TOUCHPAD_BASE_HEIGHT = 300, VELOCITY_THRESHOLD_TOUCHPAD = 0.6,
  EVENT_HISTORY_THRESHOLD_MS = 150, GESTURE_FINGER_COUNT = 3. mutter
  feeds the raw libinput swipe deltas to the shell
  (meta-seat-impl.c: notify_swipe_gesture_event). The config now uses
  the same model: 400 units per screen, the pixels per unit are the
  screen width / 400, and a swipe commits when it travels a full screen
  or when it flicks within 150 ms. The old dpi-based factor is gone: it
  could not be measured and the shell has a fixed unit anyway.
- **The fullscreen model**: the workspace list is positional. With
  w1, w2, w3 and a fullscreen in w2:
  - w2 holds only that app: the app is fullscreened in place, the list
    keeps its shape.
  - w2 holds more: the list becomes w1, w2 (the other apps), w3 (the
    fullscreen app), w4 (the old w3 content). The content above the
    origin moves one id up and the app takes the id right after its
    own. Unfullscreen moves it back, moves the content down again and
    restores the origin workspace in the same place.
  The other monitors move in the background (a silent window move
  creates the new id on the focused monitor without activating it), the
  animation stays on the monitor of the app. The vertical case is not
  handled yet; it is marked with a TODO in the config.
- **The reap**: the origin workspace is reaped by the compositor patch
  once the app leaves it. The patch never logged a reap in the live
  session although the debug log is on, so tryReap returns early
  somewhere. The patch now logs the three early returns (not reapable,
  still the active one, still holds windows). The reason shows up in the
  log after the next switch; the fix follows from it.
- **The monitors**: the CRT reports the EDID description "CRT HDMI". It
  now sits at position 0,0 with scale 5/3 and the laptop panel at
  1536,0 with scale 4/3, which puts the CRT left of the laptop. The CRT
  takes the focus when it appears (monitor.added). Hyprland has no
  "preferred monitor" rule in Lua, so this is the available mechanism.
- **Verification**: the luajit -bl syntax gate passes; the patched
  compositor builds; the toplevel build is green. The reap patch was
  regenerated in the same format as its sibling and applies cleanly to
  a pristine Hyprland tree.
- **Gate (Master)**: rebuild and relog. Then: a 3-finger swipe follows
  the finger and commits at a full-screen travel or a flick; a fullscreen
  in a shared workspace gives w1, w2 (others), w3 (the app), w4 (the old
  w3) and the strip advances, and unfullscreen restores the old list;
  the CRT appears left of the laptop and takes the focus when plugged
  in. The reap reason is in the log after the fullscreen round trip.
- **Open**: does Hyprland keep the configured position of a monitor when
  it is the only one? The laptop alone may sit at x = 1536. The
  vertical swipe case is not implemented.

### 2026-10-28 — finger-tracked workspace strip: compositor patch + 1:1 gesture (agent session, Master live)

- **Context**: Master wanted the GNOME-style workspace swipe - the
  content follows the finger one to one, and the strip moves across the
  monitors as one band.
- **Why a patch was needed**: the built-in unified swipe gesture slides
  the workspace of ONE monitor (m_monitor is the focused monitor), and
  the renderer draws a workspace only on the monitor that owns it
  (shouldRenderWindow: PWINDOWWORKSPACE->m_monitor == pMonitor). A
  strip that slides across monitors needs both halves.
- **The patch** (overlay/patches/hyprland-0.56.2-strip-swipe.patch):
  Lua bindings hl.ws.set_render_offset / set_alpha / force_render /
  reset / animate_render_offset, plus two renderer rules - one that
  lets a force-rendered workspace be drawn on a monitor that does not
  own it when its offset box touches that monitor, and one that renders
  such a foreign workspace in the monitor's pass. The reap patch stays
  a separate file.
- **The 1:1 factor**: px_per_unit = 25.4 * monitor.width / (dpi *
  monitor.physical_width), computed at runtime from the physical size
  of the monitor (the Lua monitor exposes the logical width in pixels
  and physical_width in millimetres). The dpi is the one input the
  session cannot read:
  - libinput has no public API for the resolution (checked the 1.31.3
    header: libinput_device_get_dpi does not exist)
  - the device reports none either - the kernel properties blob of the
    ASUE1305 touchpad is 2 bytes, so there is no axis resolution
  - libinput assumes a 69 mm wide touchpad in that case
    (tp_init_default_resolution), which for a typical raw range lands
    on about 1000 dots per inch
  The config therefore uses 1000 dpi, and a monitor without a physical
  size falls back to the compositor's own convention (a swipe distance
  of one full screen). The planned Aquamarine patch was dropped: there
  is no value for it to read, and one pinned patch less is one risk
  less.
- **The gesture**: the 3-finger horizontal gesture is continuous now
  (start/update/finish). The gesture delta is cumulative, the offset of
  every workspace of the strip is delta.x * px_per_unit (a rigid band),
  and the release commits the step through the existing slideStrip path
  when the travel passes 15 % of the screen or the finger flicked
  (150 ms). Below the threshold the content slides back through
  animate_render_offset.
- **Known limits**: the commit re-assigns the workspaces between the
  monitors and the compositor animates that move, but the window layout
  of a moved workspace is recalculated at the switch - so the drag
  previews the strip position, not the window layout. The incoming
  workspace is not previewed either: it usually does not exist yet, so
  the drag shows the strip's own content moving.
- **Verification**: luajit -bl gate on the config; the patched
  compositor builds (the reap marker and the new bindings are both in
  the binary); the toplevel build is green; a nested run of the new
  binary with the generated config loaded the Lua config with no
  config errors, and a scratch probe in it called all five new
  bindings. The nested gate is unsafe while a session is live - it
  falls back to the X11 backend, opens the DRM and shows its error
  overlay on the live screen; the runbook now says so.
- **Gate (Master)**: rebuild and relog - the config needs the patched
  compositor, hl.ws does not exist in the old binary. Then: a 3-finger
  horizontal swipe moves the strip with the finger, crosses the
  monitor border, commits on a long stroke and slides back on a short
  one.

### 2026-10-28 — fullscreen isolation: stay on the window's monitor, release the temp workspace (agent session, Master live)

- **Context**: Master reported an empty workspace that lingered after
  leaving fullscreen, and a fullscreen that could land on the wrong
  screen. Two compositor rules explain both.
- **Rule 1 (focused monitor)**: a workspace id that does not exist yet
  is created on the FOCUSED monitor (resolveWorkspaceStr). The fresh id
  used by the fullscreen isolation was therefore created on whichever
  screen held the keyboard focus, not on the window's screen.
- **Rule 2 (reaper skip)**: the reap patch never reaps a workspace that
  is still a monitor's active one (tryReap returns early when
  PMONITOR->m_activeWorkspace == m_self). The temporary workspace was
  left active by the fullscreen window, so the debounced sweep could
  never kill it — that was the lingering empty workspace.
- **Fix**: the fullscreen handler now records the origin workspace AND
  the window's monitor, focuses that monitor before the move (so the
  fresh id is created there), and on exit focuses the origin monitor
  and moves the window back. The move follows the window, so that
  monitor switches to the origin workspace and the temporary workspace
  stops being active — the 750 ms sweep then reaps it.
- **Verification**: the luajit -bl syntax gate passes and the toplevel
  build is green (HM generation rebuilt). The Lua API used was checked
  in the 0.56.2 source (window.monitor gives a CLuaMonitor with .name;
  the focus dispatcher takes a monitor selector, the same idiom
  settleMonitor already uses). The live fullscreen round trip rides
  Master's gate.
- **Still open**: the 1:1 finger-tracked workspace swipe with the
  cross-monitor strip (Master's option 4b: a compositor patch plus a
  gesture-driven drag). The runtime factor is derived:
  px_per_unit = 25.4 * monitor.width / (dpi * monitor.physical_width),
  with the touchpad dpi as the only input the session cannot reach on
  its own (libinput cannot open the devices while the compositor holds
  them, and udev exposes no resolution).

### 2026-10-28 — overview click: focus through the compositor, not through wlr (agent session, Master live)

- **Context**: clicking an overview card did nothing under Hyprland.
- **Root cause**: the card click called the generic toplevel
  activate(), which goes through wlr_toplevel.cpp:85 and returns early
  when display->lastInputDevice() is null — the normal case for a
  keyboard-opened overview, where the pointer never moved.
- **Fix**: under Hyprland's Lua config the card click now dispatches
  hl.dsp.focus({ window = "address:0x<addr>" }) over the IPC. The
  compositor focus action explicitly changes the workspace
  (ConfigActions.cpp), which is what a click means. The generic
  activate() stays as the fallback for GNOME and for a legacy Hyprland
  config.
- **Address lookup**: the generic toplevel carries no address (checked
  in the quickshell source), so the address is resolved through the
  Hyprland namespace: a Hyprland toplevel points at the same wayland
  handle as the generic one, and that handle identity is the join key.
  The handle address is hex without the 0x prefix while the selector
  wants the prefix, so the Overview adds it.
- **Discriminator**: Hyprland.usingLua comes from the IPC status
  (configProvider == "lua"), so it is false under GNOME and under a
  legacy Hyprland config.
- **Verification**: the built Overview loads in a live quickshell
  instance against the running compositor with zero warnings; a scratch
  test proved the join key against the live session — 7 of 7 toplevels
  matched and usingLua was true; the Lua-form dispatch returns ok over
  the IPC while the legacy form fails with the documented syntax error.

### 2026-10-27 — GNOME interlude: dual-desktop fix, notification center, quick settings, media + power-profile widgets (agent session, Master on GNOME)

- **Context**: Master switched Taihou back to GNOME (toggles flipped
  in the working tree, his call; also restored the pre-migration
  deskEnv-config.nix with the gnome-shell extensions). This session
  prepared the stack for going back.
- **Dual-desktop fix (critical pre-flip bug)**: the restored
  deskEnv-config.nix gated gtk/qt/dconf/xresources on the GNOME
  desktop option — the exact trap the runbook warns about — so the
  next Hyprland flip would have silently killed GTK theming, icons,
  fonts and prefer-dark for the surviving apps. App-facing blocks are
  now unconditional; only the gnome-shell extensions and their
  support packages stay GNOME-gated. The qt style returns to
  adwaita-qt (locked decision 8; the restored file had breeze, which
  pulls KDE Frameworks). The GNOME Shell dconf keys stay for the
  GNOME side; they are inert under Hyprland.
- **Notification center** (GNOME parity): NotifStore singleton (a
  real ListModel — safe against the 0.3.1 Repeater-crash; entries are
  plain copied fields, never the Notification wrapper) + NotifCenter
  popover (clock click, SUPER+N, ipc target `notifcenter`), unread dot
  on the clock, Clear button, click-a-card-to-drop, 20-entry cap.
- **Quick settings panel** (SUPER+S, ipc `quicksettings`): volume
  slider (Pipewire volume is writable per the 0.3.2 qmltypes —
  `setAverageVolume`), brightness slider (brightnessctl, debounced
  writes), wifi (nmcli radio), bluetooth (adapter.enabled), night
  light, power profile and caffeine toggles, lock + logout actions.
  State is re-probed on every open. Panels arbitrate through
  NotifStore.openPanel — notifcenter and quicksettings can never be
  mapped at the same time. Sliders are hand-built (the shell
  deliberately avoids QtQuick.Controls).
- **Bar widgets**: Media (Quickshell.Services.Mpris, first playing
  player wins, click toggles, hidden with no player) and PowerProfile
  (powerprofilesctl probe + optimistic cycle + 60s re-probe).
  power-profiles-daemon added to modules/hyprland.nix systemPackages
  so powerprofilesctl is guaranteed on PATH.
- **Night light** (GNOME parity): Hyprland 0.56.2 has no built-in
  (source-checked), so a gammastep user service (hyprland-gated)
  runs on the sun schedule at the weather-pinned location (Lima,
  6500:4000K), WantedBy graphical-session — auto-on per session, the
  quick settings toggle stops/starts it. Opt-out: drop the WantedBy.
- **Screenshots save to disk** (GNOME parity): both screenshot
  scripts write ~/Pictures/Screenshots/Screenshot from <ts>.png AND
  copy to the clipboard; notify carries the path.
- **Icon flatten bug found + fixed (latent since batch 4)**: the
  adwaita recolor script ran `chmod -R u+w` AFTER the devices→status
  flatten, but `cp -r` preserves the store's read-only modes on the
  copied DIRECTORIES, so the mv silently failed behind `2>/dev/null`
  and the devices set never merged (nothing noticed — every icon used
  until now lived in status). The media/quick-settings icons exposed
  it. Now: chmod first, flatten second, and the actions set joins the
  copy (media-playback-*, system-log-out live there). Verified: the
  rebuilt recolored set contains all six previously-missing icon
  names.
- **quickshell is 0.3.2 in the current lock** (was 0.3.1): qmltypes
  re-verified for every new surface used (Mpris players/values,
  isPlaying, togglePlaying; Pipewire volume write). The old
  workarounds (tracked notifications, imperative toast creation,
  rawEvent workspace tracking, palette fish-loop) are still in place
  and still valid until the live gate says otherwise.
- **Flake gotcha (bit us here)**: a dirty git tree only feeds the
  flake source from the git INDEX — new files must be staged before
  eval/build or they are silently absent. First live-load test failed
  purely on this (new QML files missing from the built shell dir).
- **Verification**: hyprland.lua passes a luajit -bl syntax parse;
  HM activation package evals with the GNOME toggles AND builds with
  the Hyprland toggles; built shell live-loaded under GNOME
  (quickshell -p): "Configuration Loaded", zero QML type errors, zero
  icon warns, only the expected environment artifacts (notification
  bus owned by GNOME Shell, layershell/mutter warnings,
  test-env PATH misses brightnessctl — on PATH in the real session).
  Data paths that need the real compositor (panel probes, media,
  notifications) ride the switch gate below.
- **Keyboard layout switcher (es <-> us)**: the 0.56.2 Lua API does
  not expose the legacy switchxkblayout dispatcher (source-checked),
  so the toggle flips `input:kb_layout` wholesale through a runtime
  `hl.config` — the option carries the REFRESH_INPUT_DEVICES bit,
  which schedules `setKeyboardLayout()` and reconfigures keyboards
  live (chain verified in the source: isDynamicParse() is true from
  bind closures and from hyprctl eval). SUPER+K toggles in-process
  (hl.get_config reads the live value, so no drift); the new bar
  widget (ES/EN, click to toggle) drives the same flip via
  `hyprctl eval` and tracks state through the activelayout rawEvent
  (posted by setKeyboardLayout with the layout display name) plus a
  getoption probe at shell start. Runtime flips do not persist: a
  reload or relog returns to the es boot default. The luajit -bl
  syntax gate earned its keep during the edit (caught a # comment in
  the Lua input block before anything built).
- **Gate (Master, when switching back)**: flip the toggles, rebuild,
  relog; then the consolidated checklist: reap v2 (empty-ws slide
  direction + ws gone ≤1s), quickshell up at login with the pill
  (env-race fix), overview, palette borders, weather, hyprlock ~3s
  retry, clock click + SUPER+N (center, dot, clear), SUPER+S
  (sliders + toggles live-apply), media widget with a player, power
  profile cycles, night light follows schedule + toggle works,
  screenshots land in ~/Pictures/Screenshots, SUPER+K and the bar's
  ES/EN pill flip the keyboard layout live (typing follows).

### 2026-10-19 (evening) — reap v2 (animation-safe debounce) + quickshell env-race fix (agent session, Master at machine)

- **v1 live regression**: with the first reap running, swiping left
  through an empty workspace made the incoming animation arrive from
  the wrong side on the right monitor. Root cause: v1 reaped in
  changeWorkspace's demotion block, BEFORE the ANIMTOLEFT
  computation — markInert sets WORKSPACE_INVALID (-1), so the
  `new > old` term flips and the direction inverts whenever the
  demoted workspace is empty. The slides' pass choreography (demote
  on eDP → pass right → settle on HDMI) also had the empty workspace
  reaped under its feet mid-slide.
- **v2**: the switch itself never reaps. A 750ms debounced sweep,
  re-armed on every changeWorkspace, calls tryReap across all
  workspaces once the switch burst (slides, animations, passes)
  settles. The window hooks (onUnmap / moveToWorkspace, deferred)
  stay. Patch updated in place; the overlay comment documents why
  the switch must not reap.
- **Test-methodology retraction**: the nested self-test used to
  "verify" v1 (and re-run for v2) is invalid for this bug — a bare
  nested session has none of the reference holders that keep
  emptied workspaces alive on the real desktop (no gesture state,
  no animation config, no windows), so demoted empties
  self-destruct through the refcount instantly, natively, in any
  build. Both nested runs measured the environment, not the patch;
  v1's "PASS" was vacuous. Verification for v2 is the live gate
  below.
- **Compositor exit crash (pre-existing)**: 2026-10-19 20:04
  SIGSEGV in Aquamarine's DRM-backend destructors inside
  __run_exit_handlers — a shutdown-time crash on logout, same
  lineage as the Oct 14/17 dumps, on the pre-patch binary; not the
  reap patch. Watch for upstream Aquamarine fixes.
- **Quickshell env race (the dead pill)**: after the compositor
  restart, quickshell spawned before Hyprland's start hook
  exported HYPRLAND_INSTANCE_SIGNATURE; the unit env is frozen at
  spawn, so every Hyprland-backed widget (the workspace pill
  included) stayed dead. Immediate fix: the signature was already
  in the user manager env — restarting quickshell restored the
  widgets (done 2026-10-19 22:53). Permanent fix: the quickshell
  unit ExecStart now waits for the signature and pulls the live
  activation environment at exec time — replaces the wayland-1 pin
  and the socket-only wait, and also covers the 2026-10-14
  start-limit crash path.
- **Gate (Master)**: rebuild + relog onto v2, then live: swipe left
  through an empty mid-strip workspace — animation direction must
  be correct on both monitors; close the last window on a workspace
  and move away — `hyprctl workspaces` drops it within ~1s; the
  pill follows.

### 2026-10-18 (night) — workspace zombies: patched Hyprland's missing empty-workspace reap (agent session, Master at machine)

- **Bug**: emptied workspaces never truly closed on moving away; the
  bar pill then showed phantom pills and holes. Root cause found in
  the 0.56.2 source: destruction became refcounted in the 0.56
  rewrite, and `CWorkspace::markInert()` — the logical-death
  primitive, with inert-filtering already wired into every workspace
  query — has zero callers in the entire tree. The old explicit reap
  was dropped, the Lua API has no delete dispatcher
  (workspace.*: rename, change_id, move, swap_monitors,
  toggle_special), and emptied workspaces linger indefinitely
  (verified live: a created-empty ws survived focus-away,
  monitor-focus events and minutes of idle; swipe-away deaths came
  only from gesture-state refs dropping, which is why swipes
  sometimes reaped and numeric/pill moves never did).
- **Fix — Hyprland overlay patch**
  (`overlay/patches/hyprland-0.56.2-reap-empty-workspaces.patch`,
  +25 lines): a new `CWorkspace::tryReap()` — markInert when empty,
  non-special, non-persistent, id > 0 and not any monitor's active —
  called at the canonical sites: `CMonitor::changeWorkspace` (the
  demoted old active) and `CWindow::onUnmap` / `moveToWorkspace`
  (deferred via doLater once the window's target drains). Wired via
  overlay/fixes.nix on prev.hyprland. An interim pill-filter approach
  was implemented first and reverted in favor of the patch.
- **Verification**: patched 0.56.2 built from the exact nixpkgs
  source + patch (clean compile). Nested self-test (in-config
  hl.timer script — nested instances get no IPC socket): focus ws 2,
  dump, focus back, dump. First dump showed the demoted empty ws 1
  already reaped; second dump showed ws 2 gone, with a fresh ws 1 on
  focus-back. PASS.
- **Nested-test gotcha**: the test instance ignored hl.dsp.exit()
  and kept running (orphaned when the nix wrapper returned), owned
  wayland-2, and its startup exported that socket into the systemd
  user activation environment — so systemd-launched apps targeted a
  dead display. Cleanup: kill the process, remove its
  $XDG_RUNTIME_DIR/hypr/<sig> dir, then
  dbus-update-activation-environment --systemd with the real
  session's WAYLAND_DISPLAY + HYPRLAND_INSTANCE_SIGNATURE (read off
  the real compositor via /proc). Future nested runs must not be
  allowed to outlive the test, and the real env should be re-imported
  afterwards regardless.
- **Gate (Master)**: rebuild + relog (the running session keeps its
  existing zombies until then), then: close the last window on a
  workspace and move away — gone from `hyprctl workspaces` and the
  pill immediately; swipe back — a fresh empty ws; ids stay packed.

### 2026-10-18 (evening) — hyprlock unlock stall + frozen border palette, both fixed (agent session, Master at machine)

- **hyprlock post-failure unlock stall (Option B applied)**: after one
  wrong password, later attempts took 30–56s (journal 12:50–12:52),
  and hyprlock 0.9.6 aborted its auth thread once (coredump
  2026-10-16: assert in a CHyprlock::run lambda on a worker thread).
  pam_fprintd sits first in the hyprlock PAM stack (injected because
  services.fprintd is on; the service was left at `{ }` defaults) and
  its finger-wait leaked into password retries, because hyprlock's
  native fingerprint manager — which cancels the verify on typing —
  was off. Fix in programs.hyprlock: `auth.fingerprint.enabled = true`
  plus removal of four dead options the 0.7-era config still set
  (disable_loading_bar, grace, no_fade_in, font_size — loading bar
  removed in 0.8.0; grace and fade-in are --grace/--no-fade-in CLI
  now). PAM stack untouched. Fallback if the native path misbehaves:
  Option A — security.pam.services.hyprlock.fprintAuth = false
  (password-only at the lock screen; fingerprint stays at the
  greeter).
- **Window border palette frozen**: the quickshell palette reader
  still called `hyprctl keyword`, which 0.57 refuses under the Lua
  config ("keyword can't work with non-legacy parsers. Use eval.",
  HyprCtl.cpp dispatchKeyword). The bar (in-process JSON) kept
  updating; the border silently never did — same migration class as
  the hyprlock options. Fix: the two calls became `hyprctl eval
  hl.config({ general = { col = { ... } } })`. Verified live on the
  running session before applying (red flash test, then the palette
  applied via eval: getoption shows b2faba73 / aa19120c). The 10s
  poll re-apply stays, so borders self-heal after Hyprland reloads.
  hyprland.lua header comment corrected to match reality (the
  palette reader does it, not update-palette, and via eval).
- **Verification state**: nix eval of the full HM activation package
  passes with all edits (no build: flake.lock is modified mid-update,
  so building/switching is Master's call against whatever the lock
  says at switch time). The live session already carries the palette
  borders via eval; they persist until the next config reload.
- **Gate (Master)**: rebuild + relog, then: wrong-password retry at
  hyprlock reports in ~2–3s and the lock screen shows the
  fingerprint ready message; `hyprctl getoption
  general:col.active_border` follows palette.json within 10s of a
  wallpaper change. Watch coredumpctl for hyprlock for a few days.

### 2026-10-14 (night, part 2) — Lua config migration (0.57 removes .conf) (agent session, Master at machine)

- **Migrated to the Lua configuration** (`users/retblast/hm/hyprland.lua`,
  ~130 lines): monitor, input, cursor, general, decoration, misc via
  `hl.config`; bezier + animations via `hl.curve`/`hl.animation` (the
  hyprlang 4-number form maps to points pairs); all binds via
  `hl.bind("MODS + KEY", hl.dsp.*)` (exec_cmd, window.close/float/
  fullscreen/drag/resize/move, focus, exit); the workspace 1-10 binds
  became a Lua for-loop; gestures via `hl.gesture` (workspace action +
  Lua-closure actions for the overview toggle and cyclenext); the two
  exec-once commands run in `hl.on("hyprland.start")` (no exec_once in
  the Lua API; both commands are idempotent). HM's own systemd
  start/shutdown hooks still render (session-target wiring preserved).
  HM wiring: `configType = "lua"`, `settings = {}` removed, body via
  `extraConfig = builtins.readFile ./hyprland.lua`.
- **Verification journey** (each finding is a gotcha): `--verify-config`
  reported "config ok" on a CORRUPTED file — it does not execute Lua
  configs, so it is NOT a gate for Lua. The nested-run gate works but
  the config error only shows on the ERROR OVERLAY (not in the
  hyprland.log); Master read the overlay. Final state: live nested
  0.56.2 session, no error overlay. Also: `hl.config` option keys are
  dash-normalized to underscores (tap_to_click — ConfigManager.cpp:1139);
  matugen-style nested tables not needed here; the first nested attempt
  fought the real compositor for the eDP-1 output (libseat errors) —
  strip `hl.monitor` for nested tests. The binds-registered count could
  not be checked over IPC (nested instances get no socket under this
  session's logind) — functional bind testing happens after the switch.
- **Gate (Master)**: switch + relogin. Rollback: revert this commit
  (configType back to hyprlang + the old settings attrset restored).

### 2026-10-14 (late night) — polish pass: login race, dock minimize (agent session, Master at machine)

- **Login race fixed**: the 17:40 journal showed the old wl_display crash
  return — the quickshell unit started before Hyprland created its socket
  (graphical-session.target races the compositor), hit quickshell's
  crash-loop guard, and the desktop spent part of the login without a
  shell (recovered at 17:40:47, recovery path unclear). Fix: an
  ExecStartPre script waits up to 20s for the WAYLAND_DISPLAY socket
  before exec. Unit verified in the generated files.
- **Dock minimize fixed**: `Hyprland.dispatch("minimize")` — the dock's
  click-on-focused-app action — has no dispatcher in 0.56 (zero hits in
  the 0.56.2 source), so the click silently did nothing. The dock now
  uses the wlr-foreign toplevel: focused click sets `t.minimized = true`
  (writable, protocol-level), non-focused click unminimizes then
  `activate()`s.
- **Lua config migration: recommended DEFER.** The legacy hyprlang path
  is fully working and verified (including the new gesture keyword); the
  format is invisible in daily use; the migration costs a full config
  re-verification pass for zero daily-use gain. Revisit when upstream
  signals hyprlang deprecation or a Lua-only feature (the hl.gesture
  live API) becomes wanted; schedule as its own task with the
  hyprplayground for verification.
- Untracked repo files left as-is (Master's notes: SF stem-darkening
  investigation, thermald/DPTF analysis, thermal-conf.xml).
- Hyprland log this boot: zero warnings or errors.

### 2026-10-14 (night) — palette reaches Hyprland borders; dock dots fixed (agent session, Master at machine)

- **Window borders follow the palette**: Theme.qml's palette reader now
  applies `general:col.active_border` (primary at b2 alpha) and
  `col.inactive_border` (background at aa) via
  `Quickshell.execDetached(hyprctl keyword ...)` on every palette read —
  10s poll cycle, so reloads self-heal. Verified live: after the hourly
  wallpaper rotation regenerated the palette (new primary #e0c56d), the
  running instance applied it and `hyprctl getoption` shows the border
  set. Hyprland prints border colors as AARRGGBB (alpha first) in its
  "custom type" output. `hyprctl keyword` takes exactly ONE option per
  call — a combined call parses the second option as an extra gradient
  stop (found live).
- **Dock running-dots fixed**: the indicator source was
  `Hyprland.toplevels.values` + `lastIpcObject.class` — the same
  quickshell-0.3.1 Hyprland-IPC integration that gave the stale
  focusedWorkspace; live classes (firefox, org.gnome.Ptyxis) matched the
  favorites exactly, so the source was the problem. Dock now filters
  `ToplevelManager.toplevels.values` on `appId` (proven by the
  overview). Lands with the next switch.

### 2026-10-14 (evening) — incident: overview ate the desktop; root cause + fix (agent session, Master on TTY)

- **Incident**: after the switch + relogin, the mouse moved the cursor but
  nothing reacted — no hover, no focus, no clicks. Cause: the Overview's
  `property bool visible` SHADOWED PanelWindow's real `visible` property
  (QsWindow exposes visible — qmltypes-confirmed), so the window's
  mapping was never controlled and the overview mapped fullscreen at
  creation, eating all pointer input on the output. The rig tests never
  caught it: the toggle-on mapping was observed but attributed to the
  toggle, and the toggle-off direction was never actually verified (the
  verifying call kept dying to the pgrep self-match trap).
- **Fix**: Overview.qml drops the custom property; the window's own
  `visible: false` + IpcHandler writes drive mapping directly.
- **Verification this time covered all three states** on a clean single
  instance: start = no overview layer; toggle = mapped; toggle again =
  unmapped. Test-harness lessons (both now runbook gotchas): never grep
  layers by exact geometry (stacked instances' exclusive zones change it
  — the overview rendered at 0 180 1536 500 under five accumulated test
  instances while the grep hunted 0 36 1536 868); count instances before
  asserting single-instance behavior; "ok" from `hyprctl dispatch exec`
  is the dispatch ack, not the spawned command's output.
- **Recovery for Master**: the deployed generation still has the broken
  Overview — the quickshell service stays stopped (desktop usable, no
  bar). Run `sudo nixos-rebuild switch --flake .#Taihou` from the TTY,
  then RELOGIN (a relogin, not just a service start: ~17 leaked pid -1
  layer surfaces from the incident and the test pile only clear on
  relogin, and leaked exclusive zones would keep squeezing the real
  bar/dock). After the relogin everything pending lands: fuzzel border +
  prompt, tray centering, gesture persistence, dconf trim, overview
  (fixed), palette theming, weather.
- The greeter remains opt-in (customGreeter.enable, default off) and was
  not part of this incident.

### 2026-10-14 (afternoon) — batch 6: dynamic wallpaper palette + weather widget (agent session, Master at machine)

- **Dynamic wallpaper->palette theming**: matugen (4.2.0, in user
  packages) generates the Material You dark scheme from the current
  wallpaper. New `update-palette` fish script (awww query -> matugen
  --prefer saturation -j hex -> $XDG_CACHE_HOME/quickshell/palette.json),
  called by wallpaper-rotate after every img and by an exec-once at
  login (4s sleep so the daemon restores first). Theme.qml gains a
  runtime layer: a long-lived fish loop re-reads the file every 10s,
  SplitParser + JSON.parse, and the color tokens (bg/bgAlt/fg/fgDim/
  accent/border) fall back to the static retTheme values while the file
  is absent. Mapping: background->bg, surface_container_high->bgAlt,
  on_background->fg, on_surface_variant->fgDim, primary->accent,
  outline->border; urgent stays static. The dynamic foreground stays
  light by construction (dark-scheme on_background) — required because
  the recolored symbolic icons are baked with the static foreground at
  build time.
- **Weather widget** (`widgets/Weather.qml`): wttr.in %C;%t one-liner
  (no API key, IP geolocation), 30-min self-loop fetch, condition words
  mapped to adwaita weather icons, hidden until the first successful
  read. Bar right side: weather, volume, battery, network, caffeine,
  bluetooth, tray.
- **Verified in the rig**: static fallback with no palette file; pylons
  palette (#111318/#e2e2e9/#acc7ff) applies live within 10s of the file
  appearing; garish hand-made palettes apply at startup; weather curl
  returns "Sunny;+19°C" and the shell loads with 0 errors.
- **quickshell 0.3.1 dynamic-data findings** (see runbook): FileView
  watchChanges and adapter reload() are dead; restarting a finished
  Process from a Timer does not re-fire its collector; the working
  pattern is one long-lived Process with a fish loop emitting one line
  per read. matugen's --json output nests every token as
  colors.<token>.dark.color (mode inside the token).

### 2026-10-14 (morning) — batch 6 started: custom Quickshell greeter built (agent session, Master awake)

- **App overview implemented** (`shell/Overview.qml`): fullscreen overlay
  (WlrLayer.Overlay, exclusive keyboard) with a GridView over
  `ToplevelManager.toplevels` (real QAbstractListModel — the Repeater
  crash gotcha does not apply) and live `ScreencopyView` thumbnails
  (capture only while visible; letter placeholder when the compositor
  refuses per-window capture). Click focuses via `Toplevel.activate()`,
  close button and Esc close, backdrop click closes. Toggled through
  `IpcHandler target: "overview"` (Quickshell.Io import needed — it is
  NOT in the root module): SUPER+TAB and the new
  `gesture = 3, up, dispatcher, exec, ... overview toggle` (GNOME's
  overview swipe). Verified in the rig: 0 QML errors, layer maps
  fullscreen on toggle and unmaps on toggle-off.
- **Greeter implemented** (`modules/quickshell-greeter/`): shell.qml +
  Greeter.qml (fullscreen PanelWindow: clock, date, fixed user, password
  field, status line) + Theme.qml (palette duplicated from retTheme —
  the greeter runs as the "greeter" user and cannot read the user's
  generated Theme.qml) + qmldir. Auth flow is Greetd-only: createSession
  -> authMessage prompts (password AND fingerprint prompts arrive here) ->
  respond -> readyToLaunch -> launch(["start-hyprland"]). No PamContext —
  greetd owns the PAM stack. A test-mode status shows when the greetd
  socket is absent, so the UI loads harmlessly outside the greeter
  session.
- **Wiring** (modules/hyprland.nix): new option
  `localModule.hyprland.customGreeter.enable` (default FALSE — a broken
  greeter means a locked-out login screen; tuigreet stays the deployed
  default). When on: greetd runs `cage -s -- quickshell -p
  <greeterConfig>` and `security.pam.services.greetd.fprintAuth = true`
  (pam_fprintd asks for a finger, falls through to the password). The
  gate keeps tuigreet's PAM stack byte-identical until Master opts in;
  nix laziness keeps the greeter config out of the closure entirely
  while off.
- **Verified**: toplevel green; greeter QML loads in a live test instance
  with zero errors (fullscreen layer renders; test-mode status shown).
  First load caught two QML import bugs (Theme.qml needs BOTH QtQuick
  for `color` and Quickshell for `Singleton`).
- **Master gate (opt-in, with recovery)**: set
  `localModule.hyprland.customGreeter.enable = true;` in
  machines/Taihou/default.nix, switch, log out. Fingerprint scan or
  password both log in. If the greeter ever fails to appear: Ctrl+Alt+F2,
  log in on the TTY, flip the option back, rebuild. The real login-flow
  test (fingerprint + session start under cage) happens at logout.

### 2026-10-14 (early morning) — batch 5 done: dconf trim, package audit, deprecations (agent session, Master awake)

- **dconf trim**: deskEnv-config.nix keeps only app-facing keys
  (org/gtk file-chooser, nautilus, wm/preferences button-layout,
  desktop/interface fonts+color-scheme). Everything consumed only by
  GNOME Shell / gnome-settings-daemon or by removed apps went:
  dash-to-dock, vitals, caffeine, azwallpaper, lockkeys, shell
  favorites/app-switcher/weather, media-keys custom binds (now Hyprland
  binds), search-providers, power, mouse, mutter, datetime, locale,
  location, sound's allow-volume-above-100-percent (gsd-consumed;
  pamixer does not read dconf), and keys for apps that are not
  installed (epiphany, Resources, Console, TextEditor,
  gnome-system-monitor).
- **Live DB cleanup**: a dconf trim only changes the declarative source —
  stale keys stay in the user DB until reset. Ran
  `dconf reset -f` on the 14 dead trees plus the single sound key;
  `dconf dump /` now shows exactly the app-facing residue (kept keys
  plus app-owned trees: blueman, file-roller, Fractal, papers, Ptyxis).
- **Package audit**: users/retblast/pkgs/* and modules/hyprland.nix have
  no GNOME-desktop leftovers — the only GNOME apps are the intentional
  keeps (nautilus, ptyxis, file-roller, papers). No package changes.
- **Deprecations fixed**: cliphist `systemdTarget` -> `systemdTargets`
  (list), `home.pointerCursor.enable = true` explicit. Eval output is
  now warning-free apart from the git-dirty note.
- Master confirmed the gcr/keyring unlock prompts work under Hyprland —
  the journal note from 2026-10-13 about the missing prompter UI is
  resolved; SSH signing path is whole again.

### 2026-10-13 (late night) — hyprplayground sandbox, gestures, GNOME-parity binds, tray centering (agent session, Master at machine)

- **hyprplayground** (new fish script, on PATH after the next switch):
  `hyprplayground` copies the deployed Hyprland + quickshell configs into
  /tmp/hyprplayground as writable files (hypridle/hyprlock as inert
  reference copies), appends a Ctrl+Alt+Q quit bind to the copy, boots a
  nested Hyprland (0.56 socket handover), opens a ptyxis with the README
  inside the sandbox, and starts a sandbox quickshell against the sandbox
  socket. Edits there never touch the real session; quickshell reloads
  live. On exit (including SIGKILL of the sandbox compositor) the script
  restores WAYLAND_DISPLAY in the systemd/D-Bus env — verified live end
  to end, env came back to wayland-1 and both sandbox processes died.
  `--reset` re-copies from the deployed generation.
- **Touchpad gestures à la GNOME**: two dead ends found live. The old
  `gestures { workspace_swipe }` block is gone in 0.56 (config error
  overlay), and `bind = , swipe:3:left, ...` is a silent trap — the bind
  parser registers it as an ordinary bind on a keysym that never exists
  ("ok", listed in `hyprctl binds`, never fires). The real syntax is the
  dedicated `gesture` keyword (verified against the 0.56.2 source,
  `CConfigManager::handleGesture`): shipped `3, horizontal, workspace`
  (1:1 GNOME-style drag) + 4-finger focus cycling via
  `dispatcher, cyclenext[, prev]`. Probed live with
  `hyprctl keyword gesture` ("ok" ×3, gestures work on the running
  session immediately), then gated with `Hyprland --verify-config`
  ("config ok"). The overview swipe still waits for an overview
  (batch 6); hyprgrass still does not build against this pin.
- **Ctrl+Alt+Left/Right** now switch workspaces, **Ctrl+Alt+Shift+**
  moves the focused window (GNOME parity).
- **Tray icons were 8px high**: the Tray Row's delegates were 20px tall
  while every other right-side widget is barHeight (36px), and the Row
  positioner top-aligns children. Delegates are now barHeight with the
  icon centered inside. The first version of that edit also hit the
  documented `import ".."` gotcha (used Theme without the import ->
  "ReferenceError: Theme is not defined" per delegate, tray broken);
  fixed and this time live-load verified through the /tmp rig before
  committing.
- **Fuzzel right border disappeared at fractional scaling**: fuzzel
  1.15 with dpi-aware=yes/auto at scale 1.25 computed a 322-logical-px
  window -> 402.5 buffer px; the rounding drops the last column, which
  is the border. First fix attempt used `dpi-aware = false` — **the ini
  only accepts auto|yes|no; true/false are silently ignored** (geometry
  identical, no error). Real fix: `dpi-aware = "no"`. Also found and
  fixed: `prompt = ""` threw "key/value pair has no value" on every
  launch (fuzzel ini has no empty values; a quoted single space
  `prompt=" "` gives the visually-empty prompt). Verified from the
  generated ini via `fuzzel --config <file>`: 0 errors, geometry
  changed 322x312 -> 337x306 (scale-1 path active). No restart of any
  kind needed — fuzzel reads the ini on every launch. Visual border
  confirmation pending (Master).
- **Keyboard/accents — verified, not yet solved**: `kb_layout = es` is
  applied (getoption set:true, active keymap "Spanish", deployed config
  line 80), no IME env vars anywhere (manager env, repo, no ibus). The
  accent failure must be mechanism-level; diagnostic question open to
  Master: what is pressed and what appears (dead key ´ vs RightAlt — the
  keyd remap turns a rightalt tap into `>`, which eats the US-intl style
  RightAlt+letter habit). No fix applied without that observation.
- Tooling gotchas: a killed (SIGKILL) instance leaves its runtime dir in
  /run/user/1000/hypr/, which makes `ls -t | head -1` point at a dead
  socket — use the manager env's HYPRLAND_INSTANCE_SIGNATURE or check
  .socket.sock. writeFishBin produces a package directory with the binary
  at bin/<name>. Fish 4 rejects a trailing `$` inside a double-quoted
  regex (`":$"`); single-quote regexes.

### 2026-10-13 (night) — tray applets out: native bluetooth widget, title alignment (agent session, Master at machine)

Post-switch feedback, three fixes:

- **Old wifi + bluetooth tray icons still present**: nm-applet had survived
  from the pre-wave-2 generation's exec-once (it was never actually killed
  earlier — the kill silently failed), and blueman-applet was still in
  exec-once. Killed nm-applet, blueman-applet and blueman-tray (by pid;
  pgrep -c -x verified zero afterwards), dropped blueman-applet from
  exec-once, and removed the networkmanagerapplet package from
  modules/hyprland.nix (nm-applet and nm-connection-editor are gone;
  nmtui from networkmanager covers connection editing; the blueman
  package stays for blueman-manager). quickshell itself hosts
  org.kde.StatusNotifierWatcher, so nothing external resurrects tray
  items; the tray is empty now.
- **Bluetooth.qml** (new): native widget from Quickshell.Bluetooth
  (Bluetooth.defaultAdapter with writable `enabled`, device connected
  state from Bluetooth.devices.values). Icon mapping: adapter off or
  missing -> bluetooth-disabled-symbolic at 0.55 opacity; a device
  connected -> bluetooth-active-symbolic; on and idle ->
  bluetooth-disconnected-symbolic. Left-click toggles adapter power;
  right-click launches blueman-manager (temporary handler until a native
  panel exists). Hidden
  when the machine has no adapter. All five bluetooth symbolic SVGs were
  already in the recolored icon set. Live-verified through a test
  instance: config loads with zero errors, bar renders; the adapter is
  Powered: no on this machine, so the disabled icon is the expected
  render.
- **Title floated ~1px high next to the clock**: ActiveWindow was 9pt vs
  the clock's 10pt. Both are center-anchored to the bar, but different
  sizes put their baselines at different heights, which reads as the
  title sitting high. Title is now 10pt — equal metrics align center,
  baseline and x-height.
- Tooling trap (bit this session): never put the
  `setsid nohup quickshell ... &` launch inside a backgrounded `&&`
  chain — `A && B && setsid nohup quickshell ... &` backgrounds the whole
  list, setsid execs quickshell as the async subshell's foreground
  child, and the subshell waits forever (the tool call timed out while
  quickshell itself detached fine and kept running). Background the
  launch statement alone.
- **Nested Hyprland tested on Master's request**: 0.56.2 runs a second
  instance in a window inside the session (`Hyprland -c scratch.conf`,
  handover via --socket/--wayland-fd internally, window class
  "aquamarine", second socket wayland-2, visible in `hyprctl
  instances`). Confirmed hazard: it republishes WAYLAND_DISPLAY to the
  systemd/D-Bus env (hijack restored manually; see the runbook gotcha).
  Scratch instance needed SIGKILL.

### 2026-10-13 (evening) — batch 4 wave 2: bar polish, native wifi, caffeine toggle, toast root cause (agent session, Master at machine)

- **Toasts stuck forever — root cause fixed.** quickshell deletes untracked
  Notification objects shortly after the onNotification handler returns.
  Every later access then hits a dangling QML wrapper: the 5s timer logged
  "Property 'expire' of object TypeError ... is not a function", and clicks
  failed the same way through dismiss()/actions (four click errors in the
  old test log). Card texts kept rendering because their bindings evaluated
  once while the object was alive. The expireTimeout change from the
  previous session (5s default for -1, sticky critical) was correct but
  dead code while the object died. Fix: `toast.tracked = true` in
  onNotification plus a guarded `actions` access. Verified live through
  hyprctl layers (no screenshots): a normal toast maps at +1.5s and the
  window shrinks back to its empty 12px container by +7.5s; a critical
  toast is still mapped at +8.5s (sticky by design); zero TypeErrors in
  the log. API surface confirmed from the package's qmltypes files —
  expire/dismiss/tracked all exist server-side (the docs site served
  v0.1.0 content; the installed binary is the authority).
- **Bar right side rebuilt** (contrast + alignment): adwaita symbolic SVGs
  hardcode `fill="#2e3436"`, invisible on the dark bar. iconRecolor
  runCommand rewrites the fills to the theme fg at build time (status +
  devices sets flattened into one dir; `chmod -R u+w` required before
  sed -i — store files are read-only). Icons 16px, % text baseline-offset.
  New Network.qml: native wifi widget (signal-strength icon + SSID text,
  wired/offline fallbacks) from Quickshell.Networking; nm-applet dropped
  from exec-once (blueman stays). New Caffeine.qml: hypridle.service
  stop/start toggle with an is-active probe and a 60s re-probe; moon =
  normal, sun = idle blocked. Screenshot-verified earlier in the session:
  white icons, SSID rendered, everything aligned.
- **Tooling**: QML-only changes iterate without a rebuild — copy the built
  store config to /tmp, `chmod -R u+w`, patch the copy, run
  `quickshell -p <copy>`. The pgrep self-match trap hit twice more: a kill
  command must live in its own bash invocation, because any other text in
  the same command line (e.g. the launch line) matches the -f pattern and
  the wrapper shell kills itself mid-script.
- End state: test instances killed; quickshell.service active and owning
  the bar + notification bus. The deployed service still runs the old
  config until the switch, so normal toasts still stick until then — do
  not re-test notifications before the gate.

### 2026-10-13 (afternoon) — deploy gate fixes: login start, IPC poke, screen keepalive (agent session, Master napping)

Master switched + relogged onto the wave-1 commits. Two issues reported:

- **quickshell did not start at login** ("qt plugins missing"). Journal:
  "Failed to create wl_display (No such file or directory)" -> Qt cannot
  load the wayland platform plugin (it probes the default wayland-0) ->
  FATAL -> quickshell's own crash-loop guard -> start-limit-hit. Root
  cause: the systemd user manager has no WAYLAND_DISPLAY at login
  (nothing in the session imported it). Manual restarts worked because
  the env had landed by then. Fixes: (1) exec-once
  `dbus-update-activation-environment --systemd WAYLAND_DISPLAY
  HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE` in
  hyprland.nix; (2) `Environment=WAYLAND_DISPLAY=wayland-1` merged into
  the quickshell unit (systemd.user.services in quickshell/default.nix).
  (3) A user-level drop-in
  (~/.config/systemd/user/quickshell.service.d/override.conf) applies the
  same Environment now, before the next rebuild; the flake fix makes it
  redundant later. Verified: restarted unit env carries WAYLAND_DISPLAY.
- **Dock did not appear in float mode**: float-workspace's bare
  `quickshell ipc call` cannot find the service instance (default-config
  resolution fails with a named config) so live pokes silently failed;
  the dock only reflected float state from its startup marker sync.
  Fix: `quickshell -c shell ipc call floatws set ...`. Verified live
  through the service instance: toggle on -> marker + dock maps; toggle
  off -> dock unmaps. Goes live on the PATH with the next rebuild (the
  in-store binary already has it).
- Tooling note: after relogin /run/user/1000/hypr/ keeps the old
  session's signature dir; `ls | head -1` returns a dead socket. Use
  `ls -t`.
- Screen keepalive per Master: systemd-inhibit block on
  sleep:idle:shutdown for 8h (hypridle respects it).
- Pending: one `sudo nixos-rebuild switch` to move the script fix +
  exec-once import into the deployed generation (drop-in already covers
  the service env).

### 2026-10-13 (morning) — batch 4 wave 1 finished: battery icon, dock input, float mode (agent session, Master at machine)

Committed `a279af4` (unsigned, per agreement; re-sign later — see pending
note below). Content on top of the staged wave:

- **Volume widget "missing" was a false alarm**: volume sat muted at 5% from
  the night tests; the % text is hidden when muted, and the muted-speaker
  icon was misread at 5x zoom as a "sliders" glyph. Unmuted to 45%. The tray
  "sliders" glyph is easyeffects' real tray icon; nm-applet colored bars and
  blueman's bluetooth-off icon are also genuine. Accepted as-is; forcing
  symbolic tray icons is fragile polish, deferred.
- **Battery icon fixed**: adwaita 50.0 has no `battery-level-100-charging`;
  level 100 is `-charged`. Battery.qml clamps the level and switches to
  `-charged` at 100% while charging. Verified in a screenshot.
- **Dock input root cause**: the OSD PanelWindow was always mapped
  (1920x140 at the dock's edge) and layer-shell surfaces swallow pointer
  input even when fully transparent — the dock was clickable only where the
  OSD did not overlap. Fix: `visible: pill.opacity > 0` (unmaps when idle,
  releases the exclusive zone) + implicitHeight 100. `hyprctl layers` shows
  exactly bar + dock + toasts at idle; the OSD maps on change and unmaps
  1.8s after hide. Master confirmed dock hover works.
- **Per-workspace float mode** (Master's request): `float-workspace` fish
  script in `hyprland.nix` (writeFishBin, bound to SUPER SHIFT F). It
  toggles `togglefloating` for each window on the ACTIVE workspace that
  needs flipping, records the state in
  `$XDG_RUNTIME_DIR/hypr-float-ws/<ws-id>` marker files, pokes the shell
  over IPC (`quickshell ipc call floatws set <ws> on|off`), and notifies.
  Windows opened while float mode is on stay tiled (documented limitation:
  0.56 has no working per-workspace float rule; `workspaceopt` and
  `setfloating` are no-ops, `togglefloating` works).
- **Dock follows float mode**: hidden on tiling workspaces, shown on
  floating ones. State source is the marker dir (re-synced at shell start);
  the IPC handler updates the live map. Gotcha found the hard way:
  quickshell 0.3.1 `Hyprland.focusedWorkspace` never updates after startup
  (empirically stale -> dock always read ws 1). Active workspace is probed
  from `hyprctl -j activeworkspace` at start and tracked via
  `Hyprland.rawEvent`; **event data is the value after `>>`**
  (`workspace>>77` -> data `"77"`), no separator to strip.
- Verified live with debug logging: startup sync loads markers, rawEvent
  fires on workspace switches, dock maps on a floating workspace and
  unmaps on a tiling one, windows float and tile. Test instances were
  killed; during testing quickshell instances died whenever their last
  layer surface was closed (quickshell quits with zero windows) — that was
  us closing the duplicate bars, not a crash. Note: quickshell daemonizes,
  so the effective pid is a child of the launched one; `pgrep -f` the
  config path and check `/proc/<pid>/cmdline`.
- **Notifications crashed the shell on every send** (Master: "notify-send
  doesn't do anything"). Crash reports in ~/.cache/quickshell/crashes:
  segfault in Qt 6.11.2's VDMListDelegateDataType::createMissingProperties
  when the Toasts Repeater model was reassigned from the onNotification
  JS handler. The wave-1 readonly fix un-masked it (the assignment used to
  fail harmlessly). A count model did NOT avoid it; the fix is the
  imperative rewrite in Toasts.qml (cards via Component.createObject,
  declared as `property Component` — bare Component children hit
  NotificationServer's missing default property). Verified live:
  notify-send renders a styled card, instance survives, zero errors.
- **hyprctl notify color syntax**: the color argument must be a plain
  `"rgb(3584e4)"`; the `"0 rgb(...)"` form renders the color string as
  message text. float-workspace notify lines fixed.

**Deploy gate (needs Master)**: `sudo nixos-rebuild switch --flake .#Taihou`
from the repo, then `systemctl --user restart quickshell` + `hyprctl reload`
(relogin also fine). After that: SUPER SHIFT F toggles float mode + dock per
workspace; OSD no longer eats dock clicks; battery icon correct at 100%.

### 2026-10-13 (night) — batch 4 wave 1: OSD, wallpaper, bar fix (agent session, Master asleep)

Ran with a systemd-inhibit lock (idle+sleep+shutdown blocked 14h) per
Master's request.

**Wallpapers: root cause found.** nixpkgs renamed `swww` -> `awww` upstream;
binaries are `awww` / `awww-daemon`. The old `exec-once = "swww-daemon"`
silently failed (command not found) — wallpapers never stood a chance.
Fixes: `awww` in systemPackages, `awww-daemon.service` + hourly
`wallpaper-rotate.timer` (fish script, random from ~/Pictures/Wallpapers,
transition), exec-once entry dropped. Verified live: daemon started manually,
wallpaper rendered on eDP-1 (`awww query`).

**OSD (volume + brightness) built and verified with screenshots:**
- `shell/OSD.qml`: GNOME-style pill (icon + bar + %), auto-hide 1.8s, fade.
  State-based triggers, not keybind-based: volume from Pipewire signals,
  brightness from a `while true; brightnessctl get; sleep 1` stream process
  (0.3.1 FileView has no polling).
- Volume OSD trigger: `onVolumesChanged` — **plural**. The notify signal for
  `PwNodeAudioIface.volume` is `volumesChanged` (qmltypes-verified);
  `onVolumeChanged` silently never fires.
- **PwObjectTracker is mandatory**: quickshell nodes stay unbound until
  tracked; unbound nodes report `volumes: []` / volume 0 (that is why the
  bar showed 0% while pamixer said 45%) and mute writes fail. Both
  `Volume.qml` and the OSD track `[Pipewire.defaultAudioSink]`.
- Verified: `OSD show: volume 0.5` in logs; screenshots show the pill with
  speaker icon + blue bar + 55%, and brightness icon + 20%; brightness
  restored afterwards. Test instances killed; the deployed instance still
  needs a switch + relogin to gain the OSD.

**Bar overlap fixed**: title is now anchored between the workspaces row and
the clock (child-to-child anchors); the old fixed 180/380px margins let long
titles run into the clock. ActiveWindow width binding removed (it fought the
anchors).

**Top-right icons polished**: volume + battery are now Adwaita symbolic
icons + small % text (level-mapped names, all verified present in the
installed theme). Theme-name lookups fail because MoreWaita (the active
theme) does not inherit Adwaita, so `Theme.adwaitaIcon(name)` resolves the
SVG by direct store path (token `iconDir` in the generated Theme.qml).

**Notifications actually fixed**: `Toasts.qml` declared `toasts` readonly
and assigned it — "Cannot assign to read-only property" at runtime meant
no toast ever rendered. Now mutable.

Remaining batch 4: launcher panel, caffeine toggle (hypridle stop/start).

### Commit pending: SSH keyring locked (2026-10-13 ~01:30)

RESOLVED 2026-10-13 morning: committed unsigned (`git -c commit.gpgsign=false
commit -F docs/COMMIT_MSG_PENDING.txt`) per Master's authorization; the
staged wave-1 plus the morning fixes are in `a279af4`. Re-sign later if
desired (`git rebase --exec 'git commit --amend -S' <base>` or re-sign the
commits individually). The keyring/prompter gap under Hyprland is still open
(secret prompts have no UI yet).

Original note: commit signing needs the SSH agent, and both agent
sockets are locked — gcr lists the keys but signing fails ("communication
with agent failed", the gcr unlock prompter cannot run outside GNOME), and
the gnupg socket hangs waiting for a pinentry that cannot display. Signing
worked earlier in the evening; the user-service restarts during the
generation switches appear to have re-locked it.

Migration finding to address later: secret/unlock prompts (gcr prompter,
pinentry) have no working UI under Hyprland yet. SSH signing, keyring
prompts for new secrets etc. depend on it. Candidate fix: ensure the gcr
prompter D-Bus activation works in the session, or register a prompter
component in the shell.


### 2026-10-12 — dock favorites rebuilt: DesktopEntries bypassed (agent session)

The dock showed no icons and clicks did nothing. Root cause: quickshell
0.3.1's `DesktopEntries` returns an empty index on this system — verified
by a probe config (`applications count: 0`, `byId`/`heuristicLookup` all
NULL) even with a correct `XDG_DATA_DIRS` and even with a .desktop file
placed in `~/.local/share/applications`. Also: `IconImage` with a bare icon
name resolves it as a relative URL ("Cannot open: qrc:.../Widgets/firefox"),
not through the icon theme.

Dock.qml rewritten to not use DesktopEntries at all:

- Favorites are static data: window-class match, launch argv (verified
  present on PATH) and a theme icon name.
- Click launches via `Quickshell.execDetached(command)`; running/focus/
  minimize behavior unchanged.
- Icons render via `Quickshell.iconPath(name)` (`image://icon/...`, the
  freedesktop theme lookup — same mechanism the working tray uses).
- Bottles dropped from favorites: it ships no .desktop on this system, so
  its tile was permanently dead. It can return once installed with an
  entry.

Verified: `nix build` green; live test of the built shell dir loads with
0 errors (only the expected notification-bus warn against the already
running instance); screenshot shows all five icons rendering.

### 2026-10-12 — quickshell triage: 3 QML defects fixed, shell live (agent session)

After the first-boot fixes, quickshell still failed
(`quickshell.service`: exit 255, start-limit-hit) and the desktop showed
Hyprland's grey config-error overlay ("read the wiki" quote) because the
compositor registers an empty-string config error at startup
(`hyprctl configerrors -j` -> `[""]`); `hyprctl reload` clears it and a
relogin clears it permanently.

Quickshell fixes (verified live against the built shell dir: 0 errors,
0 warnings, bar + dock + widgets render on both monitors):

1. `shell/qmldir` only declared the Theme singleton. A qmldir makes a
   directory authoritative for its types, so Bar/Dock/Toasts never
   registered -> "X is not a type" (in varying order per process). Fix:
   declare all three in `shell/qmldir`.
2. `Toasts.qml` put a PanelWindow inside NotificationServer as a bare
   child; NotificationServer has no default property -> "Cannot assign to
   non-existent default property". Fix: `property PanelWindow window:`
   (quickshell instantiates windows from property values, like Variants).
3. `widgets/*.qml` could not see the Theme singleton (it lives in the
   parent dir's qmldir; build-time qmllint masked this by putting the dir
   on its import path). Fix: `import ".."` in the five widgets that use
   Theme.
4. retTheme lacked `barHeight`/`dockHeight` but Bar/Dock/Toasts referenced
   them -> "Unable to assign [undefined] to int". Fix: tokens added to
   retTheme (barHeight 36, dockHeight 56) and generated into Theme.qml.

Master switched mid-session (23:44): service came up stable with fixes 1+2.
Remaining: one more switch for fixes 3+4, then restart the quickshell unit
(or relogin, which also clears the leftover overlay).

### 2026-10-12 — first boot triage: 3 startup complaints fixed (agent session)

Master switched + rebooted. Hyprland is running. Three complaints found in
the live Hyprland log
(`/run/user/1000/hypr/<sig>/hyprland.log`), all diagnosed and fixed:

1. `WARNING: Hyprland is being launched without start-hyprland` — greetd ran
   `--cmd Hyprland` (the raw wrapper). nixpkgs 0.56.2 ships `start-hyprland`
   (env setup + crash watchdog); the package's own `hyprland.desktop` Exec
   points at it. Fix: greetd `--cmd start-hyprland`
   (`modules/hyprland.nix`).
2. `ERR: Invalid dispatcher: ptyxis` + config Error Overlay —
   `bind=F12, exec, ptyxis` put F12 in the modifier field, so Hyprland read
   `exec` as the key and `ptyxis` as the dispatcher. Bare-key binds need the
   empty mods field. Fix: `", F12, exec, ptyxis"`
   (`users/retblast/hm/hyprland.nix`).
3. `Error parsing gradient rgba(53, 132, 228, 0.7)` ×5 — Hyprland only
   parses RRGGBBAA hex colors, not CSS-style comma lists. Fix:
   `rgba(3584e4b2)` (GNOME blue #3584e4 at ~70% alpha).

All three verified in the rebuilt toplevel (generated hyprland.conf +
greetd.toml). ptyxis itself was never missing: it is in
`environment.systemPackages` and on PATH; the "missing ptyxis" impression
came from complaint 2.

### 2026-10-12 — batches 1-3 implemented (agent session)

- Wrote `modules/hyprland.nix`: programs.hyprland, xdg-desktop-portal-gtk,
  greetd+tuigreet (vt 1, --cmd Hyprland), gnome-keyring, gvfs, dconf, upower,
  power-profiles-daemon, colord, hyprlock PAM, greetd keyring-unlock PAM,
  fontconfig subpixel policy (was in gnome.nix), core packages.
- `machines/Taihou/default.nix`: gnome.enable=false, hyprland.enable=true.
- Wrote `users/retblast/hm/hyprland.nix`: hyprlang config (configType forced),
  keybinds (F12, Ctrl+Alt+ñ carryover, workspace/media/screenshot binds),
  exec-once (nm-applet, blueman-applet, swww-daemon), hypridle (lock 300s /
  dpms 600s, no auto-suspend), hyprlock, fuzzel, cliphist, hyprpolkitagent,
  screenshot + clipboard-pick fish scripts.
- Wrote `users/retblast/hm/shell-theme.nix` (retTheme option) and
  `users/retblast/hm/quickshell/`: configs.shell with generated Theme.qml,
  systemd service. QML shell v1: Bar (workspaces, active window, clock, tray,
  volume, battery), Dock (favorites + running via Hyprland toplevels,
  48px, focus/minimize click), Toasts (NotificationServer-based, the only
  notification daemon).
- Re-gated `deskEnv-config.nix` (gtk/qt/dconf unconditional; qt style
  adwaita; removed gnome-shell extensions block; color-scheme prefer-dark
  made declarative; dropped breeze style -> no KDE deps).
- `workarounds.nix`: pointerCursor unconditional (Adwaita 24, gtk enabled).
- `zed.nix`: reads retTheme instead of dconf.
- `hm/default.nix`: imports added; conflicting qt block removed.
- Docs: AGENTS.md (session protocol) + docs/HYPRLAND_QUICKSHELL_MIGRATION.md
  (runbook with verified quickshell 0.3.1 API notes) + this file.

### 2026-10-12 — planning session

- Full repo sweep; live-session service inventory captured (gvfs, dconf,
  gnome-keyring, PPD, upower, colord must be re-declared explicitly).
- Couplings found: zed.nix dconf fonts, ollama service target, keyd/ydotool
  session-agnostic.

## Verification performed (build-level)

- 2026-10-12 quickshell triage: `nix build` toplevel green. Live test of the
  built shell dir (quickshell --config <store-path>): loads with 0 errors,
  0 warnings; bar, dock, volume/battery/tray render on both monitors. The
  only startup WARN was the notification-bus conflict with the instance
  already running from the earlier switch.
- 2026-10-12 triage: `nix build` toplevel green after the three fixes.
  Generated hyprland.conf: `bind=, F12, exec, ptyxis` and
  `col.active_border=rgba(3584e4b2)`. Generated greetd.toml:
  `--cmd start-hyprland`.
- `nix build .#nixosConfigurations.Taihou.config.system.build.toplevel` green.
- greetd.toml: tuigreet --time --remember --cmd Hyprland, user greeter, vt 1.
  (Superseded 2026-10-12: --cmd start-hyprland, see triage journal entry.)
- GDM disabled; hyprland/keyring/gvfs/dconf/upower/hyprlock-PAM all true.
- Generated hyprland.conf: hyprlang, all binds + exec-once present.
- Generated quickshell shell dir complete; Theme.qml generated from retTheme.
- User units: quickshell, hypridle, cliphist (+images), hyprpolkitagent all
  bound to graphical-session.target (chained from hyprland-session.target).
- qmllint with Qt+Quickshell import paths: 0 errors in all 10 QML files.
- fish scripts (screenshot-region, screenshot-full, clipboard-pick) in closure.

## Pending runtime gate (Master)

1. `sudo nixos-rebuild switch --flake .#Taihou` from the repo (waves 1-3)
2. `systemctl --user restart quickshell && hyprctl reload` (or relogin)
3. Check: OSD no longer blocks the dock (hover cursor over dock);
   battery icon correct at 100%; volume/brightness keys pop the OSD;
   wallpaper rotates hourly; bar title no longer overlaps the clock;
   SUPER SHIFT F toggles float mode + dock on the active workspace;
   bar right side shows white aligned icons + wifi SSID + caffeine moon
   + bluetooth icon; title baseline matches the clock; notify-send
   without -t disappears after ~5s, critical notifications stay until
   clicked; clicking the caffeine moon toggles hypridle (sun = idle
   blocked); left-click on the bluetooth icon toggles the adapter,
   right-click opens blueman-manager; tray has
   no applet icons (nm-applet/blueman processes are dead already; they
   cannot come back after relogin)
4. Rollback if needed: previous generation in GRUB

Note: the wallpaper for the night was already set manually (`awww img`);
the daemon keeps it until logout even without the switch.

## Next actions

1. Master: switch gate (fuzzel border + prompt, tray centering, gesture
   persistence, dconf trim live).
2. Accents diagnostic (Master): what is pressed and what appears — dead
   key ´ then vowel, or RightAlt+letter (keyd turns a rightalt tap into
   `>`)? Fix follows from that: keyd tweak or kb_variant change.
3. Batch 4 exit criteria: exercise the never-verified parity items
   (Steam/gamescope, waydroid, virt-manager polkit, Bitwarden keyring
   unlock, MTP/trash in Nautilus) — needs Master at the machine.
4. Batch 6 (future): custom greeter (fingerprint), overview (unlocks the
   3-finger-up gesture), dynamic wallpaper->palette theming, custom lock
   UI, weather widget (geoclue2 present).
5. Session-keepalive: the 8h inhibit lock from 2026-10-13 ~15:10 has
   expired by now; start a fresh one for overnight runs if asked.

## Open questions

- Night light: GNOME color block was empty; assumed not needed (wlsunset
  can be added later).
- Mouse/touchpad feel: sensitivity -0.7 is a starting point; tune live.
- Keyboard bind `CTRL ALT, ntilde`: verify at runtime; fallback is
  `code:` bind if the keysym name does not resolve.
