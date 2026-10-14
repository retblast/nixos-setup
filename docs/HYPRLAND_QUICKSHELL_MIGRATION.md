# Hyprland + Quickshell migration — runbook

Read `docs/MIGRATION_STATUS.md` first for current progress and decisions.
This file is the stable instructions. The status file is the mutable state.

## Goal

Replace GNOME on Taihou with Hyprland + Quickshell in one system generation.
Own the shell: bar, dock, launcher, notifications, OSD, lock. The greeter
stays stock (tuigreet) for v1. Later batches add a custom greeter and
dynamic theming.

## Non-goals (v1)

- Custom greeter. tuigreet is enough.
- UWSM. HM's `wayland.windowManager.hyprland.systemd.enable` (default true)
  provides `hyprland-session.target -> graphical-session.target`.
- Plasma / KDE Frameworks packages. Nothing in the app set needs them.
- Replacing GTK apps (Nautilus, Ptyxis, Papers, ...). They are apps, not the
  desktop. They keep working via dconf + gvfs.
- Changes to Hearts or TaihouLite. `modules/gnome.nix` stays for them.

## Locked decisions (with evidence)

1. **nixpkgs packages, no Hyprland/Quickshell flakes.**
   `pkgs.hyprland` 0.56.2 (a newer tagged release than the flake's master
   label), `pkgs.quickshell` 0.3.1 (one patch behind). Same nixpkgs tree as
   the system (Qt/Mesa coherence), cache.nixos.org, zero new inputs.
   Escape hatch: add `hyprland.url = "github:hyprwm/Hyprland"` and override
   `programs.hyprland.package` later if master is ever needed.
2. **Secrets: gnome-keyring, not KWallet.**
   The NixOS module is ~30 lines: daemon + D-Bus + PAM + it registers the
   xdg-desktop-portal Secret backend. No GNOME session deps. KWallet does
   not serve `org.freedesktop.secrets` to libsecret clients (Bitwarden,
   Chrome, Fractal use it directly) — KWallet would break the keyring.
3. **Polkit: hyprpolkitagent.** HM module `services.hyprpolkitagent`
   provides a user service bound to the session target.
4. **Greeter: greetd + tuigreet.** `pkgs.tuigreet` 0.11.1. Fingerprint
   unlock at the login UI is lost (accepted; returns with the custom
   greeter later). fprintd stays for sudo/polkit.
5. **Idle/lock: hypridle + hyprlock.** hyprlock needs
   `security.pam.services.hyprlock`. Keyring auto-unlock at login needs
   `security.pam.services.greetd.enableGnomeKeyring`.
6. **Wallpaper: swww.** swww-daemon restores the last image itself;
   rotation via a fish script on a timer (GNOME parity: 1h interval,
   ~/Pictures/Wallpapers).
7. **Hyprland config format: hyprlang.** HM defaults `configType` to "lua"
   for stateVersion >= 26.05. Force `"hyprlang"`: documented format, stable
   tooling, every example on the wiki applies.
8. **Qt theming: keep `qt.platformTheme.name = "adwaita"`** (QGnomePlatform).
   Works without GNOME because the dconf daemon stays. Revisit qt6ct when
   Qt apps become relevant.
9. **Theme source of truth: `users/retblast/hm/shell-theme.nix`.**
   One HM option `retTheme` (fonts, sizes, colors). Consumers: Quickshell
   (Theme.qml generated from it) and `zed.nix` (which previously read
   dconf and broke when GNOME left). Do not hardcode theme values
   elsewhere.

## GNOME services that had to be re-declared

Verified live on the GNOME session before migration: gvfs (6 user
daemons), dconf, gnome-keyring (org.freedesktop.secrets), gcr-ssh-agent,
power-profiles-daemon, upower, colord. Under Hyprland none of these are
automatic. The `modules/hyprland.nix` NixOS module enables all of them
explicitly.

Removed with the GNOME session and not replaced in v1: evolution backends
(Fractal/Calendar only), tracker/localsearch (Nautilus search degrades
gracefully), IBus (kb_layout = es covers Spanish; keyd handles the AltGr
remap below the compositor), org.freedesktop.ScreenSaver (hypridle
inhibitors take over).

