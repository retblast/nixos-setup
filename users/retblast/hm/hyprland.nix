{
  taihouConfig,
  pkgs,
  lib,
  ...
}:
let
  hyprlandEnabled = taihouConfig.localModule.hyprland.enable;

  # Screenshots: captured to the clipboard AND saved to disk (GNOME
  # parity: ~/Pictures/Screenshots, timestamped filename).
  screenshot-region = pkgs.writers.writeFishBin "screenshot-region" ''
    set -l geo (slurp)
    if test -n "$geo"
        set -l dir ~/Pictures/Screenshots
        mkdir -p $dir
        set -l f "$dir/Screenshot from "(date +"%Y-%m-%d %H-%M-%S")".png"
        if grim -g "$geo" -t png "$f"
            wl-copy < "$f"
            notify-send -a Screenshot "Region captured" "Saved to $f and copied to clipboard"
        end
    end
  '';

  screenshot-full = pkgs.writers.writeFishBin "screenshot-full" ''
    set -l dir ~/Pictures/Screenshots
    mkdir -p $dir
    set -l f "$dir/Screenshot from "(date +"%Y-%m-%d %H-%M-%S")".png"
    if grim -t png "$f"
        wl-copy < "$f"
        notify-send -a Screenshot "Screen captured" "Saved to $f and copied to clipboard"
    end
  '';

  clipboard-pick = pkgs.writers.writeFishBin "clipboard-pick" ''
    set -l item (cliphist list | fuzzel --dmenu | cliphist decode | wl-copy)
    if test -n "$item"
        notify-send -a Clipboard "Pasted from history"
    end
  '';

  # Regenerate the quickshell wallpaper palette from the currently
  # displayed wallpaper (awww query). matugen emits the Material You dark
  # scheme as JSON; Theme.qml watches that file and falls back to the
  # static retTheme values while it is absent. --prefer keeps the source
  # color choice deterministic without a terminal.
  update-palette = pkgs.writers.writeFishBin "update-palette" ''
    set -l wp (awww query 2>/dev/null | grep -oP 'image: \K.*' | head -1)
    if test -z "$wp"; or not test -f "$wp"
        exit 0
    end
    set -l cachedir (if set -q XDG_CACHE_HOME; echo $XDG_CACHE_HOME; else; echo $HOME/.cache; end)
    mkdir -p "$cachedir/quickshell"
    matugen image "$wp" -m dark -q -j hex --prefer saturation \
        > "$cachedir/quickshell/palette.json" 2>/dev/null
  '';

  # fix-geoclue-position: correct BeaconDB's knowledge of the WiFi APs
  # visible from here, so geoclue fixes land where the user actually is.
  # Usage: fix-geoclue-position <lat> <lon>   (submit ground truth)
  #        fix-geoclue-position --check       (query BeaconDB now)
  fix-geoclue-position = pkgs.writers.writePython3Bin "fix-geoclue-position" {} (builtins.readFile ./fix-geoclue-position.py);

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
    update-palette
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
            # Lua config mode: hyprctl dispatch wraps its argument as Lua
            # (hl.dispatch(...)), so the actions are hl.* expressions — the
            # legacy dispatcher names are syntax errors in this mode.
            #
            # The window is the target of the dispatcher, so no focus
            # change is needed. The old code focused the window first and
            # then toggled the float of the focused window — the focus
            # call used hl.focus, which does not exist in the Lua config
            # (it is hl.dsp.focus) and failed silently, so every window
            # toggled the window that had the focus and only that one
            # ended up floating.
            # setfloating is a no-op in 0.56 (answers ok, does nothing);
            # window.float is the dispatcher that actually works. The
            # pre-read state makes it deterministic.
            hyprctl dispatch "hl.dsp.window.float({ window = \"address:$addr\", action = \"toggle\" })" >/dev/null 2>&1
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
            echo "  hyprctl dispatch 'hl.dsp...'    try dispatchers (lua form)"
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
    env HYPRLAND_INSTANCE_SIGNATURE=$nested_sig hyprctl dispatch "hl.dsp.exec_cmd(\"ptyxis -- fish -C 'cat $dir/README.txt'\")"

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
    # Lua config: 0.56 warns the hyprlang .conf format dies in 0.57. The
    # body lives in hyprland.lua (hand-written; the settings attrset does
    # not express hl.dsp bind values).
    configType = "lua";
    systemd.enable = true;

    extraConfig = builtins.readFile ./hyprland.lua;
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
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
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
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
        }
      ];
    };
  };

  programs.hyprlock = lib.mkIf hyprlandEnabled {
    enable = true;
    settings = {
      general = {
        # hyprlock 0.9.x: disable_loading_bar, grace and no_fade_in no
        # longer exist (loading bar removed in 0.8.0; grace and the
        # fade-in are CLI flags now: --grace, --no-fade-in).
        hide_cursor = true;
      };

      # Fingerprint at the lock screen through hyprlock's own handling:
      # it shows the ready message, manages the reader, and cancels
      # the verify when the user starts typing. Without this, the raw
      # pam_fprintd prompt blocks the stack until the reader times
      # out (~30s), which made post-failure unlocks take up to a
      # minute (journal 2026-10-18).
      auth = {
        fingerprint = {
          enabled = true;
        };
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
        # Render at scale 1 and let the compositor scale up. With
        # dpi-aware=yes/auto at 1.25 the buffer width comes out fractional
        # (322 logical px -> 402.5 buffer px) and the rounding drops the
        # right border column. Note: the ini accepts auto|yes|no only —
        # true/false is silently ignored.
        dpi-aware = "no";
        # fuzzel's ini rejects empty values (prompt = "" threw a syntax
        # error on every launch); the default is "> ", so a visually empty
        # prompt needs a quoted single space.
        prompt = "\" \"";
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
    # (Renamed from systemdTarget — the singular option is deprecated.)
    systemdTargets = [ "hyprland-session.target" ];
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

      # Night light (GNOME parity): color temperature follows the sun
      # schedule at the same location the weather widget is pinned to
      # (Lima). Hyprland 0.56.2 has no built-in night light, so this uses
      # wlr-gamma-control through gammastep. The quick settings panel
      # toggles the unit; it re-enables at the next login (delete the
      # WantedBy line to make it opt-in instead).
      gammastep = {
        Unit = {
          Description = "Night light (color temperature schedule)";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.gammastep}/bin/gammastep -l -12.05:-77.04 -t 6500:4000";
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install.WantedBy = [ "graphical-session.target" ];
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
    update-palette
    float-workspace
    hyprplayground
    # Palette generation for the dynamic shell theme (called by
    # update-palette).
    pkgs.matugen
    fix-geoclue-position
  ];
}
