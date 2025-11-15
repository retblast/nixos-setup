{ pkgs, ... }:{
	users.users.retblast.packages = with pkgs; [
		
		# General multimedia tools
		mediainfo ffmpeg-fuller handbrake-retblast
		
		# Screen/Video recorders
		obs-studio-with-plugins

		# Video Production & manipulation
		mkvtoolnix # davinci-resolve

		# Music/Audio file management
		# TODO: https://github.com/NixOS/nixpkgs/issues/425364 spek
		wavpack fdk-aac-encoder lame flac opusTools opustags easytag  flacon

		# Music production: DAWs
		audacity qpwgraph reaper ardour

		# Music production: plugins
		distrho-ports dragonfly-reverb lsp-plugins x42-plugins chowmatrix auburn-sounds-graillon-2 tal-reverb-4 calf chow-tape-model zam-plugins gxplugins-lv2 tap-plugins

		# Images
		gimp3-with-plugins imagemagickBig waifu2x-converter-cpp  libjxl libavif
	];
}
