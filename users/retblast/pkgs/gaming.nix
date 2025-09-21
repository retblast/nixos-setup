{ pkgs, ... }:{
  users.users.retblast.packages = with pkgs; [
		# Windows related stuff
		wineWowPackages.stagingFull dxvk  winetricks  bottles

		# Games & Fun
		protontricks sl gamescope proton-caller

		# Emulators
		dolphin-emu-beta ppsspp-sdl-wayland # pcsx2
	];
}
