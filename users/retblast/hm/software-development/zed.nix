{ pkgs, ... }: {
  # Packages necessary for Zed to not complain about things
  # Does make using NixOS annoying tbf
  home.packages = with pkgs; [
    package-version-server
  ];
  programs.zed-editor = {
			enable = true;
			extensions = [ "nix" "toml" "rust" ];
			userSettings = {
				buffer_font_family ="Input Mono Condensed";
  			ui_font_family = "Inter";
				features = {
					copilot = false;
				};
				vim_mode = false;
				ui_font_size = 16;
				buffer_font_size = 16;
				languages = {
					Nix = {
						language_servers = [ "nixd" "!nil" ];
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
