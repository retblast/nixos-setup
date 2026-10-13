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

        property string bg: "${t.colors.bg}"
        property string bgAlt: "${t.colors.bg-alt}"
        property string fg: "${t.colors.fg}"
        property string fgDim: "${t.colors.fg-dim}"
        property string accent: "${t.colors.accent}"
        property string urgent: "${t.colors.urgent}"
        property string border: "${t.colors.border}"
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
}
