{
  taihouConfig,
  config,
  pkgs,
  lib,
  ...
}:

# Font sizes derive from the shared shell theme (retTheme), which is the
# single source of truth. Previously this read dconf (GNOME settings), which
# stopped existing with the Hyprland migration.
let
  theme = config.retTheme;
in {
  # Packages necessary for Zed to not complain about things
  # Does make using NixOS annoying tbf
  home.packages = with pkgs; [
    package-version-server
    typst
  ];
  programs.zed-editor = {
    enable = true;
    extensions = [
      "typst"
      "nix"
      "toml"
      "rust"
    ];
    userSettings = {
      git_panel = {
        dock = "left";
      };
      outline_panel = {
        dock = "left";
      };
      project_panel = {
        dock = "left";
      };
      buffer_font_family = theme.mono;
      ui_font_family = theme.sans;
      features = {
        copilot = false;
      };
      load_direnv = "shell_hook";
      vim_mode = false;
      ui_font_size = (theme.sansSize + 1) * 1.33;
      buffer_font_size = theme.monoSize * 1.33;
      languages = {
        Nix = {
          language_servers = [
            "nixd"
            "!nil"
          ];
        };
      };
      lsp = {
        nixd = {
          settings = {
            options = {
              nixos = {
                expr = "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.Taihou.options";
              };
              home-manager = {
                expr = "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.Taihou.options.home-manager.users.type.getSubOptions []";
              };
            };
            diagnostic = {
              supress = [ "sema-duplicated-attrname" ];
            };
          };
        };
      };
    };
  };
}
