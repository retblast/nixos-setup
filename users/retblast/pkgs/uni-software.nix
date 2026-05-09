{ pkgs, ... }:
{

  users.users.retblast.packages = with pkgs; [
    # RC
    cisco-packet-tracer_9
    putty
    # wireshark

    # BDA
    # TODO PR: 476332
    mysql-workbench
    dia
    # INTART
    swi-prolog-gui

  ];
}
