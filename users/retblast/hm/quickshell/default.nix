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
    import Quickshell

    Singleton {
        property string sans: "${t.sans}"
        property int sansSize: ${toString t.sansSize}
        property string mono: "${t.mono}"
        property int monoSize: ${toString t.monoSize}

        property int barHeight: ${toString t.barHeight}
        property int dockHeight: ${toString t.dockHeight}

        property string bg: "${t.colors.bg}"
        property string bgAlt: "${t.colors.bg-alt}"
        property string fg: "${t.colors.fg}"
        property string fgDim: "${t.colors.fg-dim}"
        property string accent: "${t.colors.accent}"
        property string urgent: "${t.colors.urgent}"
        property string border: "${t.colors.border}"

        // Adwaita symbolic icons hardcode a dark fill (#2e3436), which is
        // invisible on the dark bar. The recolored set (below) paints them
        // with the theme foreground; its files are flattened under status/.
        property string iconDir: "${iconRecolor}"

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

  # The generated unit starts before the Wayland socket is visible to it:
  # the user manager lacks WAYLAND_DISPLAY at login, Qt cannot load the
  # wayland platform plugin ("Failed to create wl_display") and the unit
  # hits its start limit. This machine always runs one compositor whose
  # socket is wayland-1; the env import in hyprland.nix exec-once covers
  # the general case, this pins the service itself.
  systemd.user.services.quickshell = lib.mkIf hyprlandEnabled {
    Service.Environment = [ "WAYLAND_DISPLAY=wayland-1" ];
  };
}
