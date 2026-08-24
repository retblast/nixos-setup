{
  taihouConfig,
  config,
  pkgs,
  lib,
  ...
}:

let rawMonospaceFont = config.dconf.settings."org/gnome/desktop/interface".monospace-font-name;
rawMonospaceFontParts =  lib.strings.splitString " " rawMonospaceFont;
MonospaceFontSize = lib.strings.toInt (builtins.elemAt rawMonospaceFontParts ((builtins.length rawMonospaceFontParts) - 1));
rawSansFont = config.dconf.settings."org/gnome/desktop/interface".monospace-font-name;
rawSansFontParts =  lib.strings.splitString " " rawSansFont;
SansFontSize = lib.strings.toInt (builtins.elemAt rawSansFontParts ((builtins.length rawSansFontParts) - 1));

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
      buffer_font_family = "${builtins.elemAt taihouConfig.fonts.fontconfig.defaultFonts.monospace 0}";
      ui_font_family = "${builtins.elemAt taihouConfig.fonts.fontconfig.defaultFonts.sansSerif 0}";
      features = {
        copilot = false;
      };
      load_direnv = "shell_hook";
      vim_mode = false;
      ui_font_size = (SansFontSize + 1) * 1.33;
      buffer_font_size = MonospaceFontSize * 1.33;
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
