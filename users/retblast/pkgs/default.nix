{pkgs, ...}:{
  imports = [
    ./imports
    ./media
    ./gaming.nix
    ./internet.nix
		./software-development.nix
		./uni-software.nix
  ];

  users.users.retblast.packages = with pkgs; [
		# TODO: Organize better

			# AI
			llama-cpp-vulkan stable.ollama-vulkan usable-whisperx.whisperx
			
			# Virt
			virt-manager

			# Cryptocurrency
			monero-gui xmrig-mo

			# File compressors
			rar p7zip

			# Phone stuff
			scrcpy nmap
			
			# Spellchecking dictionaries
			#TODO: Write about this in the future NixOS article I wanna write.
			hunspellDicts.en_US hunspellDicts.es_PE aspellDicts.en aspellDicts.es aspellDicts.en-science aspellDicts.en-computers
			
	];
}
