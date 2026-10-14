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
    # start. -c shell matches the service instance: a bare ipc call looks
    # for the default config (~/.config/quickshell/shell.qml), which does
    # not exist with a named config, so the poke would silently fail.
    set -l state off
    if test "$want_on" = true
        set state on
        hyprctl notify -1 1500 "rgb(3584e4)" "float mode: on (workspace $ws_id)"
    else
        hyprctl notify -1 1500 "rgb(909090)" "float mode: off (workspace $ws_id)"
    end
    quickshell -c shell ipc call floatws set $ws_id $state >/dev/null 2>&1
  '';

  # Sandbox launcher: writable copies of the deployed Hyprland + quickshell
  # configs in /tmp/hyprplayground, booted as a nested Hyprland (0.56 socket
  # handover). Edits in the sandbox never touch the real session; the
  # sandbox quickshell reloads live on file changes. A terminal opens
  # inside the sandbox with the README. On exit the systemd/D-Bus
  # environment is restored — a nested Hyprland republishes its own
  # WAYLAND_DISPLAY on startup, which otherwise leaves freshly activated
  # services bound to a dead socket.
  #
  # Usage: hyprplayground [--reset]
  hyprplayground = pkgs.writers.writeFishBin "hyprplayground" ''
    set -l dir /tmp/hyprplayground

    if not set -q WAYLAND_DISPLAY
        echo "hyprplayground: run from a terminal inside the Hyprland session"
        exit 1
    end

    # One playground at a time. The pattern matches only the nested
    # instance's cmdline; this script's own argv never contains it.
    if pgrep -f "Hyprland -c $dir/hypr/hyprland.conf" >/dev/null 2>&1
        echo "hyprplayground: already running"
        exit 1
    end

    if set -q argv[1]; and test "$argv[1]" = "--reset"
        rm -rf $dir
    end

    if not test -d $dir/quickshell/shell
        mkdir -p $dir/hypr $dir/quickshell
        for f in hyprland.conf hypridle.conf hyprlock.conf
            if test -e ~/.config/hypr/$f
                cp -L ~/.config/hypr/$f $dir/hypr/$f
            end
        end
        cp -rL ~/.config/quickshell/shell $dir/quickshell/shell
        chmod -R u+w $dir
        # The copies carry the main session's binds only; give the sandbox
        # its own quit bind so it can be exited without SUPER+M ambiguity.
        echo "" >> $dir/hypr/hyprland.conf
        echo "# hyprplayground: quit the sandbox session" >> $dir/hypr/hyprland.conf
        echo "bind = CTRL ALT, Q, exit" >> $dir/hypr/hyprland.conf
        begin
            echo "hyprplayground"
            echo "=============="
            echo ""
            echo "A writable sandbox copy of the desktop config. Nothing here"
            echo "affects the real session. Copies were taken from the deployed"
            echo "generation at first launch; re-copy with:"
            echo ""
            echo "  hyprplayground --reset"
            echo ""
            echo "Layout:"
            echo "  hypr/hyprland.conf    the config THIS instance runs; edits apply"
            echo "                        live (Hyprland reloads on file change)"
            echo "  hypr/hypridle.conf    reference copy, not running here"
            echo "  hypr/hyprlock.conf    reference copy, not running here"
            echo "  quickshell/shell/     quickshell config for THIS instance;"
            echo "                        reloads live on file changes"
            echo ""
            echo "The terminal next to this one runs inside the sandbox:"
            echo "  hyprctl keyword ...     try settings live"
            echo "  hyprctl dispatch ...    try dispatchers"
            echo "  hyprctl instances       both sessions are listed"
            echo ""
            echo "Notes:"
            echo "  - Ctrl+Alt+Q exits this playground session."
            echo "  - On exit the launcher restores WAYLAND_DISPLAY in the"
            echo "    systemd/D-Bus environment (a nested Hyprland republishes"
            echo "    its own socket on start). If something still binds to"
            echo "    wayland-2 afterwards, restore manually with:"
            echo "    dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
        end > $dir/README.txt
    end

    echo "Launching playground Hyprland ($dir/hypr/hyprland.conf)..."
    Hyprland -c $dir/hypr/hyprland.conf >$dir/hyprland.log 2>&1 &
    set -l hypr_pid $last_pid

    # Wait for the nested instance to register, then read its signature and
    # wayland socket from hyprctl instances (block layout: instance <sig>:
    # / time / pid / wl socket: <name>).
    set -l nested_sig ""
    set -l nested_wl ""
    for i in (seq 1 60)
        sleep 0.25
        set -l cur ""
        set nested_sig ""
        set nested_wl ""
        for line in (hyprctl instances 2>/dev/null)
            if string match -q "instance *" $line
                set cur (string replace -r '^instance (\S+):$' '$1' $line)
            end
            if string match -q "*wl socket:*" $line; and test "$cur" != "$HYPRLAND_INSTANCE_SIGNATURE"
                set nested_sig $cur
                set nested_wl (string replace -r ".*wl socket: " "" $line)
            end
        end
        if test -n "$nested_sig"
            break
        end
    end

    if test -z "$nested_sig"
        echo "hyprplayground: nested instance did not come up (see $dir/hyprland.log)"
        kill $hypr_pid 2>/dev/null
        exit 1
    end

    echo "Playground instance: sig $nested_sig socket $nested_wl"

    # Info terminal inside the sandbox; its shell targets the sandbox
    # instance (the compositor exports its own signature to children).
    env HYPRLAND_INSTANCE_SIGNATURE=$nested_sig hyprctl dispatch exec "ptyxis -- fish -C 'cat $dir/README.txt'"

    # The sandbox shell instance, bound to the sandbox socket. Backgrounded
    # as its own statement; it dies with the sandbox compositor.
    env WAYLAND_DISPLAY=$nested_wl HYPRLAND_INSTANCE_SIGNATURE=$nested_sig setsid nohup quickshell -p $dir/quickshell/shell >$dir/quickshell.log 2>&1 &

    function _pg_cleanup --description "restore the session env after the playground"
        # This script's own environment still carries the main session's
        # values; the nested compositor cannot change its parent's env.
        dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE 2>/dev/null
        notify-send -a hyprplayground "Playground closed" "Session environment restored" 2>/dev/null
    end

    function _pg_on_signal --on-signal INT --on-signal TERM --on-signal HUP
        _pg_cleanup
        exit 0
    end

    # Block until the sandbox compositor exits.
    wait $hypr_pid 2>/dev/null
    _pg_cleanup
    # Insurance: the sandbox quickshell normally dies with the compositor.
    pkill -f "quickshell -p $dir/quickshell/shell" 2>/dev/null
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
      monitor = [ "eDP-1, preferred, auto, 1.25" ];

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

      # GNOME-parity gestures: a 3-finger horizontal swipe switches
      # workspaces (built-in). The GNOME overview swipe has no Hyprland
      # equivalent yet (batch 6); hyprgrass does not build against
      # Hyprland 0.56.2 in this nixpkgs pin (verified 2026-10-14).
      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
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
        # GNOME parity: Ctrl+Alt+Left/Right switches workspaces, +Shift
        # moves the focused window along.
        "CTRL ALT, left, workspace, e-1"
        "CTRL ALT, right, workspace, e+1"
        "CTRL ALT SHIFT, left, movetoworkspace, e-1"
        "CTRL ALT SHIFT, right, movetoworkspace, e+1"
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
        # Publish the session variables to the systemd user manager and
        # the D-Bus activation environment. Without this, services started
        # by systemd (quickshell) lack WAYLAND_DISPLAY at login and die
        # before the compositor socket is found.
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
        # No tray applets: network and bluetooth status are native widgets
        # now (widgets/Network.qml, widgets/Bluetooth.qml). blueman stays
        # installed for its pairing/manager UI and can be started on demand.
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
    hyprplayground
  ];
}
