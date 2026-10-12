{ pkgs, ... }:
{

  users.users.retblast.packages = with pkgs; [
    # RC2
    cisco-packet-tracer_9
    putty
    wireshark
    gns3-gui
    inetutils

    # TODO PR: 476332
    # mysql-workbench
    dia
    # IA-2
    swi-prolog-gui
  ];
}
