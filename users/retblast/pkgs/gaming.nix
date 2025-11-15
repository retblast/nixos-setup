{ pkgs, ... }:{
  users.users.retblast.packages = with pkgs; [
		# Windows related stuff
		wineWowPackages.stagingFull dxvk  winetricks  bottles

		# Games & Fun
		protontricks sl

		# Emulators
		dolphin-emu ppsspp-sdl-wayland # pcsx2
	];
}
