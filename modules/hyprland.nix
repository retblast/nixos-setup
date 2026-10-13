{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.localModule;
in
{
  options.localModule = {
    hyprland.enable = lib.mkEnableOption "the Hyprland + Quickshell desktop";
  };

  config = lib.mkIf (cfg.hyprland.enable) {
    # Wayland compositor. The NixOS module wires up the session, portals and
    # xwayland. No UWSM: HM's systemd integration provides the session target.
    programs.hyprland = {
      enable = true;
      withUWSM = false;
    };
    # The Hyprland NixOS module adds its own portal; this one is needed for
    # the file chooser outside of Firefox.
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    # Login manager. Stock tuigreet for now; a custom Quickshell greeter is a
    # future batch.
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";
      };
    };

    # Services GNOME used to enable implicitly. Without these, keyring unlock,
    # Nautilus mounts/trash, power profiles and battery reporting silently
    # degrade. See docs/HYPRLAND_QUICKSHELL_MIGRATION.md.
    services = {
      gnome.gnome-keyring.enable = true;
      gvfs.enable = true;
      upower.enable = true;
      power-profiles-daemon.enable = true;
      colord.enable = true;
    };
    programs.dconf.enable = true;

    security.pam = {
      services = {
        hyprlock = { };
        greetd.enableGnomeKeyring = true;
      };
    };

    # Subpixel policy previously set by modules/gnome.nix. The freetype
    # stem-darkening patches and no-hinting are global (machines/common/fonts.nix).
    fonts.fontconfig.subpixel = {
      rgba = "none";
      lcdfilter = "none";
    };

    environment.systemPackages =
      with pkgs;
      [
        # Shell ecosystem
        hyprpolkitagent
        hypridle
        hyprlock
        swww
        fuzzel

        # Session utilities
        grim
        slurp
        wl-clipboard
        cliphist
        playerctl
        pamixer
        brightnessctl
        libnotify

        # Tray applets
        blueman
        networkmanagerapplet

        # Apps previously pulled in by the GNOME module (keep the essentials)
        nautilus
        ptyxis
        file-roller
        papers
      ];
  };
}
