{ pkgs, ...}:{

	users.users.retblast.packages = with pkgs; [
		# ARQORG
		dosbox-staging
		# COMDAT
		#ciscoPacketTracer8 
		putty wireshark-qt
		# BASDAT2
		mysql-workbench # dia
		# INTART
		swi-prolog-gui
  ];
}
