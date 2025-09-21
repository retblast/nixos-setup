{ pkgs, ...}:{

	users.users.retblast.packages = with pkgs; [
    # COMDAT
    ciscoPacketTracer8 putty wireshark-qt
		# BASDAT2
		mysql-workbench
		# INTART
		swi-prolog-gui
  ];
}
