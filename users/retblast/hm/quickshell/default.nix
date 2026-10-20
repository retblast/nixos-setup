# Quickshell: the shell itself (bar, dock, notifications).
# The QML config lives in ./shell; Theme.qml is generated from the retTheme
# option (users/retblast/hm/shell-theme.nix) so the shell, zed.nix and the
# system share one theme source.
{
  taihouConfig,
  config,
  pkgs,
  lib,
  ...
}:
let
  hyprlandEnabled = taihouConfig.localModule.hyprland.enable;
  t = config.retTheme;

  themeQml = pkgs.writeText "Theme.qml" ''
    pragma Singleton
    import QtQuick
    import Quickshell
    import Quickshell.Io

    Singleton {
        id: root

        property string sans: "${t.sans}"
        property int sansSize: ${toString t.sansSize}
        property string mono: "${t.mono}"
        property int monoSize: ${toString t.monoSize}

        property int barHeight: ${toString t.barHeight}
        property int dockHeight: ${toString t.dockHeight}

        // Adwaita symbolic icons hardcode a dark fill (#2e3436), which is
        // invisible on the dark bar. The recolored set (below) paints them
        // with the theme foreground; its files are flattened under status/.
        property string iconDir: "${iconRecolor}"

        // Dynamic wallpaper palette (matugen, dark scheme). The
        // update-palette script regenerates
        // $XDG_CACHE_HOME/quickshell/palette.json on every wallpaper
        // change; this reader polls it and the color tokens below fall
        // back to the static retTheme values while the file is absent or
        // invalid. Constraint: the dynamic foreground is the dark scheme's
        // on_background, which stays light — required because the recolored
        // symbolic icons are baked with the static foreground at build
        // time and cannot follow a runtime change.
        //
        // FileView is not used: in quickshell 0.3.1 neither watchChanges
        // nor adapter reload() deliver updates, and restarting a finished
        // Process from a Timer does not re-fire its collector (all verified
        // 2026-10-14). One long-lived fish loop re-reads the file every
        // 10s and emits one minified line per read; SplitParser parses
        // each line. The palette only changes on wallpaper rotation.
        property string palettePath: {
            const cache = Quickshell.env("XDG_CACHE_HOME");
            const base = cache !== undefined && cache !== null && cache !== ""
                ? cache
                : Quickshell.env("HOME") + "/.cache";
            return base + "/quickshell/palette.json";
        }

        property var palette: ({})

        Process {
            id: paletteProcess

            command: ["fish", "-c", "set -l f " + root.palettePath
                + "; while true; cat $f 2>/dev/null | tr -d '\\n\\r'; echo; sleep 10; end"]
            stdout: SplitParser {
                onRead: data => {
                    try {
                        const parsed = JSON.parse(data);
                        root.palette = parsed;
                        // Carry the palette into Hyprland's window borders:
                        // the generated config only has the static retTheme
                        // colors, so this override re-applies on every read
                        // (10s poll) and self-heals after reloads. Active =
                        // primary at the same ~70% alpha as the static
                        // config; inactive follows the background.
                        //
                        // 0.57: hyprctl keyword is refused under the Lua
                        // config. hyprctl eval runs hl.config dynamically,
                        // which parses the keys and schedules the border
                        // refresh (verified live 2026-10-18).
                        const p = parsed.colors?.primary?.dark?.color;
                        const b = parsed.colors?.background?.dark?.color;
                        if (p && b) {
                            Quickshell.execDetached(["hyprctl", "eval",
                                'hl.config({ general = { col = { ' +
                                'active_border = "rgba(' + p.replace("#", "") + 'b2)" } } })']);
                            Quickshell.execDetached(["hyprctl", "eval",
                                'hl.config({ general = { col = { ' +
                                'inactive_border = "rgba(' + b.replace("#", "") + 'aa)" } } })']);
                        }
                    } catch (e) {
                        root.palette = {};
                    }
                }
            }
        }

        Component.onCompleted: paletteProcess.running = true

        function _pal(value, fallback) {
            return value !== undefined && value !== null && value !== ""
                ? value
                : fallback;
        }

        property string bg: root._pal(root.palette.colors?.background?.dark?.color, "${t.colors.bg}")
        property string bgAlt: root._pal(root.palette.colors?.surface_container_high?.dark?.color, "${t.colors.bg-alt}")
        property string fg: root._pal(root.palette.colors?.on_background?.dark?.color, "${t.colors.fg}")
        property string fgDim: root._pal(root.palette.colors?.on_surface_variant?.dark?.color, "${t.colors.fg-dim}")
        property string accent: root._pal(root.palette.colors?.primary?.dark?.color, "${t.colors.accent}")
        property string urgent: "${t.colors.urgent}"
        property string border: root._pal(root.palette.colors?.outline?.dark?.color, "${t.colors.border}")

        function adwaitaIcon(name) {
            return "file://" + iconDir + "/status/" + name + ".svg";
        }
    }
  '';

  # Mirror Adwaita's monochrome symbolic sets (status + devices) and swap
  # every fill for the theme foreground. Symbolic icons are monochrome by
  # design, so a blanket fill swap is safe. Colors in style attributes are
  # covered too; opacity attributes survive and keep faint shapes faint.
  iconRecolor = pkgs.runCommand "adwaita-symbolic-recolored" { } ''
    src="${pkgs.adwaita-icon-theme}/share/icons/Adwaita"
    fg="${t.colors.fg}"
    install -d "$out"
    cp -r "$src/symbolic/status" "$out/status"
    cp -r "$src/symbolic/devices" "$out/devices" 2>/dev/null || true
    # status wins on name collisions.
    mv -n "$out/devices"/* "$out/status/" 2>/dev/null || true
    rmdir "$out/devices" 2>/dev/null || true
    # The copied SVGs are read-only (store permissions); sed -i needs write.
    chmod -R u+w "$out"
    find "$out" -name '*.svg' -exec sed -i -E \
      -e "s/fill=\"#[0-9a-fA-F]{3,8}\"/fill=\"$fg\"/g" \
      -e "s/fill:#[0-9a-fA-F]{3,8}/fill:$fg/g" \
      {} +
  '';

  shellDir = pkgs.runCommand "quickshell-shell-config" { } ''
    mkdir -p "$out"
    cp -r ${./shell}/. "$out/"
    chmod -R u+w "$out"
    cp ${themeQml} "$out/Theme.qml"
  '';
in
{
  programs.quickshell = lib.mkIf hyprlandEnabled {
    enable = true;
    configs.shell = shellDir;
    activeConfig = "shell";
    systemd.enable = true;
  };

  # The generated unit races the compositor twice: its environment is
  # frozen at spawn (the user manager lacks WAYLAND_DISPLAY at login,
  # the "Failed to create wl_display" start-limit crash, 2026-10-14
  # 17:40), and it can spawn before Hyprland's start hook exports
  # HYPRLAND_INSTANCE_SIGNATURE to the activation environment — seen
  # live 2026-10-19 20:04 after a compositor restart: quickshell ran
  # without the signature and every Hyprland-backed widget (the
  # workspace pill included) stayed dead until a manual restart.
  # ExecStart therefore waits for the signature and pulls the live
  # activation environment at exec time: no pins, no races.
  systemd.user.services.quickshell = lib.mkIf hyprlandEnabled {
    Service.ExecStart = lib.mkForce
      (let
        startScript = pkgs.writeShellScript "quickshell-with-session-env" ''
          sig=""
          for i in $(seq 1 100); do
            sig=$(systemctl --user show-environment | grep -E '^HYPRLAND_INSTANCE_SIGNATURE=' | cut -d= -f2-)
            [ -n "$sig" ] && break
            sleep 0.2
          done
          if [ -z "$sig" ]; then
            echo "compositor instance signature never appeared" >&2
            exit 1
          fi
          eval "$(systemctl --user show-environment | grep -E '^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE)=' | sed 's/^/export /')"
          for i in $(seq 1 100); do
            [ -S "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$WAYLAND_DISPLAY" ] && break
            sleep 0.2
          done
          exec ${pkgs.quickshell}/bin/quickshell --config shell
        '';
      in
      "${startScript}");
  };
}
