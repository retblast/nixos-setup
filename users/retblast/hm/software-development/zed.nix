{
  taihouConfig,
  config,
  pkgs,
  lib,
  ...
}:
{
  # Packages necessary for Zed to not complain about things
  # Does make using NixOS annoying tbf
  home.packages = with pkgs; [
    package-version-server
  ];
  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "toml"
      "rust"
    ];
    userSettings = {
      buffer_font_family = "${builtins.elemAt taihouConfig.fonts.fontconfig.defaultFonts.monospace 0}";
      ui_font_family = "${builtins.elemAt taihouConfig.fonts.fontconfig.defaultFonts.sansSerif 0}";
      features = {
        copilot = false;
      };
      load_direnv = "shell_hook";
      vim_mode = false;
      ui_font_size =
        (
          lib.strings.toInt (
            builtins.elemAt (builtins.split " " config.dconf.settings."org/gnome/desktop/interface".font-name) 2
          )
          + 1
        )
        * 1.33;
      buffer_font_size =
        lib.strings.toInt (
          builtins.elemAt (builtins.split " "
            config.dconf.settings."org/gnome/desktop/interface".monospace-font-name
          ) 2
        )
        * 1.33;
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
