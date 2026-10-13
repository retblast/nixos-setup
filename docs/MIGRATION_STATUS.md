# Migration status

Source of truth for progress. Update at the end of every work session.
Runbook: `docs/HYPRLAND_QUICKSHELL_MIGRATION.md`.

## Batch status

| # | Batch | Status | Gate |
|---|-------|--------|------|
| 1 | NixOS plumbing: greetd, services, GNOME off | done (build-verified) | switch + reboot pending (Master) |
| 2 | HM Hyprland: config, binds, idle/lock, daemons | done (build-verified) | runtime check after reboot |
| 3 | Quickshell skeleton: theme, bar, dock, toasts | done (build-verified) | runtime check after reboot |
| 4 | Shell completion: OSD, launcher panel, wallpaper timer, caffeine | pending | |
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

- `nix build .#nixosConfigurations.Taihou.config.system.build.toplevel` green.
- greetd.toml: tuigreet --time --remember --cmd Hyprland, user greeter, vt 1.
- GDM disabled; hyprland/keyring/gvfs/dconf/upower/hyprlock-PAM all true.
- Generated hyprland.conf: hyprlang, all binds + exec-once present.
- Generated quickshell shell dir complete; Theme.qml generated from retTheme.
- User units: quickshell, hypridle, cliphist (+images), hyprpolkitagent all
  bound to graphical-session.target (chained from hyprland-session.target).
- qmllint with Qt+Quickshell import paths: 0 errors in all 10 QML files.
- fish scripts (screenshot-region, screenshot-full, clipboard-pick) in closure.

## Pending runtime gate (Master)

1. `sudo nixos-rebuild switch` (or boot) from /etc/nixos
2. Reboot; tuigreet -> Hyprland; log in
3. Check: bar renders, dock launches apps, notify-send shows toast,
   Ctrl+Alt+ñ works, screenshot Print copies, polkit dialog on virt-manager,
   Bitwarden keyring unlock, Nautilus mounts USB
4. Rollback if needed: previous generation in GRUB

## Next actions

1. Master: switch + reboot gate (above).
2. Batch 4: OSD, launcher panel, wallpaper rotation timer, caffeine toggle.
3. Then batch 5 cleanup (dconf trim, package audit).

## Open questions

- Night light: GNOME color block was empty; assumed not needed (wlsunset
  can be added later).
- Mouse/touchpad feel: sensitivity -0.7 is a starting point; tune live.
- Keyboard bind `CTRL ALT, ntilde`: verify at runtime; fallback is
  `code:` bind if the keysym name does not resolve.
