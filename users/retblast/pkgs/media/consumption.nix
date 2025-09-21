{pkgs, ... }:{
	# Here go things that are related to media consumption
	imports = [
	];

	users.users.retblast.packages = with pkgs; [
		# anime
		ani-cli
		
		# Music
		# spotify

		# Video
		syncplay open-in-mpv

		# Gstreamer programs
		gst_all_1.gstreamer
	];
}
