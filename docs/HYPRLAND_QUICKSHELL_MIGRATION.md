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
  (`--time --remember --cmd Hyprland`, user "greeter").
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

## References

- Quickshell docs: https://quickshell.outfoxxed.me
- Hyprland wiki: https://wiki.hypr.land
- Reference implementations (read-only inspiration): caelestia-dots/shell,
  end-4/dots-hyprland.
- Type surface for quickshell 0.3.1 verified from the built package's
  qmltypes files (see API notes above).
