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

  # Random wallpaper rotation (GNOME parity: ~/Pictures/Wallpapers, 1h).
  # The daemon is awww (swww was renamed upstream).
  wallpaper-rotate = pkgs.writers.writeFishBin "wallpaper-rotate" ''
    set -l dir ~/Pictures/Wallpapers
    if not test -d $dir
        exit 0
    end
    set -l files (find $dir -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \))
    if test (count $files) -eq 0
        exit 0
    end
    set -l pick $files[(random 1 (count $files))]
    awww img "$pick" --transition-type random --transition-duration 2 --transition-fps 60
  '';

  # Float-mode toggle for the current workspace.
  #
  # Hyprland 0.56 has no per-workspace float rule anymore: the workspaceopt
  # dispatcher is deprecated (warns and does nothing) and workspace rules
  # lost the all:float field, so this is applied per window. on = float
  # every tiled window, off = tile every floated window. The direction is
  # tracked with a marker file in the runtime dir; the windows themselves
  # keep the layout. Windows opened while the mode is on are not
  # auto-floated; re-toggling off and on covers them.
  float-workspace = pkgs.writers.writeFishBin "float-workspace" ''
    set -l ws_flat (hyprctl -j activeworkspace | tr -d ' \n\t')
    set -l ws_id (string match -r '"id":([0-9]+)' $ws_flat)[2]
    if test -z "$ws_id"
        exit 0
    end

    set -l state_dir $XDG_RUNTIME_DIR/hypr-float-ws
    set -l marker $state_dir/$ws_id
    set -l want_on true
    if test -f $marker
        set want_on false
        rm $marker
    else
        mkdir -p $state_dir
        touch $marker
    end

    # hyprctl -j prints pretty JSON. Flatten it and split on client
    # boundaries; each chunk then holds exactly one client's fields,
    # including its workspace id and floating state.
    for chunk in (hyprctl -j clients | tr -d ' \n\t' | string split '"address":')
        string match -q "*\"workspace\":{\"id\":$ws_id,*" $chunk
        or continue
        set -l addr (string match -r '"0x[0-9a-f]+"' $chunk | head -1 | string trim -c '"')
        if test -z "$addr"
            continue
        end
        set -l floating false
        string match -q '*"floating":true*' $chunk
        and set floating true
        if test "$floating" != "$want_on"
            hyprctl dispatch focuswindow address:$addr >/dev/null 2>&1
            # setfloating is a no-op in 0.56 (answers ok, does nothing);
            # togglefloating is the dispatcher that actually works. The
            # pre-read state makes it deterministic.
            hyprctl dispatch togglefloating >/dev/null 2>&1
        end
    end

    # Tell the running shell so the dock shows/hides immediately. The
    # marker dir stays the source of truth; the shell re-syncs from it on
    # start. Fails silently when no shell instance is registered.
    set -l state off
    if test "$want_on" = true
        set state on
        hyprctl notify -1 1500 "0 rgb(3584e4)" "float mode: on (workspace $ws_id)"
    else
        hyprctl notify -1 1500 "0 rgb(909090)" "float mode: off (workspace $ws_id)"
    end
    quickshell ipc call floatws set $ws_id $state >/dev/null 2>&1
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
        # sensitivity = -0.7;
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
        # GNOME blue #3584e4 at ~70% alpha (b2). Hyprland only parses
        # RRGGBBAA hex; CSS-style rgba(r, g, b, a) fails to parse.
        "col.active_border" = "rgba(3584e4b2)";
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
        # Terminal (GNOME used F12 -> kgx; keep the habit + the standard).
        # Bare-key binds need the empty modifier field: F12 here is the key,
        # not a modifier.
        "SUPER, Return, exec, ptyxis"
        ", F12, exec, ptyxis"
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
        # Float mode for the whole workspace (see float-workspace above)
        "SUPER SHIFT, F, exec, float-workspace"
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
        # The wallpaper daemon runs as a user service (see awww-daemon below);
        # it restores the last image itself and the rotation timer sets one
        # shortly after login anyway.
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

  # Wallpaper daemon + rotation. swww was renamed to awww in nixpkgs and the
  # old exec-once "swww-daemon" silently failed (command not found).
  systemd.user = lib.mkIf hyprlandEnabled {
    services = {
      awww-daemon = {
        Unit = {
          Description = "awww (swww) wallpaper daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.awww}/bin/awww-daemon";
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
      wallpaper-rotate = {
        Unit = {
          Description = "Set a random wallpaper from ~/Pictures/Wallpapers";
          After = [ "awww-daemon.service" ];
          Requires = [ "awww-daemon.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${wallpaper-rotate}/bin/wallpaper-rotate";
        };
      };
    };
    timers.wallpaper-rotate = {
      Unit.Description = "Rotate the wallpaper hourly";
      Timer = {
        OnBootSec = "20s";
        OnUnitActiveSec = "1h";
        AccuracySec = "10s";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };

  home.packages = lib.mkIf hyprlandEnabled [
    screenshot-region
    screenshot-full
    clipboard-pick
    wallpaper-rotate
    float-workspace
  ];
}
