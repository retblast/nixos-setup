{pkgs, ... }:{
	users.users.retblast.packages = with pkgs; [
		# Web Browsers
		google-chrome

		# Chat/Voice Chat apps
		telegram-desktop discord mumble

		# Password management
		bitwarden-desktop 

		# Downloaders
		curl wget aria2 megacmd

		# VPN
		# protonvpn-gui

		# Virtual classes
		zoom-us
	];
}
