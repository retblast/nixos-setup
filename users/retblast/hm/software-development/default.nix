{ taihouConfig, pkgs, username, ... }:{
  # Here goes everything related to software development
	imports = [
		./zed.nix
	];
	
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
		delta.enable = true;
		delta.enableGitIntegration = true;
		git = {
			enable = true;
			package = pkgs.gitFull;
			settings.user.name = "${username}";
			settings.user.email = "retblast@proton.me";
			lfs = {
				enable = true;
			};
			signing = {
				format = "ssh";
				signByDefault = true;
				key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwbRtK+7/ORqvgG7FMd37txvbORP/MmvmlgUWBu/kAP retblast@proton.me";
			};

		};
		gh = {
			enable = true;
		};
  };
}