## Target file map

    modules/hyprland.nix                    # NixOS: session, services, greeter
    modules/default.nix                     # import list
    machines/Taihou/default.nix             # DE toggles
    users/retblast/hm/hyprland.nix          # HM: WM config, binds, daemons
    users/retblast/hm/shell-theme.nix       # HM: retTheme option (theme source)
    users/retblast/hm/quickshell/           # HM: quickshell wiring + QML shell
      default.nix
      shell/                                # QML, versioned here
    users/retblast/hm/default.nix           # imports
    users/retblast/hm/deskEnv-config.nix    # GTK/Qt/dconf re-gated off GNOME
    users/retblast/hm/workarounds.nix       # cursor now unconditional
    users/retblast/hm/software-development/zed.nix  # reads retTheme, not dconf

HM pieces gate on `taihouConfig.localModule.hyprland.enable`, following the
pattern used in `deskEnv-config.nix` / `hm/default.nix`.

## Quickshell 0.3.1 API notes (verified from the built qmltypes)

- Core (`import Quickshell`): `ShellRoot`, `PanelWindow` (anchors { left,
  right, top, bottom }, exclusiveZone), `Singleton`, `Variants`,
  `DesktopEntries`, `Quickshell` (configDir), `QsMenuAnchor`.
- `Quickshell.Hyprland`: singleton `Hyprland` with `focusedMonitor`,
  `monitors`, `workspaces`, `toplevels`, `dispatch(string)`,
  `rawEvent(event)`. `HyprlandWorkspace`: id, name, active, focused,
  urgent, monitor. `HyprlandToplevel`: title, activated, urgent,
  `lastIpcObject.class`. `HyprlandMonitor`: name, activeWorkspace, focused.
- `Quickshell.Services.SystemTray`: singleton `SystemTray`, `.items`
  (StatusNotifierItem: id, title, tooltipTitle, icon (string), status,
  hasMenu, onlyMenu, menu; methods activate(), secondaryActivate(),
  display(...)).
- `Quickshell.Services.UPower`: singleton `UPower`, `.displayDevice`
  (percentage, iconName, timeToEmpty, isPresent, state), `.onBattery`.
- `Quickshell.Services.Pipewire`: singleton `Pipewire`,
  `.defaultAudioSink.audio` (volume, muted).
- `Quickshell.Services.Mpris`: singleton `Mpris`, `.players`
  (trackTitle, trackArtist, isPlaying, togglePlaying()).
- `Quickshell.Services.Notifications`: `NotificationServer` singleton,
  signal `notification(toast)`; toast: summary, body, appName, expireTimeout,
  actions[], methods expire(), dismiss(), signal closed(reason).
- `Quickshell.Widgets`: `IconImage`, `WrapperItem`, `WrapperRectangle`.
- `Quickshell.Io`: `Process`, `FileView`, `Socket`.
- QML singletons inside the config dir: `shell/qmldir` declares
  `singleton Theme 1.0 Theme.qml`; Theme.qml is generated from `retTheme`.

## Batches

### Batch 1 — NixOS plumbing (one generation flip)

Files: `modules/hyprland.nix`, `modules/default.nix`,
`machines/Taihou/default.nix`.

`modules/hyprland.nix` provides `options.localModule.hyprland.enable` and
configures, under `mkIf`:

- `programs.hyprland.enable` (portal + xwayland handled by the module),
  `withUWSM = false`.
- `xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ]` (file
  chooser outside Firefox).
- `services.greetd` with tuigreet
  (`--time --remember --cmd start-hyprland`, user "greeter"). start-hyprland
  is the package's launcher (env setup + crash watchdog); launching the
  compositor binary directly makes Hyprland warn at startup.
- Explicit service set: `services.gnome.gnome-keyring.enable`,
  `services.gvfs.enable`, `programs.dconf.enable`,
  `services.upower.enable`, `services.power-profiles-daemon.enable`,
  `services.colord.enable`.
- PAM: `security.pam.services.hyprlock`,
  `security.pam.services.greetd.enableGnomeKeyring`.
- Font rendering parity (was in gnome.nix): `fonts.fontconfig.subpixel`
  rgba none, lcdfilter none.
