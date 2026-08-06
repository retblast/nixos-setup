{ pkgs, lib, ...}:
	let
		# Should I set this, or should I set this in the top flake?
		# There's no dynamic way of getting this I think.
		installPath = "/etc/nixos";
		dotfilesPath = "${installPath}/users/retblast/symlink";
		folders = [
			"btop"
			"easyeffects"
			"htop"
			"MangoHud"
			"mpv"
			"neofetch"
			"xmrig-mo"
		];

		mappedFolders = builtins.listToAttrs (map (folder: {
				name = ".config/${folder}";
				value = "${dotfilesPath}/${folder}";
			}) folders
		);
		
		mkSymlinkRule = target: source:
			"L+ %h/${target} - - - - ${source}";

		# Map folder someday
		symlinkRules = 
			lib.mapAttrsToList mkSymlinkRule mappedFolders;

	in {
	# This is where I put NixOS *user* config
	# hm configs go on the hm folder xDDDDD
	imports = [
		./pkgs
		./desktop-environment.nix
	];

	users = {
		users = {
			retblast = {
				# name = "Luis";
				isNormalUser = true;
				createHome = true;
				extraGroups = [ "ydotool" "dialout" "wheel" "audio" "adbusers" "network" "libvirtd" "networkmanager" "doas" "scanners" "lp" ]; 
				shell = pkgs.fish;
			};
		};
	};

	systemd.user.tmpfiles = {
		enable = true;
		users.retblast = {
			# there's a folder in this folder under users/retblast/symlink, that has folders that have to be symlinked to
			# $HOME/.config, can you see them and generate the completion for myself?
			rules = symlinkRules;
		};
	};

	# Git config settings are strictly for my user so I put them here, not in the system config
	programs.git = {
		enable = true;
		package = pkgs.gitFull;   # gitk/git-gui included, matches what delta.nix implied you wanted before

		config = {
			user = {
				name = "retblast";
				email = "retblast@proton.me";
			};

			gpg.format = "ssh";
			user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwbRtK+7/ORqvgG7FMd37txvbORP/MmvmlgUWBu/kAP retblast@proton.me";
			commit.gpgsign = true;

			lfs.enable = true;

			core.pager = "delta";
			interactive.diffFilter = "delta --color-only";
			delta.navigate = true;
		};
	};
	# Delta Pager for git
	environment.systemPackages = [ pkgs.delta ];
}
