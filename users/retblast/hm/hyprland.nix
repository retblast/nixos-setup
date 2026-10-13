{
  taihouConfig,
  pkgs,
  lib,
  ...
}:
let
  hyprlandEnabled = taihouConfig.localModule.hyprland.enable;

  # Volume: keybinds go through pamixer; use unmarked args so the percentage
  # limit matches GNOME's allow-volume-above-100-percent setting.
  screenshot-region = pkgs.writers.writeFishBin "screenshot-region" ''
    set -l geo (slurp)
    if test -n "$geo"
        grim -g "$geo" - | wl-copy
        notify-send -a Screenshot "Region captured" "Copied to clipboard"
    end
  '';

  screenshot-full = pkgs.writers.writeFishBin "screenshot-full" ''
    grim - | wl-copy
    notify-send -a Screenshot "Screen captured" "Copied to clipboard"
  '';

  clipboard-pick = pkgs.writers.writeFishBin "clipboard-pick" ''
    set -l item (cliphist list | fuzzel --dmenu | cliphist decode | wl-copy)
    if test -n "$item"
        notify-send -a Clipboard "Pasted from history"
    end
  '';
in
{
  wayland.windowManager.hyprland = lib.mkIf hyprlandEnabled {
    enable = true;
    # HM defaults to the new Lua config for stateVersion >= 26.05. Stay on the
    # documented hyprlang format.
    configType = "hyprlang";
    systemd.enable = true;

    settings = {
      monitor = [ "eDP-1, preferred, auto, 1" ];

      env = [ ];

      input = {
        kb_layout = "es";
        follow_mouse = 1;
        # GNOME ran with speed -0.75; scale differs, tune by feel.
        sensitivity = -0.7;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      cursor = {
        # Avoid flicker on the Intel iGPU
        no_hardware_cursors = true;
      };

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(53, 132, 228, 0.7)";
        "col.inactive_border" = "rgba(1d1d20aa)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "smooth, 0.25, 0.9, 0.1, 1.0"
        ];
        animation = [
          "windows, 1, 4, smooth"
          "fade, 1, 4, smooth"
          "workspaces, 1, 3, smooth"
        ];
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      bind = [
        # Terminal (GNOME used F12 -> kgx; keep the habit + the standard)
        "SUPER, Return, exec, ptyxis"
        "F12, exec, ptyxis"
        # Custom keybinding carried over from GNOME (custom0)
        "CTRL ALT, ntilde, exec, env TERM=xterm-256color fish -c dmmm-mouse-fix"
        # Apps
        "SUPER, E, exec, nautilus"
        "SUPER, D, exec, fuzzel"
        "SUPER, V, exec, clipboard-pick"
        # Window management
        "SUPER, Q, killactive"
        "SUPER, F, fullscreen"
        "SUPER, Space, togglefloating"
        "SUPER, L, exec, hyprlock"
        "SUPER, M, exit"
        # Workspaces
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"
        "SUPER, 0, workspace, 10"
        "SUPER, mouse_down, workspace, e+1"
        "SUPER, mouse_up, workspace, e-1"
        # Media
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioRaiseVolume, exec, pamixer -i 5"
        ", XF86AudioLowerVolume, exec, pamixer -d 5"
        ", XF86AudioMute, exec, pamixer -t"
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        # Screenshots
        ", Print, exec, screenshot-region"
        "SHIFT, Print, exec, screenshot-full"
      ];

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      exec-once = [
        # Tray applets
        "nm-applet"
        "blueman-applet"
        # Wallpaper daemon restores the last image itself
        "swww-daemon"
      ];
    };
  };

  # Polkit authentication dialog (replaces GNOME's agent). HM binds the user
  # service to the session target.
  services.hyprpolkitagent = lib.mkIf hyprlandEnabled {
    enable = true;
  };

  # Idle management. No auto-suspend at all: GNOME was configured with
  # sleep-inactive-ac-type = nothing.
  services.hypridle = lib.mkIf hyprlandEnabled {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "pidof hyprlock || hyprlock";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "hyprlock";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  programs.hyprlock = lib.mkIf hyprlandEnabled {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 2;
        hide_cursor = true;
        no_fade_in = false;
      };
      background = [
        {
          path = "screenshot";
          blur_passes = 2;
          blur_size = 8;
        }
      ];
      input-field = [
        {
          size = "300, 40";
          outline_thickness = 2;
          dots_size = 0.2;
          font_family = "SF Pro Text";
          font_size = 12;
          placeholder_text = "Password...";
          position = "0, 0";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  programs.fuzzel = lib.mkIf hyprlandEnabled {
    enable = true;
    settings = {
      main = {
        font = "SF Pro Text:size=11";
        terminal = "ptyxis -e";
        layer = "overlay";
        prompt = "";
      };
      colors = {
        background = "1d1d20f0";
        text = "ffffffff";
        selection = "3584e4ff";
        selection-text = "ffffffff";
        border = "3584e4ff";
      };
    };
  };

  services.cliphist = lib.mkIf hyprlandEnabled {
    enable = true;
    # The HM service wires the wl-paste watchers on the session target.
    systemdTarget = "hyprland-session.target";
    allowImages = true;
  };

  home.packages = lib.mkIf hyprlandEnabled [
    screenshot-region
    screenshot-full
    clipboard-pick
  ];
}