- Packages: hyprpolkitagent, hypridle, hyprlock, swww, fuzzel, grim, slurp,
  wl-clipboard, cliphist, playerctl, pamixer, brightnessctl, libnotify,
  nautilus, ptyxis, file-roller, papers, blueman.

`machines/Taihou/default.nix`: `localModule.gnome.enable = false;`,
`localModule.hyprland.enable = true;`.

Same generation: `deskEnv-config.nix` GTK/Qt/dconf blocks re-gated
unconditionally (they were keyed on the GNOME toggle and would have
silently disabled GTK theming, icons, and app settings).

Gate:
- eval: greetd enabled, gdm disabled, hyprland enabled, gvfs/dconf/upower
  enabled
- `nix build .#nixosConfigurations.Taihou.config.system.build.toplevel`
  succeeds
- switch + reboot: tuigreet appears, Hyprland starts, TTY works, previous
  generation selectable in GRUB

### Batch 2 — HM Hyprland config

File: `users/retblast/hm/hyprland.nix` (gated on
`taihouConfig.localModule.hyprland.enable`).

- `configType = "hyprlang"`, `systemd.enable = true`.
- Monitors: builtin preferred/auto.
- Input: `kb_layout = es`, natural_scroll + tap for touchpad,
  `sensitivity = -0.7` (tune by feel; GNOME used -0.75).
- Binds: F12 + Super+Return -> ptyxis; Ctrl+Alt+ntilde -> dmmm-mouse-fix;
  Super+E nautilus; Super+D fuzzel; Super+Q kill; Super+L hyprlock;
  Super+M exit; Super+1..0 workspaces; XF86 media/volume/brightness;
  Print (region) / Shift+Print (full) screenshots; Super+V clipboard pick.
- `exec-once`: nm-applet, blueman-applet, swww-daemon.
- `services.hypridle` (HM module): lock after 300s, dpms off after 600s,
  no auto-suspend (GNOME parity: sleep-inactive-ac-type = nothing).
- `programs.hyprlock` (HM module) + `security.pam.services.hyprlock` from
  the NixOS side.
- `programs.fuzzel`, `services.cliphist` (HM modules).
- Cursor: `home.pointerCursor` unconditional (Adwaita, 24) — was gated on
  GNOME and would have been lost.

Gate: login -> usable Hyprland; binds work; screenshot to clipboard;
polkit dialog appears (virt-manager); Chrome/Firefox native Wayland.

### Batch 3 — Quickshell skeleton

Files: `users/retblast/hm/shell-theme.nix`,
`users/retblast/hm/quickshell/`.

- `retTheme`: sans SF Pro Text / mono SF Mono / size 10 / dark palette.
  `zed.nix` rewritten to consume it (drops its dconf dependency).
- QML shell v1 (`configs.shell`, `activeConfig`, systemd service):
  - Bar (top): workspaces, active window, clock, tray, volume, battery.
  - Dock (bottom): favorites + running apps (Hyprland toplevels by class),
    48px, autohide on edge.
  - Toasts: NotificationServer -> simple toasts (no second daemon).
- Gate: daily-drive for a session: bar renders, tray shows nm-applet,
  dock launches/focuses/minimizes, notifications render, no CPU spikes.

### Batch 4 — shell completion

Volume/brightness OSD, launcher panel, wallpaper rotation timer
(swww + fish script, 1h), caffeine toggle in the bar (hypridle stop/start).
Parity checklist fully green.

### Batch 5 — cleanup

- Trim inert dconf keys (dash-to-dock, vitals, caffeine, lockkeys,
  azwallpaper, shell favorites) from `deskEnv-config.nix`.
- Audit `users/retblast/pkgs/*` for GNOME-only leftovers.
- Rebuild, journal, update status file.

### Batch 6+ — future

Custom greeter (Quickshell.Services.Pam, fingerprint returns), dynamic
wallpaper->palette theming (Material-You style), app overview, custom lock
UI, weather widget (geoclue2 present).

## Parity checklist (batch 4 exit criteria)

