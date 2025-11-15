{ pkgs, ... }:{

	programs = {
		gamescope = {
			enable = true;
			# https://github.com/NixOS/nixpkgs/issues/351516
			# https://discourse.nixos.org/t/unable-to-activate-gamescope-capsysnice-option/37843/15
			capSysNice = false;
		};
		steam = {
			enable = true;
			remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
			dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
			extraPackages = with pkgs; [
				openssl_1_1
        curl
        libssh2
        openal
        zlib
        libpng
        # https://github.com/NixOS/nixpkgs/issues/236561
        attr
        xorg.libXcursor
        xorg.libXi
        xorg.libXinerama
        xorg.libXScrnSaver
        libpng
        libpulseaudio
        libvorbis
        stdenv.cc.cc.lib
        libkrb5
        keyutils
				pkgsi686Linux.gtk3-x11
				pkgsi686Linux.pipewire
				pkgsi686Linux.libpulseaudio
				pkgsi686Linux.libvdpau
			]
			;
		};
		adb.enable = true;
		# nix-index conflicts with this, so let's disable it.
		command-not-found.enable = false;
	};
}
