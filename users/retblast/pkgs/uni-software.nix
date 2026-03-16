{ pkgs, ... }:
{

  users.users.retblast.packages = with pkgs; [
    # ARQORG
    dosbox-staging
    gputils
    # COMDAT
    #ciscoPacketTracer8
    putty
    wireshark
    arduino-ide
    # BASDAT2
    # TODO PR: 476332
    mysql-workbench
    dia
    # INTART
    swi-prolog-gui

  ];
}