- [ ] login: tuigreet -> Hyprland -> shell up
- [ ] lock + unlock (hyprlock, PAM)
- [ ] suspend on battery idle off / no suspend on AC (v1: none at all)
- [ ] volume + brightness keys, OSD appears (batch 4)
- [ ] media keys control players (MPRIS)
- [ ] screenshots to clipboard; grim+slurp region select
- [ ] clipboard history works (cliphist)
- [ ] notifications: notify-send -> toast renders; actions clickable
- [ ] tray: nm-applet + blueman icons; menus work
- [ ] dock: launch, focus, minimize; autohide edge-reveal
- [ ] launcher: fuzzel finds apps
- [ ] Nautilus: mounts USB (gvfs), trash works, MTP phone works
- [ ] Chrome + Firefox: portal file picker
- [ ] Steam + gamescope: launch, alt-tab patch intact
- [ ] Bottles/Wine app launches
- [ ] virt-manager: polkit dialog appears (agent active)
- [ ] Bitwarden: keyring unlock works (gnome-keyring PAM)
- [ ] ydotool works; OpenTabletDriver works
- [ ] waydroid window shows
- [ ] dual monitor: correct scale if external connected
- [ ] easyeffects active
- [ ] ollama-intel-gpu user service starts on login
- [ ] keyd: rightalt still produces <>
- [ ] fprintd: sudo fingerprint works
- [ ] fonts: SF Pro Text/SF Mono render with stem darkening, no hinting

## Gotchas (learned from the sweep)

- Bare-key binds need the empty modifier field: `", F12, exec, cmd"`, not
  `"F12, exec, cmd"`. In the malformed form Hyprland reads `exec` as the key
  and `cmd` as the dispatcher ("Invalid dispatcher" error + red error
  overlay at startup). Found live on first boot.
- Hyprland colors only parse RRGGBBAA hex (`rgba(3584e4b2)`), not CSS-style
  comma lists (`rgba(53, 132, 228, 0.7)`). Found live on first boot.
- Launch Hyprland through the package's `start-hyprland` wrapper (env setup
  + crash watchdog). The compositor warns when started directly; found live
  on first boot.
- Quickshell QML gotchas (all found live on first boot):
  - `DesktopEntries` in 0.3.1 returns an empty index on this system
    (probe-verified). Do not build on it until upgraded; favorites/launchers
    carry their own data, launching uses `Quickshell.execDetached`.
  - `IconImage` resolves bare names as relative URLs. Theme icons must go
    through `Quickshell.iconPath(name)` (`image://icon/...`).
  - A `qmldir` in a directory makes it authoritative for its types: every
    component referenced from that directory must be listed in it, or QML
    fails with "X is not a type" in varying order per process.
  - Service types (NotificationServer, ...) have no default property:
    host windows as `property PanelWindow window: PanelWindow { }`, not as
    bare children.
  - Subdirectory widgets do not see the parent dir's singletons: they need
    `import ".."`. Build-time qmllint with the shell dir on the import path
    masks all of the above — only a live
    `quickshell --config <built-dir>` run proves the shell loads.
- HM `configType` defaults to "lua" for stateVersion >= 26.05; force
  hyprlang (decision 7).
- `deskEnv-config.nix` gated gtk/qt/dconf on the GNOME toggle; re-gate
  before the flip or GTK apps lose theming/fonts/settings.
- `zed.nix` reads dconf for font sizes; rewrite against `retTheme`.
- `ollama-intel-gpu.service` is WantedBy graphical-session.target: verify
  it starts under the Hyprland session target.
- Only ONE notification daemon may own org.freedesktop.Notifications.
- greetd greeter user has no fingerprint UI. Accepted for v1.
- gvfs + dconf + upower + PPD + colord: explicit or Nautilus/power/battery
  features silently degrade.
- Mouse speed scale differs between GNOME and Hyprland; tune by feel.
- Do not add KDE Frameworks deps.
- `hyprpolkitagent` also ships D-Bus activation in the package, but the HM
  service is the deterministic path.
