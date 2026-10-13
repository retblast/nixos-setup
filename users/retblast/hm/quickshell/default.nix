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

        // The active icon theme (MoreWaita) does not inherit Adwaita, so
        // theme-name icon lookups fail for symbolic UI icons. Resolve them
        // by direct file path instead.
        property string iconDir: "${pkgs.adwaita-icon-theme}/share/icons/Adwaita"

        function adwaitaIcon(name) {
            return "file://" + iconDir + "/symbolic/status/" + name + ".svg";
        }
    }
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
