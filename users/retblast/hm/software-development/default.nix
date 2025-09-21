{ taihouConfig, pkgs, username, ... }:{
  # Here goes everything related to software development
	
  services = {
    lorri = {
			enable = true;
			enableNotifications = true;
			# There's also package and nixPackage.
		};

    gpg-agent = {
			enable = true;
			enableSshSupport = true;
			pinentry.package = if taihouConfig.services.desktopManager.plasma6.enable then pkgs.pinentry-qt else pkgs.pinentry-gnome3;
		};
  };

  programs = {
		direnv = {
			enable = true;
			# Fish integration is always enabled
			#enableFishIntegration = true;
			enableBashIntegration = true;
			nix-direnv.enable = true;
		};
    gpg = {
			enable = true;
			# mutableKeys and mutableTrust are enabled by default

		};
		git = {
			enable = true;
			package = pkgs.gitFull;
			userName = "${username}";
			userEmail = "retblast@proton.me";
			delta = {
				enable = true;
			};
			lfs = {
				enable = true;
			};
			signing = {
				format = "ssh";
				signByDefault = true;
				key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJGPyYbZ9VUdt/It/xAIFwzXwyGnOe45KyxoXp3qHXpM retblast@proton.me";
			};

		};
		gh = {
			enable = true;
		};
  };
}