- **swww is renamed to awww in nixpkgs** (binaries awww / awww-daemon); use `awww`, not `swww`.
- **quickshell PipeWire: PwObjectTracker is mandatory.** Untracked nodes stay unbound: `audio.volumes` empty, volume reads 0, mute writes fail. Track `[Pipewire.defaultAudioSink]`.
- **The volume notify signal is `volumesChanged`** (plural), not `volumeChanged`.
- **PanelWindow has no `opacity` property**; animate a child instead.
- **MoreWaita (active icon theme) does not inherit Adwaita**, so `Quickshell.iconPath()` fails for symbolic UI icons. Use `Theme.adwaitaIcon(name)` (direct file path).
- A directory qmldir is authoritative: every root-level component must be declared in it.
- **Widgets one dir down need `import ".."` to see the Theme singleton**
  — including files that previously did not use Theme. A Tray.qml edit
  added a Theme reference without the import and shipped a broken tray
  ("ReferenceError: Theme is not defined" per delegate). Any widget edit
  that touches Theme must add the import; run the /tmp-rig live load
  before committing QML changes.
- **fuzzel + fractional scaling**: with `dpi-aware = true` (default) at
  scale 1.25, fuzzel's buffer width comes out fractional (e.g. 322
  logical px -> 402.5 buffer px) and rounding clips the right border.
  Fix: `dpi-aware = false` in the fuzzel config (compositor scales a
  1x buffer).
- Hyprland binds: bare keys need the empty modifier field (`, F12, ...`); colors are RRGGBBAA only.
- greetd must launch `start-hyprland` (the package wrapper), not the raw compositor binary.
- **`quickshell ipc` needs explicit instance selection with a named
  config.** A bare `quickshell ipc call ...` resolves the default config
  (`~/.config/quickshell/shell.qml`, which does not exist here) and fails
  silently. Use `quickshell -c shell ipc call ...` to match the service
  instance.
