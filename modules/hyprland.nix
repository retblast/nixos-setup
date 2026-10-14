{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.localModule;

  # The greeter runs as the "greeter" user from this store path; it cannot
  # read the user's generated Theme.qml, so the palette is duplicated in
  # the copied sources (Theme.qml there, keep in sync with retTheme).
  greeterConfig = pkgs.runCommand "quickshell-greeter-config" { } ''
    mkdir -p "$out"
    cp -r ${./quickshell-greeter}/. "$out/"
  '';
in
{
  options.localModule = {
    hyprland.enable = lib.mkEnableOption "the Hyprland + Quickshell desktop";
    # Off by default: the deployed tuigreet PAM stack stays exactly as-is
    # until this is flipped, and a broken greeter means a locked-out login
    # screen. Fallback: flip back to false.
    hyprland.customGreeter.enable =
      lib.mkEnableOption "the Quickshell greeter under cage (fingerprint login)";
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

    # Login manager. Launch via the package's start-hyprland wrapper: it sets
    # up the session environment and the crash watchdog. Launching the
    # compositor binary directly makes Hyprland warn at startup.
    services.greetd = {
      enable = true;
      settings.default_session = {
        # Quickshell greeter under cage: fingerprint login via pam_fprintd,
        # with the PAM conversation surfacing through Greetd's authMessage.
        # Fallback: tuigreet.
        command = if cfg.hyprland.customGreeter.enable then
          "${pkgs.cage}/bin/cage -s -- ${pkgs.quickshell}/bin/quickshell -p ${greeterConfig}"
        else
          "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
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
        # Fingerprint at login, gated with the greeter: pam_fprintd asks
        # for a finger and falls through to the password on failure or
        # timeout. tuigreet's handling of non-response PAM prompts is
        # unverified, so the default stack stays unchanged.
        greetd.fprintAuth = cfg.hyprland.customGreeter.enable;
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
        # Wallpaper daemon. swww was renamed to awww upstream; the binaries
        # are awww / awww-daemon.
        awww
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

        # blueman stays for the pairing/manager UI (blueman-manager). The
        # tray status icons are native quickshell widgets now, so the
        # applets (blueman-applet, networkmanagerapplet/nm-applet) are not
        # installed; nmtui (from networkmanager) covers connection editing.
        blueman

        # Apps previously pulled in by the GNOME module (keep the essentials)
        nautilus
        ptyxis
        file-roller
        papers
      ];
  };
}
