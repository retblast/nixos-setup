# Migration status

Source of truth for progress. Update at the end of every work session.
Runbook: `docs/HYPRLAND_QUICKSHELL_MIGRATION.md`.

## Batch status

| # | Batch | Status | Gate |
|---|-------|--------|------|
| 1 | NixOS plumbing: greetd, services, GNOME off | done | switched + rebooted 2026-10-12; greetd cmd fixed to start-hyprland |
| 2 | HM Hyprland: config, binds, idle/lock, daemons | done | runtime verified after re-switch (F12, gradient, keybinds) |
| 3 | Quickshell skeleton: theme, bar, dock, toasts | done | live: bar/dock render; notifications fixed (see journal) |
| 4 | Shell completion | in-progress | OSD (volume+brightness) verified visually; wallpaper rotation done; bar overlap fixed; bar icons polished. Remaining: launcher panel, caffeine toggle |
| 5 | Cleanup: dconf trim, package audit | pending | |
| 6 | Future: custom greeter, dynamic theming, overview | not started | |

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

## Journal

Newest first.

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

Batch 4 wave 1 is fully staged (`git status` shows the staged set) but the
commit is blocked: commit signing needs the SSH agent, and both agent
sockets are locked — gcr lists the keys but signing fails ("communication
with agent failed", the gcr unlock prompter cannot run outside GNOME), and
the gnupg socket hangs waiting for a pinentry that cannot display. Signing
worked earlier in the evening; the user-service restarts during the
generation switches appear to have re-locked it.

Morning procedure: after login (PAM unlocks the keyring), run
`git commit -F docs/COMMIT_MSG_PENDING.txt` or ask the agent to commit the
staged set.

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

1. `sudo nixos-rebuild switch` from /etc/nixos (batch 4 wave 1: OSD,
   wallpaper timer + awww daemon service, bar fix, icon polish, toasts fix)
2. Relogin (or reboot) so quickshell restarts with the new shell
3. Check: wallpaper appears after ~20s and rotates hourly; volume/brightness
   keys pop the OSD pill; bar title no longer overlaps the clock; top-right
   shows symbolic icons with %; notify-send renders a toast
4. Rollback if needed: previous generation in GRUB

Note: the wallpaper for the night was already set manually (`awww img`);
the daemon keeps it until logout even without the switch.

## Next actions

1. Master: switch + relogin gate (above).
2. Batch 4 remainder: launcher panel, caffeine toggle in the bar.
3. Then batch 5 cleanup (dconf trim, package audit).
4. Session-keepalive: a systemd-inhibit lock (idle+sleep+shutdown) was
   started 2026-10-13 ~01:00 for 14h at Master's request; it expires on its
   own.

## Open questions

- Night light: GNOME color block was empty; assumed not needed (wlsunset
  can be added later).
- Mouse/touchpad feel: sensitivity -0.7 is a starting point; tune live.
- Keyboard bind `CTRL ALT, ntilde`: verify at runtime; fallback is
  `code:` bind if the keysym name does not resolve.