- **The systemd user manager lacks WAYLAND_DISPLAY at login.** The
  quickshell unit then dies before Qt can load the wayland platform plugin
  ("Failed to create wl_display" -> "no Qt platform plugin could be
  initialized" -> start-limit-hit); a later manual `systemctl --user
  restart` works because env has landed by then. Fixes: exec-once
  `dbus-update-activation-environment --systemd ...` in the Hyprland
  config + `Environment=WAYLAND_DISPLAY=wayland-1` on the unit.
- **`/run/user/1000/hypr/` keeps stale signature dirs after relogin.**
  `ls | head -1` picks the dead one; use the newest dir (`ls -t`) or the
  one whose `.socket.sock` exists. The manager env's
  HYPRLAND_INSTANCE_SIGNATURE (after the env import) is authoritative.
- **Layer-shell windows swallow pointer input while mapped**, even when fully
  transparent. A always-mapped OSD above the dock made the dock unclickable.
  Unmap unused PanelWindows (`visible` bound to activity); an unmapped
  surface also releases its exclusive zone.
- **adwaita-icon-theme 50.0**: battery level 100 has no `-charging` variant;
  it is `battery-level-100-charged-symbolic` (`-plugged-in` exists at all
  levels).
- **Hyprland 0.56 per-workspace float**: `workspaceopt` is a deprecated
  no-op (warns, does nothing), workspace rules no longer have an
  `all:float` field, `setfloating` is a no-op (returns ok, does nothing),
  dynamic `windowrule float` keywords do not match new windows. The only
  working per-window toggle is `togglefloating`; per-workspace float mode
  is therefore client-side (see the `float-workspace` script).
- **quickshell 0.3.1 `Hyprland.focusedWorkspace` never updates after
  startup** (empirically stale; qmltypes lists it with a change signal, but
  it does not fire). Track the active workspace via `Hyprland.rawEvent`:
  event `name` is the type before `>>`, `data` is the value after it
  (`workspace>>77` -> `"77"`; no separator to strip). `HyprlandToplevel`
  has no typed `class`/`appId`; use `lastIpcObject.class`.
- **quickshell daemonizes**: the launched process exits after forking the
  real instance. Match instances via `pgrep -f <config-path>` and check
  `/proc/<pid>/cmdline`; `hyprctl layers` reports the real pid.
- **quickshell quits when its last layer surface closes** (e.g. after an
  external `closelayer` dispatch). It is a clean exit, not a crash.
- `hyprctl notify <icon> <time_ms> <color> <message>`: the color argument
  must be a plain `rgb(3584e4)` / `rgba(...)` string. Extra tokens (e.g. an
  icon index inside the color string) make Hyprland render the color as
  message text.
- **Qt 6.11 + quickshell 0.3.1: Repeater models crash when reassigned from
  a JS handler** — VDMListDelegateDataType::createMissingProperties
  segfaults during delegate incubation, even with a plain count model and
  no required properties (every notification crashed the shell; reports
  under ~/.cache/quickshell/crashes). A Repeater that only incubates once
  at component creation (static favorites list) is fine. Anything
  reassigned at runtime must create objects imperatively
  (`Component.createObject`, declared as `property Component`) or use a
  real QAbstractListModel.
- **Untracked quickshell Notifications are destroyed** shortly after the
  `notification` handler returns. Every later access then hits a dangling
  QML wrapper ("Property 'expire' of object TypeError ... is not a
  function" — the object stringifies as a TypeError itself), while
  bindings that evaluated while it lived keep rendering stale text.
  Claim each notification with `toast.tracked = true` inside the handler;
  cards then destroy via the `closed(reason)` signal.
- **The package's qmltypes files are the API ground truth**:
  `<quickshell>/lib/qt-6/qml/Quickshell/**/*.qmltypes` lists every
  property, signal and method of the installed version. Check there
  before trusting the docs site (it can serve a different version — it
  defaulted to v0.1.0 content for a 0.3.1 install).
- **The networking module imports as `Quickshell.Networking`** (its qmldir
  declares `module Quickshell.Networking`). `Quickshell.Services.Networking`
  does not exist and fails as "module not installed". Devices come from
  `Networking.devices.values` (`.values` on the object model), device type
  via `DeviceType.Wifi/Wired`, wifi state per network entry in
  `wifiDevice.networks.values` (`connected`, `signalStrength` 0..1).
- **Adwaita symbolic SVGs hardcode `fill="#2e3436"`** (dark grey) —
  invisible on a dark bar. quickshell/default.nix recolors them at build
  time (`iconRecolor` runCommand: copy the status + devices sets, flatten
  devices into status, `chmod -R u+w` first — store files are read-only
  and sed -i fails without it — then sed the fills to the theme fg).
- **notify-send without -t sends expire_timeout = -1** ("the server
  decides"). The shell's Toasts.qml picks the default itself: 5s for
  normal urgency, sticky for critical (GNOME behavior). Clicking a card
  invokes its default action (if any) and dismisses it.
- **Fast QML iteration without a rebuild**: `cp -r <built-config>/ /tmp/x
  && chmod -R u+w /tmp/x`, patch the copy, `quickshell -p /tmp/x`. The
  notification bus goes to whichever instance registers first — stop the
  service (or kill the old test instance) before testing toasts.
- **pgrep/pkill -f self-match**: a -f pattern that appears anywhere else
  in the same bash command line (e.g. the launch line further down)
  matches the wrapper shell's own cmdline, which then kills itself
  mid-script. The `[q]uickshell` bracket trick only protects the pattern
  text itself. Keep kill commands in their own invocation.
- **Never background a launch inside a `&&` chain**: `A && B && setsid
  nohup quickshell ... &` backgrounds the whole list. Inside the async
  subshell, setsid execs quickshell as a foreground child, so the
  subshell waits for quickshell to exit — the caller times out while
  quickshell runs on detached. Background the launch statement alone
  (`... && echo staged; setsid nohup quickshell ... &; sleep ...`).
- **The bluetooth module imports as `Quickshell.Bluetooth`** (singleton
  `Bluetooth`): `Bluetooth.defaultAdapter` (null when no adapter),
  writable `enabled`, `state` enum
  (Disabled/Enabled/Enabling/Disabling/Blocked), devices from
  `Bluetooth.devices.values` with a writable `connected` each. The bar
  widget toggles `adapter.enabled` on left-click and launches
  `blueman-manager` on right-click via `Quickshell.execDetached` (same
  list form the dock uses).
- **quickshell hosts org.kde.StatusNotifierWatcher itself** (the tray is
  client + host in one). Killing tray applets (nm-applet, blueman) is
  permanent unless something D-Bus-activates them again — blueman ships
  org.blueman.Applet.service, so opening blueman-manager can respawn the
  applet. Nothing autostarts applets under this config (no XDG autostart
  machinery active, no systemd user units for them).
- **Nested Hyprland works on 0.56** (Wayland socket handover): run
  `Hyprland -c /tmp/scratch.conf` from a terminal inside the session and
  the second instance renders in a window (toplevel class "aquamarine"),
  registers under `hyprctl instances` with its own socket (wayland-2)
  and its own HYPRLAND_INSTANCE_SIGNATURE. Poke it explicitly with
  `HYPRLAND_INSTANCE_SIGNATURE=<sig> hyprctl ...`.
- **A nested Hyprland hijacks the session env on startup**: it republishes
  its own socket into the systemd user manager and the D-Bus activation
  environment (verified: WAYLAND_DISPLAY flipped to wayland-2 while a
  nested instance ran). Newly activated services would then bind to the
  dead nested socket. Restore after every nested run:
  `dbus-update-activation-environment --systemd WAYLAND_DISPLAY
  HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE`
  with the main session's values. A scratch nested instance also may not
  die on SIGTERM within seconds — use SIGKILL. The `hyprplayground`
  script (HM package) automates the whole flow including the restore.
- **A SIGKILLed Hyprland leaves its runtime dir behind** in
  /run/user/1000/hypr/, so `ls -t | head -1` then points at a dead
  socket. Take the signature from the systemd manager env
  (`systemctl --user show-environment`) or verify .socket.sock exists.
- **`pkgs.writers.writeFishBin` produces a package directory** with the
  script at `bin/<name>`, and the build runs `fish --no-execute` as a
  syntax gate (a fish syntax error fails the toplevel build — useful).
- **Fish 4 rejects a trailing `$` inside a double-quoted string**
  (`":$"` — "Expected a variable name after this $"). Single-quote regex
  patterns and replacement strings in `string replace -r`.
- **hyprgrass does not build against Hyprland 0.56.2 in this nixpkgs
  pin** (ninja failure, verified 2026-10-14). Native
  `gestures.workspace_swipe` (3 fingers) is the working GNOME-parity
  gesture; overview-style swipes wait for an overview (batch 6) or a
  hyprgrass rebuild.
- **Hyprland 0.56 removed the old `gestures {}` block entirely**
  ("config option <gestures:workspace_swipe> does not exist"). Trackpad
  gestures use a dedicated **`gesture` keyword** in the legacy (hyprlang)
  config, parsed by `CConfigManager::handleGesture`:
  `gesture = <fingers>, <direction>, [mod:<mods>] [scale:<f>], workspace|dispatcher|move|resize|special, <dispatcher>, <args>`.
  Directions: left/right/up/down/horizontal/vertical/swipe/pinch*.
  The `workspace` action is the 1:1 drag animation (GNOME-style);
  `dispatcher` dispatches on the gesture. Reverse window cycling is
  `dispatcher, cyclenext, prev` — a `cycleprev` dispatcher does not
  exist.
- **`bind = , swipe:...` is a silent trap**: the bind parser accepts
  `swipe:3:left` as a "keysym", registers an ordinary bind that can
  never fire, and reports "ok" (it even lists in `hyprctl binds`). If
  gestures do not work, check that the config uses the `gesture`
  keyword, not binds.
- `hyprctl dispatchers` needs an argument in 0.56 and is not a reliable
  list; probe candidate dispatchers with `hyprctl keyword bind ...`
  (volatile, validated at add time) and full gesture lines with
  `hyprctl keyword gesture ...`.
- **`Hyprland --verify-config -c <file>`** parses a config without
  launching — use it as a gate on the generated config before switching.
- **`Hyprland --verify-config`** checks a config file for errors without
  launching anything; `hyprctl keyword <setting> <value>` changes
  settings on the live session (lost on reload — by design, good for
  experiments).

## References

- Quickshell docs: https://quickshell.outfoxxed.me
- Hyprland wiki: https://wiki.hypr.land
- Reference implementations (read-only inspiration): caelestia-dots/shell,
  end-4/dots-hyprland.
- Type surface for quickshell 0.3.1 verified from the built package's
  qmltypes files (see API notes above).
