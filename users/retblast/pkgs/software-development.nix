{ pkgs, ...}:{
	
	users.users.retblast.packages = with pkgs; [
		# https://github.com/NixOS/nixpkgs/issues/242322#issuecomment-2264995861
		# Text editors, IDEs
		my-vscode

		# Linux containers just in case
		toolbox distrobox
		
		# Computer Graphics
		blender 
		
		# Compilers, configurers
		patchelf

		# Nix tooling
		nixd 

		# Debuggers
		gdb valgrind

		# Documentation tools
		# FTBFS https://github.com/NixOS/nixpkgs/pull/455354
		# zeal

		# Java libraries
		commonsIo

		# Gamedev
		#unityhub # https://nixpk.gs/pr-tracker.html?pr=368851
  ];
}
